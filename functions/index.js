const { onDocumentCreated, onDocumentUpdated, onDocumentDeleted } = require("firebase-functions/v2/firestore");
const { onRequest } = require("firebase-functions/v2/https");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const { initializeApp } = require("firebase-admin/app");
const { getAuth } = require("firebase-admin/auth");
const { getFirestore } = require("firebase-admin/firestore");
const { getMessaging } = require("firebase-admin/messaging");

initializeApp();

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

  const { token } = req.body;
  if (!token) { res.status(400).json({ error: "token required" }); return; }

  try {
    const kakaoRes = await fetch("https://kapi.kakao.com/v2/user/me", {
      headers: { Authorization: `Bearer ${token}` },
    });
    if (!kakaoRes.ok) { res.status(401).json({ error: "Invalid kakao token" }); return; }

    const kakaoUser = await kakaoRes.json();
    const uid = `kakao:${kakaoUser.id}`;
    const email = kakaoUser.kakao_account?.email || null;
    const name = kakaoUser.kakao_account?.profile?.nickname || "카카오 사용자";

    let firebaseUser;
    try {
      firebaseUser = await getAuth().getUser(uid);
    } catch {
      firebaseUser = await getAuth().createUser({
        uid,
        displayName: name,
        ...(email && { email }),
      });
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
  for (const doc of admins.docs) {
    if (doc.id === excludeUid) continue;
    const token = doc.data().fcmToken;
    if (token) await sendPush(token, title, body, { type: "account", _targetUid: doc.id });
  }
}

exports.onCommentCreated = onDocumentCreated(
  "posts/{postId}/comments/{commentId}",
  async (event) => {
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

  const title = `[${(post.category || "").substring(0, 20)}] ${(post.title || "").substring(0, 80)}`;
  const body = (post.content || "").length > 50
    ? (post.content || "").substring(0, 50) + "..."
    : (post.content || "");

  try {
    await getMessaging().send({
      topic: "board_new_post",
      notification: { title, body },
      data: { type: "new_post", postId },
      android: { notification: { channelId: "board_channel" } },
    });
  } catch (error) { await logError("onPostCreated", error, { postId }); }
});

exports.onUserCreated = onDocumentCreated("users/{userId}", async (event) => {
  const user = event.data.data();
  const name = user.name || "새 사용자";

  await sendPushToAdmins("가입 요청", `${name}님이 가입을 요청했습니다.`, event.params.userId);
});

exports.onUserUpdated = onDocumentUpdated("users/{userId}", async (event) => {
  const before = event.data.before.data();
  const after = event.data.after.data();
  const userId = event.params.userId;

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
    const message = event.data.data();
    const chatId = event.params.chatId;
    if (!message.senderUid || !message.content) return;
    const chatDoc = await getFirestore().doc(`chats/${chatId}`).get();
    if (!chatDoc.exists) return;
    const chat = chatDoc.data();
    const recipientUid = (chat.participants || []).find((uid) => uid !== message.senderUid);
    if (!recipientUid) return;
    const recipientDoc = await getFirestore().doc(`users/${recipientUid}`).get();
    if (!recipientDoc.exists) return;
    const recipientData = recipientDoc.data();
    if (recipientData.notiChat === false) return;
    await sendPush(recipientData.fcmToken, message.senderName || "알 수 없음",
      (message.content || "").substring(0, 100),
      { type: "chat", chatId, _targetUid: recipientUid });
  }
);

// 매시간 정지 만료된 유저 확인 → suspendedUntil 삭제 → onUserUpdated 트리거 → 정지 해제 알림
exports.checkSuspensionExpiry = onSchedule("every 1 hours", async () => {
  const now = new Date();
  const snap = await getFirestore().collection("users")
    .where("suspendedUntil", "<=", now).get();

  for (const doc of snap.docs) {
    await doc.ref.update({ suspendedUntil: null });
  }
});
