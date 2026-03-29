const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore } = require("firebase-admin/firestore");
const { getMessaging } = require("firebase-admin/messaging");

initializeApp();

// 댓글 생성 시 → 글 작성자에게 푸시 알림
exports.onCommentCreated = onDocumentCreated(
  "posts/{postId}/comments/{commentId}",
  async (event) => {
    const comment = event.data.data();
    const postId = event.params.postId;

    // 글 정보 조회
    const postDoc = await getFirestore().doc(`posts/${postId}`).get();
    if (!postDoc.exists) return;

    const post = postDoc.data();
    const authorUid = post.authorUid;

    // 테스트용: 자기 글에 자기가 댓글 달아도 알림 보냄
    // if (comment.authorUid === authorUid) return;

    // 글 작성자의 FCM 토큰 조회
    const userDoc = await getFirestore().doc(`users/${authorUid}`).get();
    if (!userDoc.exists) return;

    const fcmToken = userDoc.data().fcmToken;
    if (!fcmToken) return;

    // 푸시 알림 전송
    try {
      await getMessaging().send({
        token: fcmToken,
        notification: {
          title: `${post.title}`,
          body: `${comment.authorName}: ${comment.content}`,
        },
        data: {
          type: "comment",
          postId: postId,
        },
        android: {
          notification: {
            channelId: "board_channel",
          },
        },
      });
      console.log(`Push sent to ${authorUid} for comment on ${postId}`);
    } catch (error) {
      console.error("Push send error:", error);
      // 토큰이 유효하지 않으면 삭제
      if (
        error.code === "messaging/registration-token-not-registered" ||
        error.code === "messaging/invalid-registration-token"
      ) {
        await getFirestore().doc(`users/${authorUid}`).update({
          fcmToken: null,
        });
      }
    }
  }
);

// 새 게시글 작성 시 → 토픽으로 전체 알림
exports.onPostCreated = onDocumentCreated("posts/{postId}", async (event) => {
  const post = event.data.data();
  const postId = event.params.postId;

  // 토픽으로 전체 알림
  try {
    await getMessaging().send({
      topic: "board_new_post",
      notification: {
        title: `[${post.category}] ${post.title}`,
        body:
          post.content.length > 50
            ? post.content.substring(0, 50) + "..."
            : post.content,
      },
      data: {
        type: "new_post",
        postId: postId,
      },
      android: {
        notification: {
          channelId: "board_channel",
        },
      },
    });
    console.log(`Topic notification sent for new post ${postId}`);
  } catch (error) {
    console.error("Topic send error:", error);
  }
});
