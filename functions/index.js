const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore } = require("firebase-admin/firestore");
const { getMessaging } = require("firebase-admin/messaging");

initializeApp();

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
    if (!fcmToken) return;

    const title = (post.title || "").substring(0, 100);
    const body = `${(comment.authorName || "익명").substring(0, 50)}: ${(comment.content || "").substring(0, 100)}`;

    try {
      await getMessaging().send({
        token: fcmToken,
        notification: { title, body },
        data: { type: "comment", postId },
        android: { notification: { channelId: "board_channel" } },
      });
    } catch (error) {
      if (
        error.code === "messaging/registration-token-not-registered" ||
        error.code === "messaging/invalid-registration-token"
      ) {
        await getFirestore().doc(`users/${authorUid}`).update({ fcmToken: null });
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
  } catch (error) {
    console.error("Topic send error:", error);
  }
});
