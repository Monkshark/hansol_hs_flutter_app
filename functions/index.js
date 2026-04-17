const { onDocumentCreated, onDocumentUpdated, onDocumentDeleted } = require("firebase-functions/v2/firestore");
const { onRequest } = require("firebase-functions/v2/https");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const { initializeApp } = require("firebase-admin/app");
const { getAuth } = require("firebase-admin/auth");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");
const { getMessaging } = require("firebase-admin/messaging");
const { z } = require("zod");

initializeApp();

// ── Zod schemas ────────────────────────────────────────────────────
const KakaoAuthSchema = z.object({
  token: z.string().min(10).max(2000),
});

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

// 기존 사용자에게 일괄로 custom claims 적용 (1회성 마이그레이션)
// 호출: POST /backfillCustomClaims  (admin SDK 호출이므로 인증 필요 — 임시 토큰)
exports.backfillCustomClaims = onRequest(async (req, res) => {
  if (req.method !== "POST") { res.status(405).send("Method Not Allowed"); return; }
  // 매우 단순한 secret 헤더 검증 (실배포 전 환경변수로 교체)
  if (req.get("x-admin-secret") !== process.env.BACKFILL_SECRET) {
    res.status(403).json({ error: "Forbidden" });
    return;
  }
  try {
    const snap = await getFirestore().collection("users").get();
    let updated = 0, failed = 0;
    for (const doc of snap.docs) {
      const data = doc.data();
      try {
        await getAuth().setCustomUserClaims(doc.id, {
          role: data.role || "user",
          approved: data.approved === true,
        });
        updated++;
      } catch (_) { failed++; }
    }
    res.json({ updated, failed, total: snap.size });
  } catch (error) {
    await logError("backfillCustomClaims", error);
    res.status(500).json({ error: error.message });
  }
});

// 신고 rate limit: 5분 내 3건 초과 시 새 신고 자동 삭제 + 로그
exports.onReportCreated = onDocumentCreated("reports/{reportId}", async (event) => {
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
    await getFirestore().collection("function_logs").add({
      function: "cleanupOldPosts",
      deleted,
      skippedPinned: snap.size - deleted,
      createdAt: new Date(),
    });
  }
});
