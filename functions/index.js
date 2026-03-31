const { onDocumentCreated, onDocumentUpdated, onDocumentDeleted } = require("firebase-functions/v2/firestore");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore } = require("firebase-admin/firestore");
const { getMessaging } = require("firebase-admin/messaging");

initializeApp();

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
    const authorUid = post.authorUid;

    if (comment.authorUid === authorUid) return;

    const userDoc = await getFirestore().doc(`users/${authorUid}`).get();
    if (!userDoc.exists) return;

    const fcmToken = userDoc.data().fcmToken;
    const name = (comment.authorName || "익명").substring(0, 50);
    const content = (comment.content || "").substring(0, 100);

    await sendPush(fcmToken, post.title || "", `${name}: ${content}`, {
      type: "comment", postId, _targetUid: authorUid,
    });
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
  } catch (error) {}
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

  if (token && !user.approved) {
    await sendPush(token, "가입 거절", "가입이 거절되었습니다.", {
      type: "account", _targetUid: event.params.userId,
    });
  } else if (token && user.approved) {
    await sendPush(token, "계정 삭제", "관리자에 의해 계정이 삭제되었습니다.", {
      type: "account", _targetUid: event.params.userId,
    });
  }
});
