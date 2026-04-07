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

  it('남의 글 좋아요 +1은 허용 (interaction 필드)', async () => {
    await createUser('alice');
    await createUser('bob');
    await seed(async (db) => {
      await setDoc(doc(db, 'posts/p4'), {
        authorUid: 'alice',
        title: 't',
        content: 'c',
        likes: 0,
      });
    });
    await assertSucceeds(
      updateDoc(doc(authedDb('bob'), 'posts/p4'), { likes: 1 })
    );
  });

  it('좋아요 +5처럼 큰 폭 증가는 거부 (counter delta 검증)', async () => {
    await createUser('alice');
    await createUser('bob');
    await seed(async (db) => {
      await setDoc(doc(db, 'posts/p5'), {
        authorUid: 'alice',
        title: 't',
        content: 'c',
        likes: 0,
      });
    });
    await assertFails(
      updateDoc(doc(authedDb('bob'), 'posts/p5'), { likes: 5 })
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
});
