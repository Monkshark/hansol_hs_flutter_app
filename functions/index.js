const { onDocumentCreated, onDocumentUpdated, onDocumentDeleted } = require("firebase-functions/v2/firestore");
const { onRequest, onCall, HttpsError } = require("firebase-functions/v2/https");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const { defineSecret } = require("firebase-functions/params");
const { initializeApp } = require("firebase-admin/app");
const { getAuth } = require("firebase-admin/auth");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");
const { getMessaging } = require("firebase-admin/messaging");
const { getStorage } = require("firebase-admin/storage");
const crypto = require("crypto");
const { z } = require("zod");

initializeApp();

// ── Secrets ────────────────────────────────────────────────────────
const GMAIL_APP_PASSWORD = defineSecret("GMAIL_APP_PASSWORD");
const GMAIL_SENDER_EMAIL = defineSecret("GMAIL_SENDER_EMAIL");

// ── Zod schemas ────────────────────────────────────────────────────
const KakaoAuthSchema = z.object({
  token: z.string().min(10).max(2000),
});

// ── Stats helpers ──────────────────────────────────────────────────
function todayKey() {
  const d = new Date();
  const yyyy = d.getFullYear();
  const mm = String(d.getMonth() + 1).padStart(2, "0");
  const dd = String(d.getDate()).padStart(2, "0");
  return `${yyyy}-${mm}-${dd}`;
}

async function incrementStat(field, delta = 1) {
  const db = getFirestore();
  const totalsRef = db.doc("app_stats/totals");
  const dailyRef = db.doc(`app_stats/daily_${todayKey()}`);
  const inc = FieldValue.increment(delta);
  await Promise.all([
    totalsRef.set({ [field]: inc }, { merge: true }),
    dailyRef.set({ [field]: inc, date: todayKey() }, { merge: true }),
  ]);
}

async function incrementCategoryStat(category) {
  if (!category) return;
  const db = getFirestore();
  const dailyRef = db.doc(`app_stats/daily_${todayKey()}`);
  await dailyRef.set({
    [`cat_${category}`]: FieldValue.increment(1),
    date: todayKey(),
  }, { merge: true });
}

async function incrementHourStat(hour) {
  const db = getFirestore();
  const dailyRef = db.doc(`app_stats/daily_${todayKey()}`);
  await dailyRef.set({
    [`hour_${hour}`]: FieldValue.increment(1),
    date: todayKey(),
  }, { merge: true });
}

async function logError(functionName, error, extra = {}) {
  try {
    await getFirestore().collection("function_logs").add({
      function: functionName,
      error: error.message || String(error),
      code: error.code || "",
      stack: (error.stack || "").substring(0, 1000),
      ...extra,
      createdAt: new Date(),
    });
  } catch (_) {}
}

exports.kakaoCustomAuth = onRequest(async (req, res) => {
  if (req.method !== "POST") { res.status(405).send("Method Not Allowed"); return; }

  // zod 입력 검증
  const parsed = KakaoAuthSchema.safeParse(req.body);
  if (!parsed.success) {
    res.status(400).json({ error: "Invalid request body", details: parsed.error.flatten() });
    return;
  }
  const { token } = parsed.data;

  try {
    const kakaoRes = await fetch("https://kapi.kakao.com/v2/user/me", {
      headers: { Authorization: `Bearer ${token}` },
    });
    if (!kakaoRes.ok) { res.status(401).json({ error: "Invalid kakao token" }); return; }

    const kakaoUser = await kakaoRes.json();
    const uid = `kakao:${kakaoUser.id}`;
    const email = kakaoUser.kakao_account?.email || null;
    const name = kakaoUser.kakao_account?.profile?.nickname || "카카오 사용자";
    const profileImage = kakaoUser.kakao_account?.profile?.profile_image_url || null;

    let firebaseUser;
    try {
      firebaseUser = await getAuth().getUser(uid);
    } catch {
      firebaseUser = await getAuth().createUser({
        uid,
        displayName: name,
        ...(email && { email }),
        ...(profileImage && { photoURL: profileImage }),
      });
    }

    // 카카오 프로필 사진이 있고 Firestore에 아직 없으면 저장
    if (profileImage) {
      const userDoc = await getFirestore().doc(`users/${uid}`).get();
      if (userDoc.exists && !userDoc.data().profilePhotoUrl) {
        await getFirestore().doc(`users/${uid}`).update({ profilePhotoUrl: profileImage });
      }
    }

    const customToken = await getAuth().createCustomToken(uid);
    res.json({ firebaseToken: customToken });
  } catch (error) {
    await logError("kakaoCustomAuth", error);
    res.status(500).json({ error: error.message });
  }
});

async function sendPush(token, title, body, data = {}) {
  if (!token) return;
  try {
    await getMessaging().send({
      token,
      notification: { title: title.substring(0, 100), body: body.substring(0, 200) },
      data,
      android: { notification: { channelId: "board_channel" } },
    });
  } catch (error) {
    if (
      error.code === "messaging/registration-token-not-registered" ||
      error.code === "messaging/invalid-registration-token"
    ) {
      const uid = data._targetUid;
      if (uid) {
        await getFirestore().doc(`users/${uid}`).update({ fcmToken: null }).catch(() => {});
      }
    } else {
      await logError("sendPush", error, { title, _targetUid: data._targetUid });
    }
  }
}

async function sendPushToAdmins(title, body, excludeUid) {
  const admins = await getFirestore().collection("users")
    .where("role", "in", ["admin", "manager"]).get();
  const promises = [];
  for (const doc of admins.docs) {
    if (doc.id === excludeUid) continue;
    const token = doc.data().fcmToken;
    if (token) promises.push(sendPush(token, title, body, { type: "account", _targetUid: doc.id }));
  }
  await Promise.all(promises);
}

exports.onCommentCreated = onDocumentCreated(
  "posts/{postId}/comments/{commentId}",
  async (event) => {
    try {
    const comment = event.data.data();
    const postId = event.params.postId;

    if (!comment.authorUid || !comment.content) return;

    const commentAuthorDoc = await getFirestore().doc(`users/${comment.authorUid}`).get();
    if (!commentAuthorDoc.exists) return;
    const commentAuthor = commentAuthorDoc.data();
    if (!commentAuthor.approved && commentAuthor.role === "user") return;

    const postDoc = await getFirestore().doc(`posts/${postId}`).get();
    if (!postDoc.exists) return;

    const post = postDoc.data();
    const postAuthorUid = post.authorUid;
    const name = (comment.authorName || "익명").substring(0, 50);
    const content = (comment.content || "").substring(0, 100);
    const notifiedUids = new Set();

    // 글 작성자에게 알림
    if (comment.authorUid !== postAuthorUid) {
      const userDoc = await getFirestore().doc(`users/${postAuthorUid}`).get();
      if (userDoc.exists) {
        const userData = userDoc.data();
        if (userData.notiComment !== false) {
          await sendPush(userData.fcmToken, post.title || "", `${name}: ${content}`, {
            type: "comment", postId, _targetUid: postAuthorUid,
          });
        }
        notifiedUids.add(postAuthorUid);
      }
    }

    // 멘션된 사용자들에게 푸시 알림
    if (Array.isArray(comment.mentions)) {
      for (const mentionedUid of comment.mentions) {
        if (mentionedUid === comment.authorUid || notifiedUids.has(mentionedUid)) continue;
        const userDoc = await getFirestore().doc(`users/${mentionedUid}`).get();
        if (!userDoc.exists) continue;
        const userData = userDoc.data();
        if (userData.notiMention === false) continue;
        await sendPush(userData.fcmToken, "멘션 알림", `${name}님이 회원님을 언급했습니다: ${content}`, {
          type: "comment", postId, _targetUid: mentionedUid,
        });
        notifiedUids.add(mentionedUid);
      }
    }

    // 대댓글: 부모 댓글 작성자에게도 알림
    if (comment.parentId) {
      const parentDoc = await getFirestore().doc(`posts/${postId}/comments/${comment.parentId}`).get();
      if (parentDoc.exists) {
        const parentAuthorUid = parentDoc.data().authorUid;
        if (parentAuthorUid && parentAuthorUid !== comment.authorUid && !notifiedUids.has(parentAuthorUid)) {
          const parentUserDoc = await getFirestore().doc(`users/${parentAuthorUid}`).get();
          if (parentUserDoc.exists) {
            const parentUserData = parentUserDoc.data();
            if (parentUserData.notiReply !== false) {
              await sendPush(parentUserData.fcmToken, "답글 알림", `${name}: ${content}`, {
                type: "comment", postId, _targetUid: parentAuthorUid,
              });
            }
          }
        }
      }
    }
  } catch (e) { await logError("onCommentCreated", e, { postId: event.params.postId }); }
  }
);

exports.onPostCreated = onDocumentCreated("posts/{postId}", async (event) => {
  const post = event.data.data();
  const postId = event.params.postId;

  // 통계 카운터 갱신
  try {
    const hour = post.createdAt ? new Date(post.createdAt.seconds * 1000).getHours() : new Date().getHours();
    await Promise.all([
      incrementStat("posts"),
      incrementCategoryStat(post.category),
      incrementHourStat(hour),
    ]);
  } catch (e) { await logError("onPostCreated.stats", e, { postId }); }

  if (!post.authorUid || !post.title) return;

  const authorDoc = await getFirestore().doc(`users/${post.authorUid}`).get();
  if (!authorDoc.exists) return;
  const author = authorDoc.data();
  if (!author.approved && author.role === "user") return;

  const category = (post.category || "").substring(0, 20);
  const title = `[${category}] ${(post.title || "").substring(0, 80)}`;
  const body = (post.content || "").length > 50
    ? (post.content || "").substring(0, 50) + "..."
    : (post.content || "");
  const payload = {
    notification: { title, body },
    data: { type: "new_post", postId },
    android: { notification: { channelId: "board_channel" } },
  };

  try {
    if (post.isPinned) {
      // 공지글 → 전체 구독자
      await getMessaging().send({ ...payload, topic: "board_new_post" });
    } else if (category) {
      // 일반글 → 카테고리 구독자만
      const topicName = `board_${category}`;
      await getMessaging().send({ ...payload, topic: topicName });
    }
  } catch (error) { await logError("onPostCreated", error, { postId }); }
});

// 인기글 알림: 좋아요 10개 도달 시 1회 발송
const POPULAR_THRESHOLD = 10;
exports.onPostLikeUpdated = onDocumentUpdated("posts/{postId}", async (event) => {
  try {
    const before = event.data.before.data();
    const after = event.data.after.data();
    const postId = event.params.postId;

    const beforeLikes = before.likeCount || 0;
    const afterLikes = after.likeCount || 0;

    // threshold를 이번 업데이트에서 처음 넘었을 때만
    if (beforeLikes < POPULAR_THRESHOLD && afterLikes >= POPULAR_THRESHOLD) {
      const title = `🔥 인기글: ${(after.title || "").substring(0, 60)}`;
      const body = `좋아요 ${afterLikes}개 달성!`;
      await getMessaging().send({
        topic: "board_popular",
        notification: { title, body },
        data: { type: "new_post", postId },
        android: { notification: { channelId: "board_channel" } },
      });
    }
  } catch (e) { await logError("onPostLikeUpdated", e, { postId: event.params.postId }); }
});

exports.onUserCreated = onDocumentCreated("users/{userId}", async (event) => {
  try {
    await incrementStat("users");
  } catch (e) { await logError("onUserCreated.stats", e, { userId: event.params.userId }); }
  try {
    const user = event.data.data();
    const name = user.name || "새 사용자";
    await sendPushToAdmins("가입 요청", `${name}님이 가입을 요청했습니다.`, event.params.userId);
  } catch (e) { await logError("onUserCreated", e, { userId: event.params.userId }); }
});

exports.onUserUpdated = onDocumentUpdated("users/{userId}", async (event) => {
  try {
  const before = event.data.before.data();
  const after = event.data.after.data();
  const userId = event.params.userId;

  // role 변경 시 Firebase Auth Custom Claims 동기화
  // 클라이언트는 다음 ID 토큰 갱신 시 새 role을 받음 (forceRefresh)
  if (before.role !== after.role) {
    try {
      await getAuth().setCustomUserClaims(userId, {
        role: after.role || "user",
        approved: after.approved === true,
      });
    } catch (e) {
      await logError("onUserUpdated.setCustomClaims", e, { userId });
    }
  } else if (before.approved !== after.approved) {
    try {
      await getAuth().setCustomUserClaims(userId, {
        role: after.role || "user",
        approved: after.approved === true,
      });
    } catch (e) {
      await logError("onUserUpdated.setCustomClaims", e, { userId });
    }
  }

  if (after.notiAccount === false) return;

  if (!before.approved && after.approved) {
    const token = after.fcmToken;
    await sendPush(token, "가입 승인", "가입이 승인되었습니다. 앱의 모든 기능을 사용할 수 있습니다.", {
      type: "account", _targetUid: userId,
    });
  }

  if (!before.suspendedUntil && after.suspendedUntil) {
    const token = after.fcmToken;
    await sendPush(token, "계정 정지", "관리자에 의해 계정이 정지되었습니다.", {
      type: "account", _targetUid: userId,
    });
  }

  if (before.suspendedUntil && !after.suspendedUntil) {
    const token = after.fcmToken;
    await sendPush(token, "정지 해제", "계정 정지가 해제되었습니다. 앱을 정상적으로 이용할 수 있습니다.", {
      type: "account", _targetUid: userId,
    });
  }

  if (before.role !== after.role) {
    const token = after.fcmToken;
    const roleNames = { admin: "Admin", manager: "매니저", user: "일반 사용자" };
    await sendPush(token, "권한 변경", `${roleNames[after.role] || after.role}(으)로 변경되었습니다.`, {
      type: "account", _targetUid: userId,
    });
  }
  } catch (e) { await logError("onUserUpdated", e, { userId: event.params.userId }); }
});

exports.onUserDeleted = onDocumentDeleted("users/{userId}", async (event) => {
  try { await incrementStat("users", -1); } catch (_) {}

  const user = event.data.data();
  const token = user.fcmToken;
  const userId = event.params.userId;

  // 푸시 알림
  if (token && !user.approved) {
    await sendPush(token, "가입 거절", "가입이 거절되었습니다.", {
      type: "account", _targetUid: userId,
    });
  } else if (token && user.approved) {
    await sendPush(token, "계정 삭제", "관리자에 의해 계정이 삭제되었습니다.", {
      type: "account", _targetUid: userId,
    });
  }

  // Firebase Auth 계정 삭제
  try {
    await getAuth().deleteUser(userId);
  } catch (e) { await logError("onUserDeleted.deleteAuth", e, { userId }); }

  // 하위 컬렉션 삭제 (subjects, notifications)
  const db = getFirestore();
  const subcollections = ["subjects", "notifications"];
  for (const sub of subcollections) {
    const snap = await db.collection(`users/${userId}/${sub}`).get();
    const batch = db.batch();
    snap.docs.forEach((doc) => batch.delete(doc.ref));
    if (snap.docs.length > 0) await batch.commit();
  }
});

exports.onChatMessageCreated = onDocumentCreated(
  "chats/{chatId}/messages/{messageId}",
  async (event) => {
    try {
    const message = event.data.data();
    const chatId = event.params.chatId;
    // 사진 메시지는 content가 비어있을 수 있음 → imageUrl 있으면 통과
    if (!message.senderUid) return;
    if (!message.content && !message.imageUrl) return;
    const chatDoc = await getFirestore().doc(`chats/${chatId}`).get();
    if (!chatDoc.exists) return;
    const chat = chatDoc.data();
    const recipientUid = (chat.participants || []).find((uid) => uid !== message.senderUid);
    if (!recipientUid) return;
    const recipientDoc = await getFirestore().doc(`users/${recipientUid}`).get();
    if (!recipientDoc.exists) return;
    const recipientData = recipientDoc.data();
    if (recipientData.notiChat === false) return;
    const body = message.imageUrl
      ? "[사진]"
      : (message.content || "").substring(0, 100);
    await sendPush(recipientData.fcmToken, message.senderName || "알 수 없음",
      body,
      { type: "chat", chatId, _targetUid: recipientUid });
    } catch (e) { await logError("onChatMessageCreated", e, { chatId: event.params.chatId }); }
  }
);

// 신고 rate limit: 5분 내 3건 초과 시 새 신고 자동 삭제 + 로그
exports.onReportCreated = onDocumentCreated("reports/{reportId}", async (event) => {
  try { await incrementStat("reports"); } catch (_) {}
  try {
    const report = event.data.data();
    const reporterUid = report.reporterUid;
    if (!reporterUid) return;

    const db = getFirestore();
    const cutoff = new Date(Date.now() - 5 * 60 * 1000);
    const recent = await db.collection("reports")
      .where("reporterUid", "==", reporterUid)
      .where("createdAt", ">=", cutoff)
      .get();

    if (recent.size > 3) {
      await event.data.ref.delete();
      await logError("onReportCreated.rateLimit", new Error("Report rate limit exceeded"), {
        reporterUid,
        recentCount: recent.size,
      });
    }
  } catch (e) {
    await logError("onReportCreated", e, { reportId: event.params.reportId });
  }
});

// 매시간 정지 만료된 유저 확인 → suspendedUntil 삭제 → onUserUpdated 트리거 → 정지 해제 알림
exports.checkSuspensionExpiry = onSchedule("every 1 hours", async () => {
  const now = new Date();
  const snap = await getFirestore().collection("users")
    .where("suspendedUntil", "<=", now).get();

  for (const doc of snap.docs) {
    await doc.ref.update({ suspendedUntil: null });
  }
});

// 매일 03:00 KST: 4년 지난 비공지 게시글 + 하위 댓글 + Storage 이미지 삭제
// 게시글 OG 태그 동적 렌더링
exports.postOgRenderer = onRequest(async (req, res) => {
  try {
    const pathMatch = req.path.match(/\/post\/([^/]+)/);
    const postId = pathMatch ? pathMatch[1] : null;

    let title = "한솔고등학교 앱";
    let description = "세종시 한솔고등학교 통합 학교 플랫폼";
    let imageUrl = "";

    if (postId) {
      const doc = await getFirestore().collection("posts").doc(postId).get();
      if (doc.exists) {
        const data = doc.data();
        title = data.title || title;
        const content = data.content || "";
        description = content.length > 100 ? content.substring(0, 100) + "..." : content;
        if (Array.isArray(data.imageUrls) && data.imageUrls.length > 0) {
          imageUrl = data.imageUrls[0];
        }
      }
    }

    const url = `https://hansol-high-school-46fc9.web.app/post/${postId || ""}`;
    const ogTags = `
    <meta property="og:type" content="article">
    <meta property="og:title" content="${title.replace(/"/g, "&quot;")}">
    <meta property="og:description" content="${description.replace(/"/g, "&quot;")}">
    <meta property="og:url" content="${url}">
    <meta property="og:site_name" content="한솔고등학교">
    ${imageUrl ? `<meta property="og:image" content="${imageUrl}">` : ""}
    <meta name="twitter:card" content="${imageUrl ? "summary_large_image" : "summary"}">
    <meta name="twitter:title" content="${title.replace(/"/g, "&quot;")}">
    <meta name="twitter:description" content="${description.replace(/"/g, "&quot;")}">`;

    // 기존 landing page HTML을 읽어서 OG 태그 삽입
    const fs = require("fs");
    const path = require("path");
    let html;
    const localPath = path.join(__dirname, "..", "hosting", "public", "post", "index.html");
    if (fs.existsSync(localPath)) {
      html = fs.readFileSync(localPath, "utf8");
    } else {
      // fallback: 최소 HTML
      html = `<!DOCTYPE html><html><head><meta charset="UTF-8"><title>${title}</title></head><body><p>앱에서 열어주세요</p></body></html>`;
    }

    html = html.replace("</head>", ogTags + "\n</head>");
    html = html.replace(/<title>[^<]*<\/title>/, `<title>${title.replace(/</g, "&lt;")} - 한솔고등학교</title>`);

    res.set("Cache-Control", "public, max-age=300, s-maxage=600");
    res.status(200).send(html);
  } catch (error) {
    await logError("postOgRenderer", error);
    res.status(500).send("Internal Server Error");
  }
});

// 통계 backfill: 기존 데이터로 app_stats를 초기 구축 (1회성)
exports.backfillStats = onRequest(async (req, res) => {
  if (req.method !== "POST") { res.status(405).send("Method Not Allowed"); return; }
  if (req.get("x-admin-secret") !== process.env.BACKFILL_SECRET) {
    res.status(403).json({ error: "Forbidden" }); return;
  }
  try {
    const db = getFirestore();
    const [usersSnap, postsSnap, reportsSnap] = await Promise.all([
      db.collection("users").get(),
      db.collection("posts").get(),
      db.collection("reports").get(),
    ]);

    // totals
    await db.doc("app_stats/totals").set({
      users: usersSnap.size,
      posts: postsSnap.size,
      reports: reportsSnap.size,
    });

    // daily (30 days)
    const dailyMap = {};
    const thirtyDaysAgo = new Date();
    thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);

    for (const doc of postsSnap.docs) {
      const data = doc.data();
      const ts = data.createdAt;
      if (!ts) continue;
      const dt = ts.toDate ? ts.toDate() : new Date(ts);
      if (dt < thirtyDaysAgo) continue;
      const key = `${dt.getFullYear()}-${String(dt.getMonth() + 1).padStart(2, "0")}-${String(dt.getDate()).padStart(2, "0")}`;
      if (!dailyMap[key]) dailyMap[key] = { posts: 0, date: key };
      dailyMap[key].posts++;
      if (data.category) {
        dailyMap[key][`cat_${data.category}`] = (dailyMap[key][`cat_${data.category}`] || 0) + 1;
      }
      const hour = dt.getHours();
      dailyMap[key][`hour_${hour}`] = (dailyMap[key][`hour_${hour}`] || 0) + 1;
    }

    for (const doc of usersSnap.docs) {
      const data = doc.data();
      const ts = data.createdAt;
      if (!ts) continue;
      const dt = ts.toDate ? ts.toDate() : new Date(ts);
      if (dt < thirtyDaysAgo) continue;
      const key = `${dt.getFullYear()}-${String(dt.getMonth() + 1).padStart(2, "0")}-${String(dt.getDate()).padStart(2, "0")}`;
      if (!dailyMap[key]) dailyMap[key] = { date: key };
      dailyMap[key].users = (dailyMap[key].users || 0) + 1;
    }

    for (const doc of reportsSnap.docs) {
      const data = doc.data();
      const ts = data.createdAt;
      if (!ts) continue;
      const dt = ts.toDate ? ts.toDate() : new Date(ts);
      if (dt < thirtyDaysAgo) continue;
      const key = `${dt.getFullYear()}-${String(dt.getMonth() + 1).padStart(2, "0")}-${String(dt.getDate()).padStart(2, "0")}`;
      if (!dailyMap[key]) dailyMap[key] = { date: key };
      dailyMap[key].reports = (dailyMap[key].reports || 0) + 1;
    }

    const batch = db.batch();
    for (const [key, data] of Object.entries(dailyMap)) {
      batch.set(db.doc(`app_stats/daily_${key}`), data);
    }
    await batch.commit();

    res.json({ totals: { users: usersSnap.size, posts: postsSnap.size, reports: reportsSnap.size }, dailyDocs: Object.keys(dailyMap).length });
  } catch (error) {
    await logError("backfillStats", error);
    res.status(500).json({ error: error.message });
  }
});

exports.cleanupOldPosts = onSchedule("every day 18:00", async () => {
  const db = getFirestore();
  const { getStorage } = require("firebase-admin/storage");
  const cutoff = new Date(Date.now() - 4 * 365.25 * 24 * 60 * 60 * 1000);

  const snap = await db.collection("posts")
    .where("createdAt", "<=", cutoff)
    .limit(200)
    .get();

  let deleted = 0;
  for (const postDoc of snap.docs) {
    const data = postDoc.data();
    if (data.isPinned === true) continue;

    // 하위 댓글 삭제
    const comments = await db.collection(`posts/${postDoc.id}/comments`).get();
    const batch = db.batch();
    comments.docs.forEach((c) => batch.delete(c.ref));
    if (comments.docs.length > 0) await batch.commit();

    // Storage 이미지 삭제
    if (Array.isArray(data.imageUrls) && data.imageUrls.length > 0) {
      try {
        const bucket = getStorage().bucket();
        await bucket.deleteFiles({ prefix: `posts/${postDoc.id}/` });
      } catch (_) {}
    }

    await postDoc.ref.delete();
    deleted++;
  }

  if (deleted > 0) {
    try {
      await getFirestore().doc("app_stats/totals").set(
        { posts: FieldValue.increment(-deleted) },
        { merge: true }
      );
    } catch (_) {}
    await getFirestore().collection("function_logs").add({
      function: "cleanupOldPosts",
      deleted,
      skippedPinned: snap.size - deleted,
      createdAt: new Date(),
    });
  }
});

// ═══════════════════════════════════════════════════════════════════
// PIPA 대응: OTP / 탈퇴 / 데이터 이전 / 신고 큐 / 누진정지 / 진급 / 교사 초대
// ═══════════════════════════════════════════════════════════════════

const SCHOOL_EMAIL_DOMAINS = ["edu.sje.go.kr", "sjhansol.sjeduhs.kr"];
function isSchoolEmail(email) {
  if (typeof email !== "string") return false;
  const at = email.indexOf("@");
  if (at < 0) return false;
  const domain = email.slice(at + 1).toLowerCase();
  return SCHOOL_EMAIL_DOMAINS.includes(domain);
}

function sha256(input) {
  return crypto.createHash("sha256").update(input).digest("hex");
}

function generate6DigitCode() {
  return String(crypto.randomInt(0, 1000000)).padStart(6, "0");
}

async function getMailer() {
  const nodemailer = require("nodemailer");
  return nodemailer.createTransport({
    service: "gmail",
    auth: {
      user: GMAIL_SENDER_EMAIL.value(),
      pass: GMAIL_APP_PASSWORD.value(),
    },
  });
}

// ── OTP: 학교 이메일 인증 ─────────────────────────────────────────
const SendOTPSchema = z.object({
  email: z.string().email().max(120),
});

exports.sendSchoolEmailOTP = onCall(
  { secrets: [GMAIL_APP_PASSWORD, GMAIL_SENDER_EMAIL] },
  async (request) => {
    if (!request.auth) throw new HttpsError("unauthenticated", "로그인이 필요합니다");
    const uid = request.auth.uid;

    const parsed = SendOTPSchema.safeParse(request.data);
    if (!parsed.success) throw new HttpsError("invalid-argument", "이메일 형식 오류");
    const email = parsed.data.email.toLowerCase().trim();

    if (!isSchoolEmail(email)) {
      throw new HttpsError("invalid-argument", "학교 이메일 도메인이 아닙니다");
    }

    const db = getFirestore();
    const otpRef = db.doc(`otp_codes/${uid}`);
    const now = Date.now();

    const existing = await otpRef.get();
    if (existing.exists) {
      const data = existing.data();
      if (data.lastSentAt && now - data.lastSentAt.toMillis() < 120 * 1000) {
        throw new HttpsError("resource-exhausted", "120초 후에 다시 시도해주세요");
      }
      const todayKey = new Date().toISOString().slice(0, 10);
      if (data.dailyKey === todayKey && (data.dailyCount || 0) >= 5) {
        throw new HttpsError("resource-exhausted", "오늘 발송 한도(5회)를 초과했습니다");
      }
    }

    const code = generate6DigitCode();
    const codeHash = sha256(code);
    const expiresAt = new Date(now + 30 * 60 * 1000);
    const todayKey = new Date().toISOString().slice(0, 10);
    const prevDaily = existing.exists && existing.data().dailyKey === todayKey
      ? (existing.data().dailyCount || 0) : 0;

    await otpRef.set({
      uid,
      email,
      codeHash,
      attempts: 0,
      expiresAt,
      lastSentAt: new Date(now),
      dailyKey: todayKey,
      dailyCount: prevDaily + 1,
    });

    try {
      const mailer = await getMailer();
      await mailer.sendMail({
        from: `"한솔고 앱" <${GMAIL_SENDER_EMAIL.value()}>`,
        to: email,
        subject: "[한솔고 앱] 학교 이메일 인증 코드",
        text: `인증 코드: ${code}\n\n이 코드는 30분간 유효합니다.\n본인이 요청하지 않았다면 이 메일을 무시해주세요.`,
        html: `<p>인증 코드: <strong style="font-size:20px">${code}</strong></p><p>이 코드는 <strong>30분</strong>간 유효합니다.</p><p style="color:#888;font-size:12px">본인이 요청하지 않았다면 이 메일을 무시해주세요.</p>`,
      });
    } catch (error) {
      await logError("sendSchoolEmailOTP", error, { uid, email });
      throw new HttpsError("internal", "이메일 발송에 실패했습니다");
    }

    return { ok: true, expiresInSec: 1800 };
  }
);

const VerifyOTPSchema = z.object({
  code: z.string().regex(/^\d{6}$/),
});

exports.verifySchoolEmailOTP = onCall(async (request) => {
  if (!request.auth) throw new HttpsError("unauthenticated", "로그인이 필요합니다");
  const uid = request.auth.uid;

  const parsed = VerifyOTPSchema.safeParse(request.data);
  if (!parsed.success) throw new HttpsError("invalid-argument", "6자리 숫자 코드 필요");

  const db = getFirestore();
  const otpRef = db.doc(`otp_codes/${uid}`);
  const snap = await otpRef.get();
  if (!snap.exists) throw new HttpsError("not-found", "OTP가 존재하지 않습니다");
  const data = snap.data();

  if (data.expiresAt && data.expiresAt.toMillis() < Date.now()) {
    await otpRef.delete();
    throw new HttpsError("deadline-exceeded", "코드가 만료되었습니다");
  }
  if ((data.attempts || 0) >= 5) {
    await otpRef.delete();
    throw new HttpsError("resource-exhausted", "시도 한도 초과");
  }

  const inputHash = sha256(parsed.data.code);
  if (inputHash !== data.codeHash) {
    await otpRef.update({ attempts: FieldValue.increment(1) });
    throw new HttpsError("invalid-argument", "코드가 일치하지 않습니다");
  }

  await db.doc(`users/${uid}`).set({
    schoolEmail: data.email,
    verificationStatus: "verified",
    verifiedAt: FieldValue.serverTimestamp(),
    verifiedVia: "otp",
    approved: true,
    approvedAt: FieldValue.serverTimestamp(),
    approvedVia: "otp",
  }, { merge: true });
  await otpRef.delete();

  return { ok: true };
});

// ── 탈퇴 / 30일 후 파기 ──────────────────────────────────────────
exports.requestAccountDeletion = onCall(async (request) => {
  if (!request.auth) throw new HttpsError("unauthenticated", "로그인이 필요합니다");
  const uid = request.auth.uid;
  const db = getFirestore();
  const userRef = db.doc(`users/${uid}`);
  const userSnap = await userRef.get();
  if (!userSnap.exists) throw new HttpsError("not-found", "사용자 없음");
  const user = userSnap.data();

  if (user.suspendedUntil && user.suspendedUntil.toMillis() > Date.now()) {
    throw new HttpsError("failed-precondition", "정지 중에는 탈퇴할 수 없습니다");
  }

  const scheduled = new Date(Date.now() + 30 * 24 * 60 * 60 * 1000);
  await userRef.update({
    withdrawnAt: FieldValue.serverTimestamp(),
    withdrawalScheduledAt: scheduled,
    deactivatedAt: FieldValue.serverTimestamp(),
    isAnonymized: true,
  });

  return { ok: true, scheduledAt: scheduled.toISOString() };
});

exports.purgeDeactivatedAccounts = onSchedule("every day 04:00", async () => {
  const db = getFirestore();
  const now = new Date();
  const snap = await db.collection("users")
    .where("withdrawalScheduledAt", "<=", now)
    .limit(100).get();

  let purged = 0;
  for (const doc of snap.docs) {
    const uid = doc.id;
    try {
      await getAuth().deleteUser(uid).catch(() => {});

      const subcols = ["subjects", "notifications", "blocks"];
      for (const sub of subcols) {
        const colSnap = await db.collection(`users/${uid}/${sub}`).get();
        const batch = db.batch();
        colSnap.docs.forEach(d => batch.delete(d.ref));
        if (colSnap.size > 0) await batch.commit();
      }

      const studentId = doc.data().studentId;
      if (studentId) {
        await db.doc(`studentIds/${studentId}`).delete().catch(() => {});
      }

      try {
        const bucket = getStorage().bucket();
        await bucket.deleteFiles({ prefix: `users/${uid}/` });
      } catch (_) {}

      await doc.ref.delete();
      purged++;
    } catch (e) {
      await logError("purgeDeactivatedAccounts", e, { uid });
    }
  }

  if (purged > 0) {
    await db.collection("function_logs").add({
      function: "purgeDeactivatedAccounts",
      purged,
      createdAt: new Date(),
    });
  }
});

// ── 데이터 이전권 (PIPA 제35조의2) ───────────────────────────────
exports.createDataExport = onCall(
  { memory: "512MiB", timeoutSeconds: 300, secrets: [GMAIL_APP_PASSWORD, GMAIL_SENDER_EMAIL] },
  async (request) => {
    if (!request.auth) throw new HttpsError("unauthenticated", "로그인이 필요합니다");
    const uid = request.auth.uid;
    const db = getFirestore();

    const recent = await db.collection("data_requests")
      .where("uid", "==", uid)
      .where("type", "==", "export")
      .where("createdAt", ">=", new Date(Date.now() - 30 * 24 * 60 * 60 * 1000))
      .limit(1).get();
    if (!recent.empty) {
      throw new HttpsError("resource-exhausted", "30일 1회 제한");
    }

    const reqRef = await db.collection("data_requests").add({
      uid,
      type: "export",
      status: "processing",
      createdAt: FieldValue.serverTimestamp(),
    });

    try {
      const userDoc = await db.doc(`users/${uid}`).get();
      const userData = userDoc.exists ? userDoc.data() : {};

      const [posts, comments, reportsBy, appeals] = await Promise.all([
        db.collection("posts").where("authorUid", "==", uid).get(),
        db.collectionGroup("comments").where("authorUid", "==", uid).get(),
        db.collection("reports").where("reporterUid", "==", uid).get(),
        db.collection("appeals").where("uid", "==", uid).get(),
      ]);

      const exportData = {
        profile: userData,
        posts: posts.docs.map(d => ({ id: d.id, ...d.data() })),
        comments: comments.docs.map(d => ({ id: d.id, ...d.data() })),
        reportsByMe: reportsBy.docs.map(d => ({ id: d.id, ...d.data() })),
        appeals: appeals.docs.map(d => ({ id: d.id, ...d.data() })),
        exportedAt: new Date().toISOString(),
      };

      const archiver = require("archiver");
      const { Readable } = require("stream");
      const bucket = getStorage().bucket();
      const filePath = `exports/${uid}/${reqRef.id}.zip`;
      const file = bucket.file(filePath);
      const writeStream = file.createWriteStream({ contentType: "application/zip" });

      const zip = archiver("zip", { zlib: { level: 9 } });
      zip.pipe(writeStream);
      zip.append(JSON.stringify(exportData, null, 2), { name: "data.json" });
      zip.append(buildExportReadme(userData), { name: "README.txt" });
      await zip.finalize();
      await new Promise((resolve, reject) => {
        writeStream.on("finish", resolve);
        writeStream.on("error", reject);
      });

      const expiresAt = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000);
      const [signedUrl] = await file.getSignedUrl({
        action: "read",
        expires: expiresAt,
      });

      await reqRef.update({
        status: "completed",
        downloadUrl: signedUrl,
        filePath,
        expiresAt,
        completedAt: FieldValue.serverTimestamp(),
      });

      const email = userData.email || userData.schoolEmail;
      if (email) {
        try {
          const mailer = await getMailer();
          await mailer.sendMail({
            from: `"한솔고 앱" <${GMAIL_SENDER_EMAIL.value()}>`,
            to: email,
            subject: "[한솔고 앱] 데이터 다운로드 준비 완료",
            text: `요청하신 데이터 ZIP이 준비되었습니다.\n\n다운로드: ${signedUrl}\n\n링크는 7일간 유효합니다.`,
            html: `<p>요청하신 데이터 ZIP이 준비되었습니다.</p><p><a href="${signedUrl}">다운로드</a></p><p style="color:#888;font-size:12px">링크는 7일간 유효합니다.</p>`,
          });
        } catch (mailErr) {
          await logError("createDataExport.mail", mailErr, { uid, requestId: reqRef.id });
        }
      }

      return { ok: true, requestId: reqRef.id };
    } catch (error) {
      await reqRef.update({ status: "rejected", note: String(error.message || error) }).catch(() => {});
      await logError("createDataExport", error, { uid });
      throw new HttpsError("internal", "내보내기 실패");
    }
  }
);

function buildExportReadme(profile) {
  return `한솔고 앱 데이터 내보내기
${"=".repeat(40)}

이 ZIP에는 다음이 포함되어 있습니다:
- data.json: 모든 데이터 (개발자용)

발급일: ${new Date().toISOString()}
사용자: ${profile.name || ""} (${profile.email || profile.schoolEmail || ""})

근거: 개인정보보호법 제35조의2 (개인정보 이전 요구권)
`;
}

exports.purgeExpiredExports = onSchedule("every day 05:00", async () => {
  const db = getFirestore();
  const snap = await db.collection("data_requests")
    .where("type", "==", "export")
    .where("expiresAt", "<=", new Date())
    .where("status", "==", "completed")
    .limit(200).get();

  const bucket = getStorage().bucket();
  let removed = 0;
  for (const doc of snap.docs) {
    const filePath = doc.data().filePath;
    if (filePath) {
      try { await bucket.file(filePath).delete(); } catch (_) {}
    }
    await doc.ref.update({ status: "expired", downloadUrl: null });
    removed++;
  }
  if (removed > 0) {
    await db.collection("function_logs").add({
      function: "purgeExpiredExports",
      removed,
      createdAt: new Date(),
    });
  }
});

// ── 신고 큐 (5명 임계 + 가중치) ──────────────────────────────────
const REPORT_THRESHOLD = 5;
exports.aggregateReports = onDocumentCreated("reports/{reportId}", async (event) => {
  try {
    const report = event.data.data();
    const targetType = report.targetType;
    const targetId = report.targetId;
    const reporterUid = report.reporterUid;
    if (!targetType || !targetId || !reporterUid) return;

    const db = getFirestore();
    const queueRef = db.doc(`reports_queue/${targetType}_${targetId}`);

    const reporterDoc = await db.doc(`users/${reporterUid}`).get();
    const isVerified = reporterDoc.exists &&
      (reporterDoc.data().verificationStatus || "verified") === "verified";
    const weight = isVerified ? 1.0 : 0.5;
    const deviceId = report.deviceId || null;

    await db.runTransaction(async (tx) => {
      const snap = await tx.get(queueRef);
      const reporters = snap.exists ? (snap.data().reporters || []) : [];
      const seenDevices = snap.exists ? (snap.data().seenDevices || []) : [];

      if (reporters.includes(reporterUid)) return;
      if (deviceId && seenDevices.includes(deviceId)) return;

      const newReporters = [...reporters, reporterUid];
      const newDevices = deviceId ? [...seenDevices, deviceId] : seenDevices;
      const totalWeight = (snap.exists ? (snap.data().totalWeight || 0) : 0) + weight;

      tx.set(queueRef, {
        targetType,
        targetId,
        reporters: newReporters,
        seenDevices: newDevices,
        totalWeight,
        reportCount: newReporters.length,
        lastReportedAt: FieldValue.serverTimestamp(),
        createdAt: snap.exists ? snap.data().createdAt : FieldValue.serverTimestamp(),
        flagged: totalWeight >= REPORT_THRESHOLD,
      }, { merge: true });
    });
  } catch (e) {
    await logError("aggregateReports", e, { reportId: event.params.reportId });
  }
});

// ── 누진 정지 + 자동 해제 ─────────────────────────────────────────
const SUSPENSION_DAYS = [7, 14, 21, 30, -1]; // -1 = 영구

exports.applyProgressiveSuspension = onCall(async (request) => {
  if (!request.auth) throw new HttpsError("unauthenticated", "로그인이 필요합니다");
  const adminUid = request.auth.uid;
  const db = getFirestore();
  const adminDoc = await db.doc(`users/${adminUid}`).get();
  if (!adminDoc.exists) throw new HttpsError("permission-denied", "권한 없음");
  const role = adminDoc.data().role;
  if (!["admin", "manager"].includes(role)) {
    throw new HttpsError("permission-denied", "admin/manager만 가능");
  }

  const Schema = z.object({
    targetUid: z.string().min(1),
    reason: z.string().min(1).max(200),
  });
  const parsed = Schema.safeParse(request.data);
  if (!parsed.success) throw new HttpsError("invalid-argument", "입력 오류");

  const { targetUid, reason } = parsed.data;
  const userRef = db.doc(`users/${targetUid}`);
  const userSnap = await userRef.get();
  if (!userSnap.exists) throw new HttpsError("not-found", "사용자 없음");

  const current = userSnap.data().suspensionCount || 0;
  const next = current + 1;
  const idx = Math.min(next - 1, SUSPENSION_DAYS.length - 1);
  const days = SUSPENSION_DAYS[idx];
  const suspendedUntil = days < 0 ? null : new Date(Date.now() + days * 24 * 60 * 60 * 1000);

  await userRef.update({
    suspensionCount: next,
    suspendedUntil: days < 0 ? new Date("9999-12-31") : suspendedUntil,
    suspendReason: reason,
    suspendedAt: FieldValue.serverTimestamp(),
    suspendedBy: adminUid,
  });

  await db.collection("admin_logs").add({
    action: "suspend",
    targetUid,
    reason,
    suspensionCount: next,
    days,
    actorUid: adminUid,
    createdAt: FieldValue.serverTimestamp(),
  });

  return { ok: true, count: next, days };
});

// ── 학년 진급 (3월 1일 00:00 KST) ────────────────────────────────
exports.promoteGradesAnnually = onSchedule(
  { schedule: "0 0 1 3 *", timeZone: "Asia/Seoul" },
  async () => {
    const db = getFirestore();
    const snap = await db.collection("users")
      .where("userType", "==", "student").get();

    let promoted = 0, graduated = 0;
    for (const doc of snap.docs) {
      const data = doc.data();
      const grade = data.grade || 0;
      try {
        if (grade === 3) {
          await doc.ref.update({
            userType: "graduate",
            graduationYear: new Date().getFullYear(),
            grade: 0,
            classNum: 0,
            studentId: "",
          });
          graduated++;
        } else if (grade === 1 || grade === 2) {
          await doc.ref.update({ grade: grade + 1 });
          promoted++;
        }
      } catch (e) {
        await logError("promoteGradesAnnually", e, { uid: doc.id });
      }
    }

    await db.collection("function_logs").add({
      function: "promoteGradesAnnually",
      promoted,
      graduated,
      createdAt: new Date(),
    });
  }
);

// ── 교사 초대링크 ─────────────────────────────────────────────────
exports.redeemTeacherInvite = onCall(async (request) => {
  if (!request.auth) throw new HttpsError("unauthenticated", "로그인이 필요합니다");
  const uid = request.auth.uid;
  const Schema = z.object({ token: z.string().min(8).max(128) });
  const parsed = Schema.safeParse(request.data);
  if (!parsed.success) throw new HttpsError("invalid-argument", "토큰 필요");

  const db = getFirestore();
  const inviteRef = db.doc(`teacher_invites/${parsed.data.token}`);

  const result = await db.runTransaction(async (tx) => {
    const snap = await tx.get(inviteRef);
    if (!snap.exists) throw new HttpsError("not-found", "유효하지 않은 초대");
    const data = snap.data();
    if (data.expiresAt && data.expiresAt.toMillis() < Date.now()) {
      throw new HttpsError("deadline-exceeded", "만료된 초대");
    }
    const usedCount = data.usedCount || 0;
    if (usedCount >= (data.maxUses || 1)) {
      throw new HttpsError("resource-exhausted", "사용 횟수 초과");
    }

    tx.update(inviteRef, {
      usedCount: FieldValue.increment(1),
      usedBy: FieldValue.arrayUnion(uid),
      lastUsedAt: FieldValue.serverTimestamp(),
    });

    tx.set(db.doc(`users/${uid}`), {
      userType: "teacher",
      verificationStatus: "verified",
      verifiedAt: FieldValue.serverTimestamp(),
      verifiedVia: "teacher_invite",
      teacherInviteToken: parsed.data.token,
    }, { merge: true });

    return { ok: true };
  });

  return result;
});
