const fs = require('fs');
const path = require('path');
const { expect } = require('chai');
const {
  initializeTestEnvironment,
  assertSucceeds,
  assertFails,
} = require('@firebase/rules-unit-testing');

const {
  doc,
  getDoc,
  setDoc,
  updateDoc,
  deleteDoc,
  collection,
  addDoc,
  setLogLevel,
} = require('firebase/firestore');

const PROJECT_ID = 'hansol-test';
let testEnv;

before(async function () {
  this.timeout(30000);
  setLogLevel('error');
  testEnv = await initializeTestEnvironment({
    projectId: PROJECT_ID,
    firestore: {
      rules: fs.readFileSync(path.resolve(__dirname, '../../../firestore.rules'), 'utf8'),
      host: '127.0.0.1',
      port: 8080,
    },
  });
});

after(async () => {
  if (testEnv) await testEnv.cleanup();
});

beforeEach(async () => {
  await testEnv.clearFirestore();
});

// 헬퍼: 사전 데이터를 rules 우회로 미리 심어둠
async function seed(fn) {
  await testEnv.withSecurityRulesDisabled(async (ctx) => {
    await fn(ctx.firestore());
  });
}

function authedDb(uid) {
  return testEnv.authenticatedContext(uid).firestore();
}

function unauthedDb() {
  return testEnv.unauthenticatedContext().firestore();
}

// 사용자 프로필 생성 (role 지정 가능)
async function createUser(uid, role = 'user') {
  await seed(async (db) => {
    await setDoc(doc(db, 'users', uid), {
      uid,
      name: `user_${uid}`,
      role,
      approved: true,
      suspendedUntil: null,
    });
  });
}

describe('users collection', () => {
  it('본인 프로필은 읽을 수 있음', async () => {
    await createUser('alice');
    await assertSucceeds(getDoc(doc(authedDb('alice'), 'users/alice')));
  });

  it('일반 사용자는 다른 사람 프로필 읽을 수 없음', async () => {
    await createUser('alice');
    await createUser('bob');
    await assertFails(getDoc(doc(authedDb('bob'), 'users/alice')));
  });

  it('manager는 다른 사람 프로필 읽을 수 있음', async () => {
    await createUser('alice');
    await createUser('mgr', 'manager');
    await assertSucceeds(getDoc(doc(authedDb('mgr'), 'users/alice')));
  });

  it('본인이 자기 role을 admin으로 변경하면 거부 (권한 상승 방지)', async () => {
    await createUser('alice');
    await assertFails(updateDoc(doc(authedDb('alice'), 'users/alice'), { role: 'admin' }));
  });

  it('admin은 다른 사용자 role 변경 가능', async () => {
    await createUser('alice');
    await createUser('admin1', 'admin');
    await assertSucceeds(updateDoc(doc(authedDb('admin1'), 'users/alice'), { role: 'manager' }));
  });

  it('미인증 사용자는 프로필 읽기 거부', async () => {
    await createUser('alice');
    await assertFails(getDoc(doc(unauthedDb(), 'users/alice')));
  });
});

describe('posts collection', () => {
  it('누구나 글 읽기 가능 (미인증 포함)', async () => {
    await seed(async (db) => {
      await setDoc(doc(db, 'posts/p1'), {
        authorUid: 'alice',
        title: 'hello',
        content: 'world',
      });
    });
    await assertSucceeds(getDoc(doc(unauthedDb(), 'posts/p1')));
  });

  it('로그인 사용자는 본인 uid로 글 작성 가능', async () => {
    await createUser('alice');
    await assertSucceeds(
      setDoc(doc(authedDb('alice'), 'posts/new1'), {
        authorUid: 'alice',
        title: 'title',
        content: 'content',
      })
    );
  });

  it('다른 사람 uid로 글 작성 시 거부 (위조 방지)', async () => {
    await createUser('alice');
    await assertFails(
      setDoc(doc(authedDb('alice'), 'posts/new2'), {
        authorUid: 'bob', // 위조
        title: 'title',
        content: 'content',
      })
    );
  });

  it('제목 200자 초과 시 거부', async () => {
    await createUser('alice');
    await assertFails(
      setDoc(doc(authedDb('alice'), 'posts/long'), {
        authorUid: 'alice',
        title: 'a'.repeat(201),
        content: 'x',
      })
    );
  });

  it('본인이 작성한 글은 자유 수정 가능', async () => {
    await createUser('alice');
    await seed(async (db) => {
      await setDoc(doc(db, 'posts/p2'), {
        authorUid: 'alice',
        title: 'old',
        content: 'old',
        likes: 0,
      });
    });
    await assertSucceeds(
      updateDoc(doc(authedDb('alice'), 'posts/p2'), { title: 'new title' })
    );
  });

  it('남의 글 제목 수정 시 거부', async () => {
    await createUser('alice');
    await createUser('bob');
    await seed(async (db) => {
      await setDoc(doc(db, 'posts/p3'), {
        authorUid: 'alice',
        title: 'old',
        content: 'old',
        likes: 0,
      });
    });
    await assertFails(
      updateDoc(doc(authedDb('bob'), 'posts/p3'), { title: 'hijacked' })
    );
  });

  it('남의 글 좋아요 +1은 허용 (likes Map + likeCount counter)', async () => {
    await createUser('alice');
    await createUser('bob');
    await seed(async (db) => {
      await setDoc(doc(db, 'posts/p4'), {
        authorUid: 'alice',
        title: 't',
        content: 'c',
        likes: {},
        likeCount: 0,
      });
    });
    await assertSucceeds(
      updateDoc(doc(authedDb('bob'), 'posts/p4'), {
        'likes.bob': true,
        likeCount: 1,
      })
    );
  });

  it('likeCount +5처럼 큰 폭 증가는 거부 (counter delta 검증)', async () => {
    await createUser('alice');
    await createUser('bob');
    await seed(async (db) => {
      await setDoc(doc(db, 'posts/p5'), {
        authorUid: 'alice',
        title: 't',
        content: 'c',
        likes: {},
        likeCount: 0,
      });
    });
    await assertFails(
      updateDoc(doc(authedDb('bob'), 'posts/p5'), {
        'likes.bob': true,
        likeCount: 5,
      })
    );
  });

  it('likeCount 음수는 거부', async () => {
    await createUser('alice');
    await createUser('bob');
    await seed(async (db) => {
      await setDoc(doc(db, 'posts/p5b'), {
        authorUid: 'alice',
        title: 't',
        content: 'c',
        likes: {},
        likeCount: 0,
      });
    });
    await assertFails(
      updateDoc(doc(authedDb('bob'), 'posts/p5b'), { likeCount: -1 })
    );
  });

  it('likeCount 필드 없는 기존 글에 +1 허용 (legacy 호환)', async () => {
    await createUser('alice');
    await createUser('bob');
    await seed(async (db) => {
      await setDoc(doc(db, 'posts/p5c'), {
        authorUid: 'alice',
        title: 't',
        content: 'c',
        likes: {},
      });
    });
    await assertSucceeds(
      updateDoc(doc(authedDb('bob'), 'posts/p5c'), {
        'likes.bob': true,
        likeCount: 1,
      })
    );
  });

  it('manager는 남의 글 삭제 가능', async () => {
    await createUser('alice');
    await createUser('mgr', 'manager');
    await seed(async (db) => {
      await setDoc(doc(db, 'posts/p6'), {
        authorUid: 'alice',
        title: 't',
        content: 'c',
      });
    });
    await assertSucceeds(deleteDoc(doc(authedDb('mgr'), 'posts/p6')));
  });

  it('일반 사용자는 남의 글 삭제 거부', async () => {
    await createUser('alice');
    await createUser('bob');
    await seed(async (db) => {
      await setDoc(doc(db, 'posts/p7'), {
        authorUid: 'alice',
        title: 't',
        content: 'c',
      });
    });
    await assertFails(deleteDoc(doc(authedDb('bob'), 'posts/p7')));
  });
});

describe('comments subcollection', () => {
  beforeEach(async () => {
    await seed(async (db) => {
      await setDoc(doc(db, 'posts/p1'), {
        authorUid: 'alice',
        title: 't',
        content: 'c',
      });
    });
  });

  it('본인 uid로 댓글 작성 가능', async () => {
    await createUser('bob');
    await assertSucceeds(
      addDoc(collection(authedDb('bob'), 'posts/p1/comments'), {
        authorUid: 'bob',
        content: '댓글입니다',
      })
    );
  });

  it('다른 사람 uid로 댓글 작성 거부', async () => {
    await createUser('bob');
    await assertFails(
      addDoc(collection(authedDb('bob'), 'posts/p1/comments'), {
        authorUid: 'eve',
        content: '위조',
      })
    );
  });

  it('mentions가 21개 이상이면 거부', async () => {
    await createUser('bob');
    await assertFails(
      addDoc(collection(authedDb('bob'), 'posts/p1/comments'), {
        authorUid: 'bob',
        content: '도배',
        mentions: Array.from({ length: 21 }, (_, i) => `u${i}`),
      })
    );
  });

  it('1000자 초과 댓글 거부', async () => {
    await createUser('bob');
    await assertFails(
      addDoc(collection(authedDb('bob'), 'posts/p1/comments'), {
        authorUid: 'bob',
        content: 'a'.repeat(1001),
      })
    );
  });
});

describe('reports collection', () => {
  it('일반 사용자는 본인 uid로 신고 생성 가능', async () => {
    await createUser('alice');
    await assertSucceeds(
      setDoc(doc(authedDb('alice'), 'reports/r1'), {
        reporterUid: 'alice',
        reason: '욕설',
        targetType: 'post',
        targetId: 'p1',
      })
    );
  });

  it('다른 사람 uid로 신고 생성 거부', async () => {
    await createUser('alice');
    await assertFails(
      setDoc(doc(authedDb('alice'), 'reports/r2'), {
        reporterUid: 'bob',
        reason: '위조',
      })
    );
  });

  it('일반 사용자는 신고 목록 읽기 거부', async () => {
    await seed(async (db) => {
      await setDoc(doc(db, 'reports/r3'), { reporterUid: 'x', reason: 'r' });
    });
    await createUser('alice');
    await assertFails(getDoc(doc(authedDb('alice'), 'reports/r3')));
  });

  it('manager는 신고 읽기/삭제 가능', async () => {
    await seed(async (db) => {
      await setDoc(doc(db, 'reports/r4'), { reporterUid: 'x', reason: 'r' });
    });
    await createUser('mgr', 'manager');
    await assertSucceeds(getDoc(doc(authedDb('mgr'), 'reports/r4')));
    await assertSucceeds(deleteDoc(doc(authedDb('mgr'), 'reports/r4')));
  });
});

describe('chats collection', () => {
  beforeEach(async () => {
    await createUser('alice');
    await createUser('bob');
    await seed(async (db) => {
      await setDoc(doc(db, 'chats/c1'), {
        participants: ['alice', 'bob'],
      });
    });
  });

  it('참여자는 채팅방 읽기 가능', async () => {
    await assertSucceeds(getDoc(doc(authedDb('alice'), 'chats/c1')));
  });

  it('비참여자는 채팅방 읽기 거부', async () => {
    await assertFails(getDoc(doc(authedDb('eve'), 'chats/c1')));
  });

  it('참여자는 본인 senderUid로 메시지 전송 가능', async () => {
    await assertSucceeds(
      addDoc(collection(authedDb('alice'), 'chats/c1/messages'), {
        senderUid: 'alice',
        content: 'hi',
      })
    );
  });

  it('참여자가 다른 사람 senderUid로 메시지 전송 거부', async () => {
    await assertFails(
      addDoc(collection(authedDb('alice'), 'chats/c1/messages'), {
        senderUid: 'bob',
        content: '위조',
      })
    );
  });

  it('비참여자는 메시지 전송 거부', async () => {
    await assertFails(
      addDoc(collection(authedDb('eve'), 'chats/c1/messages'), {
        senderUid: 'eve',
        content: 'intruder',
      })
    );
  });
});

describe('admin_logs collection', () => {
  it('일반 사용자는 admin_logs 작성 거부', async () => {
    await createUser('alice');
    await assertFails(
      setDoc(doc(authedDb('alice'), 'admin_logs/l1'), {
        action: 'something',
        actorUid: 'alice',
      })
    );
  });

  it('manager는 admin_logs 작성 가능', async () => {
    await createUser('mgr', 'manager');
    await assertSucceeds(
      setDoc(doc(authedDb('mgr'), 'admin_logs/l2'), {
        action: 'delete_post',
        actorUid: 'mgr',
      })
    );
  });

  it('admin_logs는 누구도 update/delete 불가능', async () => {
    await seed(async (db) => {
      await setDoc(doc(db, 'admin_logs/l3'), { action: 'x', actorUid: 'mgr' });
    });
    await createUser('mgr', 'manager');
    await assertFails(updateDoc(doc(authedDb('mgr'), 'admin_logs/l3'), { action: 'modified' }));
    await assertFails(deleteDoc(doc(authedDb('mgr'), 'admin_logs/l3')));
  });

  it('moderator는 admin_logs 작성 가능', async () => {
    await createUser('mod', 'moderator');
    await assertSucceeds(
      setDoc(doc(authedDb('mod'), 'admin_logs/l4'), {
        action: 'delete_post',
        actorUid: 'mod',
      })
    );
  });

  it('auditor는 admin_logs 읽기 가능, 작성 불가', async () => {
    await seed(async (db) => {
      await setDoc(doc(db, 'admin_logs/l5'), { action: 'x', actorUid: 'mgr' });
    });
    await createUser('aud', 'auditor');
    await assertSucceeds(getDoc(doc(authedDb('aud'), 'admin_logs/l5')));
    await assertFails(
      setDoc(doc(authedDb('aud'), 'admin_logs/l6'), {
        action: 'something',
        actorUid: 'aud',
      })
    );
  });
});

describe('moderator role', () => {
  it('moderator는 다른 사용자 글 삭제 가능', async () => {
    await createUser('mod', 'moderator');
    await createUser('alice');
    await seed(async (db) => {
      await setDoc(doc(db, 'posts/p1'), {
        title: 'test', content: 'content', authorUid: 'alice', authorName: 'Alice',
        createdAt: new Date(), category: '자유',
      });
    });
    await assertSucceeds(deleteDoc(doc(authedDb('mod'), 'posts/p1')));
  });

  it('moderator는 댓글 삭제 가능', async () => {
    await createUser('mod', 'moderator');
    await seed(async (db) => {
      await setDoc(doc(db, 'posts/p2'), {
        title: 'test', content: 'c', authorUid: 'alice', authorName: 'Alice',
        createdAt: new Date(), category: '자유',
      });
      await setDoc(doc(db, 'posts/p2/comments/c1'), {
        content: 'hi', authorUid: 'alice', authorName: 'Alice', createdAt: new Date(),
      });
    });
    await assertSucceeds(deleteDoc(doc(authedDb('mod'), 'posts/p2/comments/c1')));
  });

  it('moderator는 신고 읽기 가능, 삭제 불가', async () => {
    await createUser('mod', 'moderator');
    await seed(async (db) => {
      await setDoc(doc(db, 'reports/r1'), {
        postId: 'p1', reporterUid: 'alice', reason: 'spam', createdAt: new Date(),
      });
    });
    await assertSucceeds(getDoc(doc(authedDb('mod'), 'reports/r1')));
    await assertFails(deleteDoc(doc(authedDb('mod'), 'reports/r1')));
  });

  it('moderator는 사용자 프로필 읽기 불가', async () => {
    await createUser('mod', 'moderator');
    await createUser('alice');
    await assertFails(getDoc(doc(authedDb('mod'), 'users/alice')));
  });

  it('moderator는 app_config 쓰기 불가', async () => {
    await createUser('mod', 'moderator');
    await assertFails(
      setDoc(doc(authedDb('mod'), 'app_config/general'), { version: '2.0' })
    );
  });

  it('moderator는 app_stats 읽기 불가', async () => {
    await createUser('mod', 'moderator');
    await seed(async (db) => {
      await setDoc(doc(db, 'app_stats/totals'), { users: 100 });
    });
    await assertFails(getDoc(doc(authedDb('mod'), 'app_stats/totals')));
  });
});

describe('auditor role', () => {
  it('auditor는 app_stats 읽기 가능', async () => {
    await createUser('aud', 'auditor');
    await seed(async (db) => {
      await setDoc(doc(db, 'app_stats/totals'), { users: 100 });
    });
    await assertSucceeds(getDoc(doc(authedDb('aud'), 'app_stats/totals')));
  });

  it('auditor는 신고 읽기 가능, 삭제 불가', async () => {
    await createUser('aud', 'auditor');
    await seed(async (db) => {
      await setDoc(doc(db, 'reports/r2'), {
        postId: 'p1', reporterUid: 'alice', reason: 'spam', createdAt: new Date(),
      });
    });
    await assertSucceeds(getDoc(doc(authedDb('aud'), 'reports/r2')));
    await assertFails(deleteDoc(doc(authedDb('aud'), 'reports/r2')));
  });

  it('auditor는 건의사항 읽기 가능, 삭제 불가', async () => {
    await createUser('aud', 'auditor');
    await seed(async (db) => {
      await setDoc(doc(db, 'app_feedbacks/f1'), {
        authorUid: 'alice', content: 'feedback', createdAt: new Date(),
      });
    });
    await assertSucceeds(getDoc(doc(authedDb('aud'), 'app_feedbacks/f1')));
    await assertFails(deleteDoc(doc(authedDb('aud'), 'app_feedbacks/f1')));
  });

  it('auditor는 글/댓글 삭제 불가', async () => {
    await createUser('aud', 'auditor');
    await seed(async (db) => {
      await setDoc(doc(db, 'posts/p3'), {
        title: 'test', content: 'c', authorUid: 'alice', authorName: 'Alice',
        createdAt: new Date(), category: '자유',
      });
    });
    await assertFails(deleteDoc(doc(authedDb('aud'), 'posts/p3')));
  });

  it('auditor는 사용자 수정 불가', async () => {
    await createUser('aud', 'auditor');
    await createUser('alice');
    await assertFails(updateDoc(doc(authedDb('aud'), 'users/alice'), { approved: false }));
  });

  it('auditor는 function_logs 읽기 가능', async () => {
    await createUser('aud', 'auditor');
    await seed(async (db) => {
      await setDoc(doc(db, 'function_logs/fl1'), { error: 'test', createdAt: new Date() });
    });
    await assertSucceeds(getDoc(doc(authedDb('aud'), 'function_logs/fl1')));
  });

  it('auditor는 crash_logs 읽기 가능', async () => {
    await createUser('aud', 'auditor');
    await seed(async (db) => {
      await setDoc(doc(db, 'crash_logs/cl1'), { error: 'test', createdAt: new Date() });
    });
    await assertSucceeds(getDoc(doc(authedDb('aud'), 'crash_logs/cl1')));
  });
});

// 인증 + 비정지 가드 (canWrite)
describe('canWrite guard', () => {
  async function createSuspendedUser(uid) {
    await seed(async (db) => {
      await setDoc(doc(db, 'users', uid), {
        uid, name: `user_${uid}`, role: 'user', approved: true,
        verificationStatus: 'verified',
        suspendedUntil: new Date(Date.now() + 24 * 60 * 60 * 1000), // 24h future
      });
    });
  }

  async function createUnverifiedUser(uid) {
    await seed(async (db) => {
      await setDoc(doc(db, 'users', uid), {
        uid, name: `user_${uid}`, role: 'user', approved: true,
        verificationStatus: 'unverified',
        suspendedUntil: null,
      });
    });
  }

  it('정지 사용자는 글 작성 불가', async () => {
    await createSuspendedUser('sus');
    await assertFails(
      setDoc(doc(authedDb('sus'), 'posts/blocked1'), {
        title: 'x', content: 'c', authorUid: 'sus', authorName: 'Sus',
        createdAt: new Date(), category: '자유',
      })
    );
  });

  it('미인증 사용자는 글 작성 불가', async () => {
    await createUnverifiedUser('un');
    await assertFails(
      setDoc(doc(authedDb('un'), 'posts/blocked2'), {
        title: 'x', content: 'c', authorUid: 'un', authorName: 'Un',
        createdAt: new Date(), category: '자유',
      })
    );
  });

  it('정지 사용자는 신고 작성 불가', async () => {
    await createSuspendedUser('sus2');
    await assertFails(
      addDoc(collection(authedDb('sus2'), 'reports'), {
        postId: 'p1', reporterUid: 'sus2', reason: 'spam', createdAt: new Date(),
      })
    );
  });

  it('정지 만료된 사용자는 글 작성 가능', async () => {
    await seed(async (db) => {
      await setDoc(doc(db, 'users/expired'), {
        uid: 'expired', name: 'e', role: 'user', approved: true,
        verificationStatus: 'verified',
        suspendedUntil: new Date(Date.now() - 24 * 60 * 60 * 1000), // 24h past
      });
    });
    await assertSucceeds(
      setDoc(doc(authedDb('expired'), 'posts/ok1'), {
        title: 'x', content: 'c', authorUid: 'expired', authorName: 'E',
        createdAt: new Date(), category: '자유',
      })
    );
  });

  it('verificationStatus 필드 없는 기존 사용자는 작성 가능 (grandfathered)', async () => {
    await createUser('legacy'); // no verificationStatus, no suspendedUntil
    await assertSucceeds(
      setDoc(doc(authedDb('legacy'), 'posts/legacy1'), {
        title: 'x', content: 'c', authorUid: 'legacy', authorName: 'L',
        createdAt: new Date(), category: '자유',
      })
    );
  });
});

describe('studentIds collection', () => {
  it('로그인 사용자는 학번 점유 여부 읽기 가능', async () => {
    await createUser('alice');
    await seed(async (db) => {
      await setDoc(doc(db, 'studentIds/303241621'), { uid: 'bob' });
    });
    await assertSucceeds(getDoc(doc(authedDb('alice'), 'studentIds/303241621')));
  });

  it('미인증 사용자는 학번 점유 읽기 거부', async () => {
    await assertFails(getDoc(doc(unauthedDb(), 'studentIds/303241621')));
  });

  it('클라이언트는 studentIds 작성 거부 (Cloud Functions만)', async () => {
    await createUser('alice');
    await assertFails(
      setDoc(doc(authedDb('alice'), 'studentIds/303241621'), { uid: 'alice' })
    );
  });
});

describe('otp_codes collection', () => {
  it('클라이언트는 OTP 코드 읽기/쓰기 모두 거부', async () => {
    await createUser('alice');
    await assertFails(getDoc(doc(authedDb('alice'), 'otp_codes/alice')));
    await assertFails(
      setDoc(doc(authedDb('alice'), 'otp_codes/alice'), { hash: 'x' })
    );
  });
});

describe('banned_devices collection', () => {
  it('클라이언트는 banned_devices 접근 거부 (Cloud Functions만)', async () => {
    await createUser('alice');
    await assertFails(getDoc(doc(authedDb('alice'), 'banned_devices/dev1')));
    await assertFails(
      setDoc(doc(authedDb('alice'), 'banned_devices/dev1'), { uid: 'alice' })
    );
  });
});

describe('reports_queue collection', () => {
  it('moderator는 reports_queue 읽기 가능', async () => {
    await createUser('mod', 'moderator');
    await seed(async (db) => {
      await setDoc(doc(db, 'reports_queue/p1'), {
        postId: 'p1', reportCount: 5, createdAt: new Date(),
      });
    });
    await assertSucceeds(getDoc(doc(authedDb('mod'), 'reports_queue/p1')));
  });

  it('일반 사용자는 reports_queue 읽기 거부', async () => {
    await createUser('alice');
    await seed(async (db) => {
      await setDoc(doc(db, 'reports_queue/p2'), { postId: 'p2', reportCount: 5 });
    });
    await assertFails(getDoc(doc(authedDb('alice'), 'reports_queue/p2')));
  });

  it('moderator도 reports_queue 직접 쓰기 거부 (Cloud Functions만)', async () => {
    await createUser('mod', 'moderator');
    await assertFails(
      setDoc(doc(authedDb('mod'), 'reports_queue/p3'), {
        postId: 'p3', reportCount: 1,
      })
    );
  });
});

describe('appeals collection', () => {
  it('정지된 사용자도 본인 uid로 이의제기 작성 가능 (canWrite 우회)', async () => {
    await seed(async (db) => {
      await setDoc(doc(db, 'users/sus'), {
        uid: 'sus', name: 'S', role: 'user', approved: true,
        verificationStatus: 'verified',
        suspendedUntil: new Date(Date.now() + 24 * 60 * 60 * 1000),
      });
    });
    await assertSucceeds(
      addDoc(collection(authedDb('sus'), 'appeals'), {
        uid: 'sus',
        reason: '억울합니다 — 광고가 아닌 학교 행사 안내였습니다.',
        createdAt: new Date(),
      })
    );
  });

  it('남의 uid로 이의제기 작성 거부', async () => {
    await createUser('alice');
    await assertFails(
      addDoc(collection(authedDb('alice'), 'appeals'), {
        uid: 'bob', reason: '대신 이의 제기', createdAt: new Date(),
      })
    );
  });

  it('500자 초과 이의제기 거부', async () => {
    await createUser('alice');
    await assertFails(
      addDoc(collection(authedDb('alice'), 'appeals'), {
        uid: 'alice', reason: 'x'.repeat(501), createdAt: new Date(),
      })
    );
  });

  it('본인 이의제기 읽기 가능, 남의 것은 staff만 읽기', async () => {
    await seed(async (db) => {
      await setDoc(doc(db, 'appeals/a1'), {
        uid: 'alice', reason: 'r', createdAt: new Date(),
      });
    });
    await createUser('alice');
    await createUser('bob');
    await createUser('aud', 'auditor');
    await assertSucceeds(getDoc(doc(authedDb('alice'), 'appeals/a1')));
    await assertFails(getDoc(doc(authedDb('bob'), 'appeals/a1')));
    await assertSucceeds(getDoc(doc(authedDb('aud'), 'appeals/a1')));
  });

  it('admin/manager만 이의제기 처리 (status/reviewedBy 변경)', async () => {
    await seed(async (db) => {
      await setDoc(doc(db, 'appeals/a2'), {
        uid: 'alice', reason: 'r', createdAt: new Date(),
      });
    });
    await createUser('mgr', 'manager');
    await createUser('mod', 'moderator');
    await assertSucceeds(
      updateDoc(doc(authedDb('mgr'), 'appeals/a2'), {
        status: 'accepted', reviewedBy: 'mgr', reviewedAt: new Date(),
      })
    );
    await assertFails(
      updateDoc(doc(authedDb('mod'), 'appeals/a2'), { status: 'accepted' })
    );
  });
});

describe('data_requests collection', () => {
  it('인증 사용자는 본인 uid로 데이터 요청 가능', async () => {
    await createUser('alice');
    await assertSucceeds(
      addDoc(collection(authedDb('alice'), 'data_requests'), {
        uid: 'alice', requestedAt: new Date(), status: 'pending',
      })
    );
  });

  it('정지 사용자는 데이터 요청 거부', async () => {
    await seed(async (db) => {
      await setDoc(doc(db, 'users/sus3'), {
        uid: 'sus3', name: 'S', role: 'user', approved: true,
        verificationStatus: 'verified',
        suspendedUntil: new Date(Date.now() + 24 * 60 * 60 * 1000),
      });
    });
    await assertFails(
      addDoc(collection(authedDb('sus3'), 'data_requests'), {
        uid: 'sus3', requestedAt: new Date(),
      })
    );
  });

  it('남의 uid로 데이터 요청 거부', async () => {
    await createUser('alice');
    await assertFails(
      addDoc(collection(authedDb('alice'), 'data_requests'), {
        uid: 'bob', requestedAt: new Date(),
      })
    );
  });

  it('본인 요청 읽기 가능, 남의 것은 manager 이상', async () => {
    await seed(async (db) => {
      await setDoc(doc(db, 'data_requests/d1'), {
        uid: 'alice', requestedAt: new Date(),
      });
    });
    await createUser('alice');
    await createUser('bob');
    await createUser('mgr', 'manager');
    await createUser('mod', 'moderator');
    await assertSucceeds(getDoc(doc(authedDb('alice'), 'data_requests/d1')));
    await assertFails(getDoc(doc(authedDb('bob'), 'data_requests/d1')));
    await assertSucceeds(getDoc(doc(authedDb('mgr'), 'data_requests/d1')));
    await assertFails(getDoc(doc(authedDb('mod'), 'data_requests/d1')));
  });

  it('클라이언트는 data_requests 직접 update/delete 거부', async () => {
    await seed(async (db) => {
      await setDoc(doc(db, 'data_requests/d2'), {
        uid: 'alice', requestedAt: new Date(),
      });
    });
    await createUser('alice');
    await createUser('mgr', 'manager');
    await assertFails(
      updateDoc(doc(authedDb('mgr'), 'data_requests/d2'), { status: 'done' })
    );
  });
});

describe('teacher_invites collection', () => {
  it('manager는 초대링크 발급 가능', async () => {
    await createUser('mgr', 'manager');
    await assertSucceeds(
      addDoc(collection(authedDb('mgr'), 'teacher_invites'), {
        token: 'abc123', maxUses: 5,
        expiresAt: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000),
        createdBy: 'mgr',
      })
    );
  });

  it('일반 사용자는 초대링크 발급 거부', async () => {
    await createUser('alice');
    await assertFails(
      addDoc(collection(authedDb('alice'), 'teacher_invites'), {
        token: 'x', maxUses: 1,
        expiresAt: new Date(Date.now() + 86400000),
      })
    );
  });

  it('로그인 사용자는 초대링크 검증용 read 가능', async () => {
    await seed(async (db) => {
      await setDoc(doc(db, 'teacher_invites/i1'), {
        token: 't', maxUses: 5, expiresAt: new Date(),
      });
    });
    await createUser('alice');
    await assertSucceeds(getDoc(doc(authedDb('alice'), 'teacher_invites/i1')));
  });

  it('클라이언트는 invite update 거부 (Cloud Functions만 사용 횟수 차감)', async () => {
    await seed(async (db) => {
      await setDoc(doc(db, 'teacher_invites/i2'), {
        token: 't', maxUses: 5, usedCount: 0,
        expiresAt: new Date(Date.now() + 86400000),
      });
    });
    await createUser('mgr', 'manager');
    await assertFails(
      updateDoc(doc(authedDb('mgr'), 'teacher_invites/i2'), { usedCount: 1 })
    );
  });

  it('manager는 초대링크 삭제 가능', async () => {
    await seed(async (db) => {
      await setDoc(doc(db, 'teacher_invites/i3'), {
        token: 't', maxUses: 5,
        expiresAt: new Date(Date.now() + 86400000),
      });
    });
    await createUser('mgr', 'manager');
    await assertSucceeds(deleteDoc(doc(authedDb('mgr'), 'teacher_invites/i3')));
  });
});

describe('community_rules collection', () => {
  it('비로그인 사용자도 규정 읽기 가능', async () => {
    await seed(async (db) => {
      await setDoc(doc(db, 'community_rules/v1'), {
        version: 1, content: '규정 내용', publishedAt: new Date(),
      });
    });
    await assertSucceeds(getDoc(doc(unauthedDb(), 'community_rules/v1')));
  });

  it('manager는 규정 발행 가능', async () => {
    await createUser('mgr', 'manager');
    await assertSucceeds(
      setDoc(doc(authedDb('mgr'), 'community_rules/v2'), {
        version: 2, content: '새 규정', publishedAt: new Date(),
      })
    );
  });

  it('moderator는 규정 발행 거부', async () => {
    await createUser('mod', 'moderator');
    await assertFails(
      setDoc(doc(authedDb('mod'), 'community_rules/v3'), {
        version: 3, content: 'x', publishedAt: new Date(),
      })
    );
  });
});

describe('soft delete (isHidden)', () => {
  beforeEach(async () => {
    await createUser('alice');
    await createUser('bob');
    await createUser('mod', 'moderator');
    await seed(async (db) => {
      await setDoc(doc(db, 'posts/p1'), {
        authorUid: 'alice',
        title: 't',
        content: 'c',
        commentCount: 1,
        isHidden: false,
      });
      await setDoc(doc(db, 'posts/p1/comments/c1'), {
        authorUid: 'alice',
        content: 'cc',
        isHidden: false,
      });
    });
  });

  it('moderator는 글 소프트 삭제 가능 (isHidden=true)', async () => {
    await assertSucceeds(
      updateDoc(doc(authedDb('mod'), 'posts/p1'), {
        isHidden: true,
        deletedAt: new Date(),
        deletedBy: 'mod',
      })
    );
  });

  it('일반 사용자는 남의 글 소프트 삭제 거부', async () => {
    await assertFails(
      updateDoc(doc(authedDb('bob'), 'posts/p1'), {
        isHidden: true,
        deletedAt: new Date(),
        deletedBy: 'bob',
      })
    );
  });

  it('모더가 isHidden 필드 외 다른 필드 같이 변경 시 거부', async () => {
    await assertFails(
      updateDoc(doc(authedDb('mod'), 'posts/p1'), {
        isHidden: true,
        title: '변조됨',
      })
    );
  });

  it('댓글 작성자는 본인 댓글 소프트 삭제 가능', async () => {
    await assertSucceeds(
      updateDoc(doc(authedDb('alice'), 'posts/p1/comments/c1'), {
        isHidden: true,
        deletedAt: new Date(),
        deletedBy: 'alice',
      })
    );
  });

  it('타인 댓글 소프트 삭제는 거부 (모더가 아니면)', async () => {
    await assertFails(
      updateDoc(doc(authedDb('bob'), 'posts/p1/comments/c1'), {
        isHidden: true,
        deletedAt: new Date(),
        deletedBy: 'bob',
      })
    );
  });
});
