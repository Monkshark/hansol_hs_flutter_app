const { initializeApp, cert } = require("firebase-admin/app");
const { getFirestore, Timestamp } = require("firebase-admin/firestore");
const path = require("path");

const serviceAccount = require(path.join(__dirname, "service-account.json"));
initializeApp({ credential: cert(serviceAccount) });
const db = getFirestore();

const now = Timestamp.now();
const ago = (minutes) => Timestamp.fromDate(new Date(Date.now() - minutes * 60000));

// 실제 유저 (채팅용)
const REAL_UID = "57WVXMVoV8OxBnRlrfx60Ffrqyq1";
const REAL_NAME = "추희도";

async function seed() {
  console.log("더미 데이터 삽입 시작...\n");

  // ── 사용자 (20명) ──
  const users = [
    { uid: "demo_admin", name: "관리자", studentId: "20101", grade: 2, classNum: 1, email: "admin@test.com", approved: true, role: "admin", userType: "student", loginProvider: "google" },
    { uid: "demo_manager", name: "김매니저", studentId: "20302", grade: 2, classNum: 3, email: "manager@test.com", approved: true, role: "manager", userType: "student", loginProvider: "google" },
    { uid: "demo_user1", name: "이서준", studentId: "10105", grade: 1, classNum: 1, email: "user1@test.com", approved: true, role: "user", userType: "student", loginProvider: "google" },
    { uid: "demo_user2", name: "박지민", studentId: "20208", grade: 2, classNum: 2, email: "user2@test.com", approved: true, role: "user", userType: "student", loginProvider: "kakao" },
    { uid: "demo_user3", name: "최예린", studentId: "30315", grade: 3, classNum: 3, email: "user3@test.com", approved: true, role: "user", userType: "student", loginProvider: "apple" },
    { uid: "demo_user4", name: "정하늘", studentId: "10210", grade: 1, classNum: 2, email: "user4@test.com", approved: true, role: "user", userType: "student", loginProvider: "github" },
    { uid: "demo_user5", name: "강민호", studentId: "20105", grade: 2, classNum: 1, email: "user5@test.com", approved: true, role: "user", userType: "student", loginProvider: "google" },
    { uid: "demo_user6", name: "윤서아", studentId: "10308", grade: 1, classNum: 3, email: "user6@test.com", approved: true, role: "user", userType: "student", loginProvider: "kakao" },
    { uid: "demo_user7", name: "임도현", studentId: "30207", grade: 3, classNum: 2, email: "user7@test.com", approved: true, role: "user", userType: "student", loginProvider: "google" },
    { uid: "demo_user8", name: "한소희", studentId: "20412", grade: 2, classNum: 4, email: "user8@test.com", approved: true, role: "user", userType: "student", loginProvider: "apple" },
    { uid: "demo_user9", name: "오준혁", studentId: "10415", grade: 1, classNum: 4, email: "user9@test.com", approved: true, role: "user", userType: "student", loginProvider: "google" },
    { uid: "demo_user10", name: "신유진", studentId: "30110", grade: 3, classNum: 1, email: "user10@test.com", approved: true, role: "user", userType: "student", loginProvider: "kakao" },
    { uid: "demo_teacher1", name: "김태영", email: "teacher1@test.com", studentId: "", grade: 0, classNum: 0, approved: true, role: "user", userType: "teacher", teacherSubject: "수학", loginProvider: "google" },
    { uid: "demo_teacher2", name: "박수연", email: "teacher2@test.com", studentId: "", grade: 0, classNum: 0, approved: true, role: "user", userType: "teacher", teacherSubject: "영어", loginProvider: "google" },
    { uid: "demo_graduate1", name: "홍성민", email: "grad1@test.com", studentId: "", grade: 0, classNum: 0, approved: true, role: "user", userType: "graduate", graduationYear: 2025, loginProvider: "kakao" },
    { uid: "demo_graduate2", name: "장서윤", email: "grad2@test.com", studentId: "", grade: 0, classNum: 0, approved: true, role: "user", userType: "graduate", graduationYear: 2024, loginProvider: "google" },
    { uid: "demo_parent", name: "김영숙", email: "parent@test.com", studentId: "", grade: 0, classNum: 0, approved: true, role: "user", userType: "parent", loginProvider: "google" },
    { uid: "demo_pending1", name: "가입신청_이현우", studentId: "10501", grade: 1, classNum: 5, email: "pending1@test.com", approved: false, role: "user", userType: "student", loginProvider: "google" },
    { uid: "demo_pending2", name: "가입신청_김소연", studentId: "20601", grade: 2, classNum: 6, email: "pending2@test.com", approved: false, role: "user", userType: "student", loginProvider: "kakao" },
    { uid: "demo_pending3", name: "가입신청_박준서", studentId: "30401", grade: 3, classNum: 4, email: "pending3@test.com", approved: false, role: "user", userType: "student", loginProvider: "github" },
    { uid: "demo_suspended1", name: "정지_홍길동", studentId: "20501", grade: 2, classNum: 5, email: "sus1@test.com", approved: true, role: "user", userType: "student", loginProvider: "google", suspendedUntil: Timestamp.fromDate(new Date(Date.now() + 7 * 24 * 60 * 60000)) },
    { uid: "demo_suspended2", name: "정지_김영희", studentId: "10601", grade: 1, classNum: 6, email: "sus2@test.com", approved: true, role: "user", userType: "student", loginProvider: "kakao", suspendedUntil: Timestamp.fromDate(new Date(Date.now() + 1 * 24 * 60 * 60000)) },
  ];

  for (const u of users) {
    await db.collection("users").doc(u.uid).set({
      ...u,
      updatedAt: now,
      blockedUsers: [],
      lastProfileUpdate: "2026",
      notiComment: true, notiReply: true, notiNewPost: true, notiChat: true, notiAccount: true,
    });
  }
  console.log(`✓ 사용자 ${users.length}명 생성`);

  // ── 게시글 (20개) ──
  const posts = [
    { title: "중간고사 시험 범위 공유합니다", content: "수학: 1~3단원\n영어: Lesson 1~4\n국어: 현대시 + 고전소설\n과학: 힘과 운동 전체\n\n다들 파이팅!", category: "정보공유", authorUid: "demo_user1", authorName: "10105 이서준", isAnonymous: false, likes: 42, dislikes: 0, isPinned: true, pinnedAt: now },
    { title: "급식 너무 맛있다 ㅋㅋ", content: "오늘 돈까스 진짜 맛있었음\n급식 아주머니 감사합니다", category: "자유", authorUid: "demo_user2", authorName: "익명", isAnonymous: true, likes: 67, dislikes: 2, isPinned: false },
    { title: "에어팟 프로 분실했습니다", content: "3층 남자화장실 근처에서 잃어버린 것 같습니다.\n검정색 케이스에 이름 스티커 붙어있어요.\n찾으신 분 댓글 부탁드립니다", category: "분실물", authorUid: "demo_user3", authorName: "30315 최예린", isAnonymous: false, likes: 8, dislikes: 0, isResolved: false, isPinned: false },
    { title: "동아리 축제 일정 안내", content: "이번 동아리 축제는 5월 16일~17일입니다.\n각 동아리별 부스 신청은 다음 주까지!\n\n장소: 체육관 + 운동장\n시간: 10:00 ~ 16:00", category: "동아리", authorUid: "demo_manager", authorName: "20302 김매니저", isAnonymous: false, likes: 89, dislikes: 0, isPinned: true, pinnedAt: ago(60) },
    { title: "수학 문제 질문이요", content: "수학 교과서 p.142 5번 문제 어떻게 푸나요?\nlim(x→0) sin(3x)/x 이거 답이 3 맞나요?", category: "질문", authorUid: "demo_user4", authorName: "익명", isAnonymous: true, likes: 15, dislikes: 0, isPinned: false },
    { title: "학생회 체육대회 종목 투표", content: "이번 체육대회 종목을 정하려고 합니다.\n아래에서 투표해주세요!", category: "학생회", authorUid: "demo_admin", authorName: "20101 관리자", isAnonymous: false, likes: 53, dislikes: 0, isPinned: true, pinnedAt: ago(120), pollOptions: ["축구", "피구", "농구", "줄다리기", "계주", "발야구"], pollVotes: { "축구": 145, "피구": 98, "농구": 87, "줄다리기": 45, "계주": 32, "발야구": 112 }, pollVoters: [] },
    { title: "도서관 자리 양도합니다", content: "오늘 오후 3시 이후 도서관 3번 자리 비워요\n필요하신 분 댓글 달아주세요", category: "자유", authorUid: "demo_user5", authorName: "익명", isAnonymous: true, likes: 5, dislikes: 0, isPinned: false },
    { title: "코딩 동아리 신규 부원 모집", content: "코딩 동아리에서 신규 부원을 모집합니다!\n\n활동: 매주 수요일 방과후\n대상: 1~2학년\n내용: Python, 알고리즘, 프로젝트\n\n관심있는 학생은 댓글 남겨주세요.", category: "동아리", authorUid: "demo_user4", authorName: "10210 정하늘", isAnonymous: false, likes: 38, dislikes: 0, isPinned: false },
    { title: "USB 찾습니다", content: "2층 컴퓨터실에 삼성 USB 32GB 놓고 갔습니다.\n파란색이에요. 혹시 보신 분?", category: "분실물", authorUid: "demo_user6", authorName: "10308 윤서아", isAnonymous: false, likes: 3, dislikes: 0, isResolved: true, isPinned: false },
    { title: "방과후 수업 추천해주세요", content: "2학기 방과후 뭐 들을지 고민중인데\n추천해주실 분 있나요?\n영어회화 vs 수학심화 고민중", category: "질문", authorUid: "demo_user7", authorName: "익명", isAnonymous: true, likes: 19, dislikes: 0, isPinned: false },
    { title: "오늘 체육 뭐해요?", content: "비오는데 체육 실내에서 하나요?\n혹시 아시는 분?", category: "자유", authorUid: "demo_user8", authorName: "익명", isAnonymous: true, likes: 11, dislikes: 0, isPinned: false },
    { title: "학생회 예산 사용 내역 공개", content: "1학기 학생회 예산 사용 내역입니다.\n\n체육대회: 120만원\n축제: 80만원\n간식비: 30만원\n비품: 20만원\n\n질문 있으시면 댓글 남겨주세요.", category: "학생회", authorUid: "demo_manager", authorName: "20302 김매니저", isAnonymous: false, likes: 45, dislikes: 3, isPinned: false },
    { title: "영어 단어 외우는 팁", content: "제가 쓰는 방법 공유합니다\n\n1. 하루 30개씩 (아침에)\n2. 잠들기 전 복습\n3. 예문으로 같이 외우기\n4. 3일마다 누적 테스트\n\n이렇게 하니까 한 달에 900개 외웠어요!", category: "정보공유", authorUid: "demo_user9", authorName: "10415 오준혁", isAnonymous: false, likes: 76, dislikes: 0, isPinned: false },
    { title: "점심시간에 농구할 사람?", content: "점심시간에 체육관에서 3:3 농구 하실 분 구합니다\n매일 가능! 실력 상관없어요", category: "자유", authorUid: "demo_user5", authorName: "20105 강민호", isAnonymous: false, likes: 22, dislikes: 0, isPinned: false },
    { title: "검정 우산 주인 찾습니다", content: "1층 우산 꽂이에 검정 장우산 한 개 남아있습니다.\n손잡이에 곰돌이 키링 달려있어요.\n이번 주까지 안 찾아가시면 분실물 보관함으로 옮기겠습니다.", category: "분실물", authorUid: "demo_teacher1", authorName: "교사 김태영", isAnonymous: false, likes: 2, dislikes: 0, isResolved: false, isPinned: false },
    { title: "내신 등급 컷 아시는 분?", content: "이번 중간고사 수학 등급 컷 아시는 분 있나요?\n1등급 몇 점인지 궁금합니다", category: "질문", authorUid: "demo_user10", authorName: "익명", isAnonymous: true, likes: 28, dislikes: 0, isPinned: false },
    { title: "졸업생인데 학교 많이 변했네요", content: "25년도 졸업생입니다.\n앱이 생겼다길래 깔아봤는데 좋네요\n재학생 여러분 학교생활 화이팅!", category: "자유", authorUid: "demo_graduate1", authorName: "졸업생 홍성민", isAnonymous: false, likes: 34, dislikes: 0, isPinned: false },
    { title: "학교 앞 붕어빵 맛집 추천", content: "정문 나가서 오른쪽으로 50m 가면 있는 붕어빵 가게\n팥 붕어빵이 진짜 맛있어요 2개 1000원\n\n슈크림은 별로...", category: "자유", authorUid: "demo_user2", authorName: "익명", isAnonymous: true, likes: 55, dislikes: 1, isPinned: false },
    { title: "과학실험 보고서 양식", content: "과학 실험 보고서 양식 공유합니다.\n\n1. 실험 제목\n2. 실험 목적\n3. 가설\n4. 실험 방법\n5. 결과\n6. 결론 및 고찰\n\n선생님이 이 순서대로 쓰래요", category: "정보공유", authorUid: "demo_user3", authorName: "30315 최예린", isAnonymous: false, likes: 41, dislikes: 0, isPinned: false },
    { title: "급식 메뉴 건의", content: "학생회에 건의합니다.\n떡볶이 좀 자주 나오게 해주세요!\n저번에 나온 로제 떡볶이 너무 맛있었어요", category: "학생회", authorUid: "demo_user8", authorName: "익명", isAnonymous: true, likes: 93, dislikes: 5, isPinned: false },
    { title: "학부모 입장에서 앱 후기", content: "아이가 이 앱으로 급식 확인하는 걸 보고 저도 깔아봤습니다.\n학부모로서 아이 학교 소식을 앱으로 볼 수 있어서 좋네요.\n시간표도 확인 가능하면 더 좋을 것 같습니다.", category: "자유", authorUid: "demo_parent", authorName: "학부모 김영숙", isAnonymous: false, likes: 28, dislikes: 0, isPinned: false },
    { title: "학부모 간담회 일정 문의", content: "이번 학기 학부모 간담회 일정이 언제인가요?\n작년에는 5월에 했던 것 같은데 올해 일정을 모르겠어요.", category: "질문", authorUid: "demo_parent", authorName: "학부모 김영숙", isAnonymous: false, likes: 12, dislikes: 0, isPinned: false },
  ];

  const postIds = [];
  for (let i = 0; i < posts.length; i++) {
    const ref = await db.collection("posts").add({
      ...posts[i],
      likedBy: [], dislikedBy: [], bookmarkedBy: i < 5 ? [REAL_UID, "demo_user1"] : [],
      createdAt: ago(i * 90 + 10),
      commentCount: 0,
    });
    postIds.push(ref.id);
  }
  console.log(`✓ 게시글 ${posts.length}개 생성`);

  // ── 댓글 (30개) ──
  // 댓글: id를 키로, reply는 parentKey로 참조
  const commentDefs = [
    // post 0: 시험 범위
    { key: "c0a", postIdx: 0, authorUid: "demo_user2", authorName: "익명", content: "감사합니다! 과학 범위 정확한건가요?", isAnonymous: true },
    { key: "c0b", postIdx: 0, authorUid: "demo_user1", authorName: "10105 이서준", content: "네 선생님이 오늘 말씀하신 범위에요!", isAnonymous: false, parentKey: "c0a" },
    { key: "c0c", postIdx: 0, authorUid: "demo_user3", authorName: "익명", content: "역사는 범위 아시는 분?", isAnonymous: true },
    { key: "c0d", postIdx: 0, authorUid: "demo_user7", authorName: "익명", content: "역사는 3단원까지입니다", isAnonymous: true, parentKey: "c0c" },
    { key: "c0e", postIdx: 0, authorUid: "demo_user5", authorName: "익명", content: "과학은 실험 부분도 포함인가요?", isAnonymous: true, parentKey: "c0a" },

    // post 1: 급식
    { key: "c1a", postIdx: 1, authorUid: "demo_user3", authorName: "익명", content: "ㅋㅋ 나도 오늘 급식 인정", isAnonymous: true },
    { key: "c1b", postIdx: 1, authorUid: "demo_user4", authorName: "익명", content: "돈까스 소스가 찐이었음", isAnonymous: true },
    { key: "c1c", postIdx: 1, authorUid: "demo_user9", authorName: "익명", content: "매일 이랬으면 좋겠다", isAnonymous: true, parentKey: "c1a" },

    // post 2: 분실물
    { key: "c2a", postIdx: 2, authorUid: "demo_user4", authorName: "10210 정하늘", content: "3층 교무실 앞에서 비슷한거 봤는데 확인해보세요!", isAnonymous: false },
    { key: "c2b", postIdx: 2, authorUid: "demo_user3", authorName: "30315 최예린", content: "감사합니다! 가서 확인해볼게요", isAnonymous: false, parentKey: "c2a" },
    { key: "c2c", postIdx: 2, authorUid: "demo_user6", authorName: "10308 윤서아", content: "혹시 케이스에 스티커 없는 건 아니죠?", isAnonymous: false },
    { key: "c2d", postIdx: 2, authorUid: "demo_user3", authorName: "30315 최예린", content: "네 이름 스티커 붙어있어요!", isAnonymous: false, parentKey: "c2c" },

    // post 4: 수학 질문
    { key: "c4a", postIdx: 4, authorUid: "demo_user1", authorName: "익명", content: "네 맞아요. 로피탈 쓰면 바로 나옵니다", isAnonymous: true },
    { key: "c4b", postIdx: 4, authorUid: "demo_teacher1", authorName: "교사 김태영", content: "sin(3x)/x = 3 · sin(3x)/(3x) → 3 정답입니다. 치환을 이용하면 더 깔끔해요.", isAnonymous: false },
    { key: "c4c", postIdx: 4, authorUid: "demo_user5", authorName: "익명", content: "선생님 감사합니다!", isAnonymous: true, parentKey: "c4b" },
    { key: "c4d", postIdx: 4, authorUid: "demo_user4", authorName: "익명", content: "로피탈은 어떻게 쓰는건가요?", isAnonymous: true, parentKey: "c4a" },
    { key: "c4e", postIdx: 4, authorUid: "demo_user1", authorName: "익명", content: "분모분자 각각 미분하면 됩니다", isAnonymous: true, parentKey: "c4d" },

    // post 7: 코딩 동아리
    { key: "c7a", postIdx: 7, authorUid: "demo_user1", authorName: "10105 이서준", content: "저 관심있어요! 파이썬 초보인데 괜찮나요?", isAnonymous: false },
    { key: "c7b", postIdx: 7, authorUid: "demo_user4", authorName: "10210 정하늘", content: "물론이죠! 기초부터 가르쳐드려요", isAnonymous: false, parentKey: "c7a" },
    { key: "c7c", postIdx: 7, authorUid: "demo_user6", authorName: "10308 윤서아", content: "저도 가입하고 싶어요~", isAnonymous: false },
    { key: "c7d", postIdx: 7, authorUid: "demo_user4", authorName: "10210 정하늘", content: "환영합니다! 수요일에 봐요", isAnonymous: false, parentKey: "c7c" },
    { key: "c7e", postIdx: 7, authorUid: "demo_user9", authorName: "10415 오준혁", content: "웹개발도 배울 수 있나요?", isAnonymous: false },
    { key: "c7f", postIdx: 7, authorUid: "demo_user4", authorName: "10210 정하늘", content: "네 2학기부터 웹 프로젝트도 할 예정이에요", isAnonymous: false, parentKey: "c7e" },

    // post 9: 방과후 추천
    { key: "c9a", postIdx: 9, authorUid: "demo_user1", authorName: "익명", content: "영어회화 강추합니다 원어민 선생님이세요", isAnonymous: true },
    { key: "c9b", postIdx: 9, authorUid: "demo_user4", authorName: "익명", content: "수학심화는 내신에 도움 많이 됨", isAnonymous: true },
    { key: "c9c", postIdx: 9, authorUid: "demo_user8", authorName: "익명", content: "둘 다 들어도 괜찮아요 시간 안 겹쳐요", isAnonymous: true, parentKey: "c9a" },
    { key: "c9d", postIdx: 9, authorUid: "demo_user7", authorName: "익명", content: "수학심화 선생님 누구세요?", isAnonymous: true, parentKey: "c9b" },

    // post 11: 예산
    { key: "c11a", postIdx: 11, authorUid: "demo_user3", authorName: "익명", content: "체육대회 예산이 제일 많네요", isAnonymous: true },
    { key: "c11b", postIdx: 11, authorUid: "demo_manager", authorName: "20302 김매니저", content: "대관료가 포함되어서 그래요!", isAnonymous: false, parentKey: "c11a" },

    // post 12: 영어 단어
    { key: "c12a", postIdx: 12, authorUid: "demo_user5", authorName: "20105 강민호", content: "와 진짜 유용한 팁이다", isAnonymous: false },
    { key: "c12b", postIdx: 12, authorUid: "demo_user8", authorName: "익명", content: "앱 추천도 해주세요!", isAnonymous: true, parentKey: "c12a" },
    { key: "c12c", postIdx: 12, authorUid: "demo_user9", authorName: "10415 오준혁", content: "Anki 추천합니다!", isAnonymous: false, parentKey: "c12b" },

    // post 13: 농구
    { key: "c13a", postIdx: 13, authorUid: "demo_user7", authorName: "30207 임도현", content: "저 할래요! 매일 가능합니다", isAnonymous: false },
    { key: "c13b", postIdx: 13, authorUid: "demo_user5", authorName: "20105 강민호", content: "좋아요! 내일부터 하죠", isAnonymous: false, parentKey: "c13a" },

    // post 15: 등급 컷
    { key: "c15a", postIdx: 15, authorUid: "demo_user5", authorName: "익명", content: "수학 92점이면 몇 등급일까요...", isAnonymous: true },
    { key: "c15b", postIdx: 15, authorUid: "demo_user10", authorName: "익명", content: "작년에는 94점이 1등급 컷이었어요", isAnonymous: true, parentKey: "c15a" },

    // post 16: 졸업생
    { key: "c16a", postIdx: 16, authorUid: "demo_user1", authorName: "10105 이서준", content: "졸업생 선배님 감사합니다!", isAnonymous: false },

    // post 17: 붕어빵
    { key: "c17a", postIdx: 17, authorUid: "demo_user10", authorName: "익명", content: "거기 슈크림은 진짜 별로임 ㅋㅋ 동의", isAnonymous: true },
    { key: "c17b", postIdx: 17, authorUid: "demo_user5", authorName: "익명", content: "팥이 국룰이지", isAnonymous: true, parentKey: "c17a" },

    // post 19: 급식 건의
    { key: "c19a", postIdx: 19, authorUid: "demo_user1", authorName: "익명", content: "로제 떡볶이 +1", isAnonymous: true },
    { key: "c19b", postIdx: 19, authorUid: "demo_user9", authorName: "익명", content: "치킨도 좀...", isAnonymous: true },
    { key: "c19c", postIdx: 19, authorUid: "demo_user5", authorName: "익명", content: "치킨은 위생 문제로 어렵대요", isAnonymous: true, parentKey: "c19b" },

    // post 20: 학부모 후기
    { key: "c20a", postIdx: 20, authorUid: "demo_user1", authorName: "10105 이서준", content: "학부모님 감사합니다! 좋은 후기 남겨주셔서요", isAnonymous: false },
    { key: "c20b", postIdx: 20, authorUid: "demo_teacher1", authorName: "교사 김태영", content: "학부모님 의견 감사합니다. 시간표 기능도 곧 학부모용으로 업데이트될 예정입니다.", isAnonymous: false },
    { key: "c20c", postIdx: 20, authorUid: "demo_parent", authorName: "학부모 김영숙", content: "감사합니다 선생님!", isAnonymous: false, parentKey: "c20b" },

    // post 21: 학부모 간담회
    { key: "c21a", postIdx: 21, authorUid: "demo_manager", authorName: "20302 김매니저", content: "학부모 간담회는 5월 23일 예정입니다!", isAnonymous: false },
    { key: "c21b", postIdx: 21, authorUid: "demo_parent", authorName: "학부모 김영숙", content: "감사합니다! 장소는 어디인가요?", isAnonymous: false, parentKey: "c21a" },
    { key: "c21c", postIdx: 21, authorUid: "demo_manager", authorName: "20302 김매니저", content: "본관 3층 시청각실입니다!", isAnonymous: false, parentKey: "c21b" },
  ];

  // 댓글 삽입 (parentId 참조를 위해 key→id 맵 관리)
  const commentIdMap = {};
  let commentCount = 0;
  for (const c of commentDefs) {
    const data = {
      authorUid: c.authorUid, authorName: c.authorName, content: c.content, isAnonymous: c.isAnonymous,
      createdAt: ago(Math.floor(Math.random() * 500) + 10),
    };
    if (c.parentKey && commentIdMap[c.parentKey]) {
      data.parentId = commentIdMap[c.parentKey];
    }
    const ref = await db.collection("posts").doc(postIds[c.postIdx]).collection("comments").add(data);
    commentIdMap[c.key] = ref.id;
    commentCount++;
  }
  console.log(`✓ 댓글 ${commentCount}개 생성 (대댓글 포함)`);

  // ── 채팅 (실제 유저와 더미 유저 3개) ──
  const chats = [
    {
      id: [REAL_UID, "demo_user1"].sort().join("_"),
      other: "demo_user1", otherName: "10105 이서준",
      messages: [
        { sender: "demo_user1", name: "10105 이서준", content: "선배님 안녕하세요! 졸업생이신거 봤어요", min: 180 },
        { sender: REAL_UID, name: REAL_NAME, content: "안녕 ㅎㅎ 반가워", min: 175 },
        { sender: "demo_user1", name: "10105 이서준", content: "대학 생활 어떠세요?", min: 170 },
        { sender: REAL_UID, name: REAL_NAME, content: "재밌어! 근데 한솔고가 그립긴 하다 ㅋㅋ", min: 165 },
        { sender: "demo_user1", name: "10105 이서준", content: "ㅋㅋㅋ 내신 팁 좀 알려주세요", min: 160 },
        { sender: REAL_UID, name: REAL_NAME, content: "수학은 기출 많이 풀어봐. 선생님 스타일 파악하는게 제일 중요해", min: 155 },
        { sender: "demo_user1", name: "10105 이서준", content: "감사합니다! 참고할게요", min: 150 },
        { sender: REAL_UID, name: REAL_NAME, content: "화이팅!", min: 145 },
      ],
    },
    {
      id: [REAL_UID, "demo_user4"].sort().join("_"),
      other: "demo_user4", otherName: "10210 정하늘",
      messages: [
        { sender: "demo_user4", name: "10210 정하늘", content: "안녕하세요! 코딩 동아리 관련해서 여쭤볼게 있어요", min: 90 },
        { sender: REAL_UID, name: REAL_NAME, content: "응 말해봐~", min: 85 },
        { sender: "demo_user4", name: "10210 정하늘", content: "혹시 졸업하시기 전에 동아리에서 뭐 만드셨어요?", min: 80 },
        { sender: REAL_UID, name: REAL_NAME, content: "학교 앱 만들었지 ㅋㅋ 지금 쓰고 있는 이 앱이야", min: 75 },
        { sender: "demo_user4", name: "10210 정하늘", content: "대박 이 앱을 만드셨어요?? 진짜 잘 만드셨다", min: 70 },
        { sender: REAL_UID, name: REAL_NAME, content: "고마워 ㅎㅎ Flutter로 만들었어. 관심있으면 코드 공유해줄게", min: 65 },
        { sender: "demo_user4", name: "10210 정하늘", content: "와 감사합니다!! 꼭 보고싶어요", min: 60 },
        { sender: REAL_UID, name: REAL_NAME, content: "GitHub에 올려놨으니까 한번 봐봐", min: 55 },
        { sender: "demo_user4", name: "10210 정하늘", content: "넵! 감사합니다 선배님!", min: 50 },
      ],
    },
    {
      id: [REAL_UID, "demo_manager"].sort().join("_"),
      other: "demo_manager", otherName: "20302 김매니저",
      messages: [
        { sender: "demo_manager", name: "20302 김매니저", content: "선배님 앱 관리자 권한 관련 질문이요", min: 30 },
        { sender: REAL_UID, name: REAL_NAME, content: "응 뭔데?", min: 25 },
        { sender: "demo_manager", name: "20302 김매니저", content: "신고된 글 처리는 어떻게 하면 되나요?", min: 20 },
        { sender: REAL_UID, name: REAL_NAME, content: "Admin 탭 들어가서 신고 섹션 보면 돼. 거기서 글 확인하고 삭제하면 됨", min: 15 },
        { sender: "demo_manager", name: "20302 김매니저", content: "아 감사합니다! 해볼게요", min: 10 },
        { sender: REAL_UID, name: REAL_NAME, content: "궁금한거 있으면 언제든 물어봐", min: 5 },
      ],
    },
  ];

  for (const chat of chats) {
    await db.collection("chats").doc(chat.id).set({
      participants: [REAL_UID, chat.other],
      participantNames: { [REAL_UID]: REAL_NAME, [chat.other]: chat.otherName },
      lastMessage: chat.messages[chat.messages.length - 1].content,
      lastMessageAt: ago(chat.messages[chat.messages.length - 1].min),
      unreadCount: { [REAL_UID]: 1, [chat.other]: 0 },
    });
    for (const m of chat.messages) {
      await db.collection("chats").doc(chat.id).collection("messages").add({
        senderUid: m.sender, senderName: m.name, content: m.content,
        createdAt: ago(m.min), deletedFor: [],
      });
    }
  }
  console.log(`✓ 채팅 ${chats.length}개 (메시지 ${chats.reduce((a, c) => a + c.messages.length, 0)}개) 생성`);

  // ── 신고 (5건) ──
  const reports = [
    { postId: postIds[1], reporterUid: "demo_user3", reason: "부적절한 내용" },
    { postId: postIds[6], reporterUid: "demo_user2", reason: "광고/홍보" },
    { postId: postIds[10], reporterUid: "demo_user7", reason: "도배" },
    { postId: postIds[17], reporterUid: "demo_user10", reason: "허위 정보" },
    { postId: postIds[1], reporterUid: "demo_user9", reason: "욕설/비방" },
  ];

  for (const r of reports) {
    await db.collection("reports").add({ ...r, createdAt: ago(Math.floor(Math.random() * 1440)) });
  }
  console.log(`✓ 신고 ${reports.length}건 생성`);

  // ── 관리자 로그 (10건) ──
  const adminLogs = [
    { action: "approve_user", adminUid: "demo_admin", adminName: "관리자", targetName: "이서준" },
    { action: "approve_user", adminUid: "demo_admin", adminName: "관리자", targetName: "박지민" },
    { action: "approve_user", adminUid: "demo_admin", adminName: "관리자", targetName: "최예린" },
    { action: "approve_user", adminUid: "demo_manager", adminName: "김매니저", targetName: "정하늘" },
    { action: "delete_post", adminUid: "demo_admin", adminName: "관리자", postId: "old_1", postTitle: "부적절한 게시글입니다", postAuthorUid: "demo_user99", postAuthorName: "알수없음" },
    { action: "delete_post", adminUid: "demo_manager", adminName: "김매니저", postId: "old_2", postTitle: "광고성 게시글", postAuthorUid: "demo_user98", postAuthorName: "광고계정" },
    { action: "suspend_user", adminUid: "demo_admin", adminName: "관리자", targetName: "정지_홍길동", duration: "7일" },
    { action: "suspend_user", adminUid: "demo_admin", adminName: "관리자", targetName: "정지_김영희", duration: "1일" },
    { action: "role_change", adminUid: "demo_admin", adminName: "관리자", targetName: "김매니저", newRole: "manager" },
    { action: "reject_user", adminUid: "demo_admin", adminName: "관리자", targetName: "스팸계정" },
  ];

  for (let i = 0; i < adminLogs.length; i++) {
    await db.collection("admin_logs").add({ ...adminLogs[i], createdAt: ago(i * 720 + 60) });
  }
  console.log(`✓ 관리자 로그 ${adminLogs.length}건 생성`);

  // ── 건의사항 (8건) ──
  const feedbacks = [
    { col: "council_feedbacks", content: "체육관 에어컨 좀 틀어주세요. 너무 더워서 운동하기 힘듭니다.", authorUid: "demo_user1", authorName: "10105 이서준", status: "pending" },
    { col: "council_feedbacks", content: "급식실 줄이 너무 길어요. 학년별 시간 분리하면 좋겠습니다.", authorUid: "demo_user2", authorName: "20208 박지민", status: "reviewed" },
    { col: "council_feedbacks", content: "도서관 이용 시간을 저녁 8시까지 연장해주세요.", authorUid: "demo_user3", authorName: "30315 최예린", status: "resolved" },
    { col: "council_feedbacks", content: "교복 자율화 건의드립니다. 체육복 등교 허용해주세요.", authorUid: "demo_user5", authorName: "20105 강민호", status: "pending" },
    { col: "council_feedbacks", content: "화장실 비누가 자주 떨어져요. 보충 주기를 줄여주세요.", authorUid: "demo_user8", authorName: "20412 한소희", status: "pending" },
    { col: "app_feedbacks", content: "다크모드에서 게시판 글씨가 잘 안 보여요. 색상 조정 부탁드립니다.", authorUid: "demo_user4", authorName: "10210 정하늘", status: "pending" },
    { col: "app_feedbacks", content: "시간표 화면에서 가끔 로딩이 오래 걸립니다. 5초 이상 걸릴 때가 있어요.", authorUid: "demo_user1", authorName: "10105 이서준", status: "reviewed" },
    { col: "app_feedbacks", content: "채팅에서 사진도 보낼 수 있게 해주세요!", authorUid: "demo_user6", authorName: "10308 윤서아", status: "pending" },
  ];

  for (let i = 0; i < feedbacks.length; i++) {
    const { col, ...data } = feedbacks[i];
    await db.collection(col).add({ ...data, imageUrls: [], createdAt: ago(i * 480 + 30) });
  }
  console.log(`✓ 건의사항 ${feedbacks.length}건 생성`);

  // ── 크래시 로그 (4건) ──
  const crashes = [
    { error: "RangeError: Invalid value: Not in inclusive range 0..5, actual value: -1", stack: "at _HomeScreenState.build (home_screen.dart:142)\nat StatefulElement.build (framework.dart:5765)\nat ComponentElement.performRebuild", library: "flutter", uid: "demo_user1" },
    { error: "NoSuchMethodError: Class 'Null' has no instance method '[]'", stack: "at _PostDetailScreenState._buildComments (post_detail_screen.dart:523)\nat StreamBuilder.build (async.dart:247)", library: "flutter", uid: "demo_user3" },
    { error: "SocketException: Connection refused", stack: "at NetworkStatus.check (network_status.dart:15)\nat MealDataApi.getMeal (meal_data_api.dart:48)", library: "dart:io", uid: "demo_user7" },
    { error: "FormatException: Unexpected character (at character 1)", stack: "at jsonDecode (convert.dart:96)\nat TimetableDataApi.getTimeTable (timetable_data_api.dart:82)", library: "dart:convert", uid: "demo_user5" },
  ];

  for (const c of crashes) {
    await db.collection("crash_logs").add({ ...c, createdAt: ago(Math.floor(Math.random() * 4320)) });
  }
  console.log(`✓ 크래시 로그 ${crashes.length}건 생성`);

  // ── 알림 (실제 유저용, 6건) ──
  const notifications = [
    { type: "comment", postId: postIds[0], postTitle: "중간고사 시험 범위 공유합니다", senderName: "익명", content: "감사합니다! 과학 범위 정확한건가요?", read: false },
    { type: "comment", postId: postIds[7], postTitle: "코딩 동아리 신규 부원 모집", senderName: "10105 이서준", content: "저 관심있어요!", read: false },
    { type: "comment", postId: postIds[4], postTitle: "수학 문제 질문이요", senderName: "교사 김태영", content: "sin(3x)/x = 3 정답입니다", read: true },
    { type: "account", postId: "", postTitle: "가입 요청", senderName: "가입신청_이현우", content: "가입신청_이현우님이 가입을 요청했습니다.", read: false },
    { type: "account", postId: "", postTitle: "가입 요청", senderName: "가입신청_김소연", content: "가입신청_김소연님이 가입을 요청했습니다.", read: false },
    { type: "account", postId: "", postTitle: "가입 요청", senderName: "가입신청_박준서", content: "가입신청_박준서님이 가입을 요청했습니다.", read: true },
  ];

  for (const n of notifications) {
    await db.collection("users").doc(REAL_UID).collection("notifications").add({
      ...n, createdAt: ago(Math.floor(Math.random() * 180)),
    });
  }
  console.log(`✓ 알림 ${notifications.length}건 생성 (${REAL_NAME})`);

  console.log("\n✅ 더미 데이터 삽입 완료!");
  console.log("삭제: node seed_dummy_data.js --delete");
}

async function deleteAll() {
  console.log("더미 데이터 삭제 시작...\n");

  const demoUids = [
    "demo_admin", "demo_manager",
    "demo_user1", "demo_user2", "demo_user3", "demo_user4", "demo_user5",
    "demo_user6", "demo_user7", "demo_user8", "demo_user9", "demo_user10",
    "demo_teacher1", "demo_teacher2", "demo_graduate1", "demo_graduate2", "demo_parent",
    "demo_pending1", "demo_pending2", "demo_pending3",
    "demo_suspended1", "demo_suspended2",
  ];

  for (const uid of demoUids) {
    for (const sub of ["subjects", "notifications"]) {
      const snap = await db.collection(`users/${uid}/${sub}`).get();
      for (const doc of snap.docs) await doc.ref.delete();
    }
    await db.collection("users").doc(uid).delete();
  }

  // 실제 유저 알림만 삭제
  const notiSnap = await db.collection(`users/${REAL_UID}/notifications`).get();
  for (const doc of notiSnap.docs) await doc.ref.delete();

  console.log("✓ 사용자 삭제");

  for (const col of ["posts", "reports", "admin_logs", "crash_logs", "app_feedbacks", "council_feedbacks"]) {
    const snap = await db.collection(col).get();
    for (const doc of snap.docs) {
      if (col === "posts") {
        const subs = await doc.ref.collection("comments").get();
        for (const s of subs.docs) await s.ref.delete();
      }
      await doc.ref.delete();
    }
    console.log(`✓ ${col} 삭제`);
  }

  const chatSnap = await db.collection("chats").get();
  for (const doc of chatSnap.docs) {
    const msgs = await doc.ref.collection("messages").get();
    for (const m of msgs.docs) await m.ref.delete();
    await doc.ref.delete();
  }
  console.log("✓ 채팅 삭제");

  console.log("\n✅ 더미 데이터 삭제 완료!");
}

if (process.argv.includes("--delete")) {
  deleteAll().catch(console.error);
} else {
  seed().catch(console.error);
}
