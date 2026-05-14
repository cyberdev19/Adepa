const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");
const axios = require("axios");

initializeApp();
const db = getFirestore();

// ─── Config ────────────────────────────────────────────────────────────────
// Set this in Firebase Functions config:
//   firebase functions:secrets:set PERSPECTIVE_API_KEY
const PERSPECTIVE_API_KEY = process.env.PERSPECTIVE_API_KEY;
const TOXICITY_THRESHOLD = 0.85; // 0-1. Posts above this are auto-deleted.
const REVIEW_THRESHOLD = 0.65;   // Posts between 0.65-0.85 are flagged for review.

// ─── Banned words (server-side backup) ────────────────────────────────────
const BANNED_WORDS = [
  "fuck", "shit", "bitch", "asshole", "cunt", "nigger", "faggot",
  "twea", "kyinkyinga", "kill yourself", "kys", "go die",
];

function containsBannedWords(text) {
  const lower = text.toLowerCase();
  return BANNED_WORDS.some((w) => lower.includes(w));
}

// ─── Perspective API call ──────────────────────────────────────────────────
async function getToxicityScore(text) {
  if (!PERSPECTIVE_API_KEY) {
    console.warn("No Perspective API key set. Skipping toxicity check.");
    return 0;
  }
  try {
    const res = await axios.post(
      `https://commentanalyzer.googleapis.com/v1alpha1/comments:analyze?key=${PERSPECTIVE_API_KEY}`,
      {
        comment: { text },
        languages: ["en"],
        requestedAttributes: {
          TOXICITY: {},
          INSULT: {},
          THREAT: {},
          IDENTITY_ATTACK: {},
        },
      }
    );
    const scores = res.data.attributeScores;
    // Return the highest score across all attributes
    return Math.max(
      scores.TOXICITY?.summaryScore?.value ?? 0,
      scores.INSULT?.summaryScore?.value ?? 0,
      scores.THREAT?.summaryScore?.value ?? 0,
      scores.IDENTITY_ATTACK?.summaryScore?.value ?? 0
    );
  } catch (err) {
    console.error("Perspective API error:", err.message);
    return 0; // Fail open — don't block posts if API is down
  }
}

// ─── Trigger: new post created ─────────────────────────────────────────────
exports.moderatePost = onDocumentCreated("posts/{postId}", async (event) => {
  const snap = event.data;
  const data = snap.data();
  const postId = event.params.postId;
  const text = data?.text ?? "";

  if (!text) return;

  console.log(`Moderating post ${postId}: "${text.substring(0, 60)}..."`);

  // 1. Hard banned words check
  if (containsBannedWords(text)) {
    console.log(`Post ${postId} deleted: banned words`);
    await snap.ref.delete();
    await logModerationAction(postId, "deleted", "banned_words", 1.0);
    return;
  }

  // 2. Perspective API toxicity check
  const score = await getToxicityScore(text);
  console.log(`Post ${postId} toxicity score: ${score}`);

  if (score >= TOXICITY_THRESHOLD) {
    // Auto-delete
    console.log(`Post ${postId} deleted: toxicity ${score}`);
    await snap.ref.delete();
    await logModerationAction(postId, "deleted", "toxicity", score);
  } else if (score >= REVIEW_THRESHOLD) {
    // Flag for human review
    console.log(`Post ${postId} flagged for review: toxicity ${score}`);
    await snap.ref.update({ hidden: true, flaggedScore: score });
    await logModerationAction(postId, "flagged", "toxicity", score);
  }
  // else: post is clean — do nothing
});

// ─── Trigger: new comment created ─────────────────────────────────────────
exports.moderateComment = onDocumentCreated(
  "posts/{postId}/comments/{commentId}",
  async (event) => {
    const snap = event.data;
    const data = snap.data();
    const { postId, commentId } = event.params;
    const text = data?.text ?? "";

    if (!text) return;

    if (containsBannedWords(text)) {
      console.log(`Comment ${commentId} deleted: banned words`);
      await snap.ref.delete();
      // Also decrement comment count
      await db.collection("posts").doc(postId).update({
        commentCount: FieldValue.increment(-1),
      });
      return;
    }

    const score = await getToxicityScore(text);
    if (score >= TOXICITY_THRESHOLD) {
      console.log(`Comment ${commentId} deleted: toxicity ${score}`);
      await snap.ref.delete();
      await db.collection("posts").doc(postId).update({
        commentCount: FieldValue.increment(-1),
      });
    }
  }
);

// ─── Helper: log moderation actions ───────────────────────────────────────
async function logModerationAction(postId, action, reason, score) {
  await db.collection("moderation_log").add({
    postId,
    action,       // "deleted" | "flagged"
    reason,       // "banned_words" | "toxicity"
    score,
    timestamp: FieldValue.serverTimestamp(),
  });
}
