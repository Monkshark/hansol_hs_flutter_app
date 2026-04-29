const { initializeApp, cert } = require("firebase-admin/app");
const { getAuth } = require("firebase-admin/auth");
const { getFirestore } = require("firebase-admin/firestore");
const path = require("path");

const serviceAccount = require(path.join(__dirname, "service-account.json"));
initializeApp({ credential: cert(serviceAccount) });

const db = getFirestore();
const auth = getAuth();

async function main() {
  const snap = await db.collection("users").get();
  console.log(`총 ${snap.size}명의 사용자 처리 시작...`);

  let updated = 0;
  let failed = 0;
  const failures = [];

  for (const doc of snap.docs) {
    const data = doc.data();
    const claims = {
      role: data.role || "user",
      approved: data.approved === true,
    };
    try {
      await auth.setCustomUserClaims(doc.id, claims);
      updated++;
      if (updated % 50 === 0) console.log(`  ${updated}/${snap.size} 완료...`);
    } catch (e) {
      failed++;
      failures.push({ uid: doc.id, error: e.message });
    }
  }

  console.log(`\n완료: 성공 ${updated}, 실패 ${failed}, 전체 ${snap.size}`);
  if (failures.length > 0) {
    console.log("\n실패 상세:");
    failures.slice(0, 20).forEach((f) => console.log(`  ${f.uid}: ${f.error}`));
    if (failures.length > 20) console.log(`  ...외 ${failures.length - 20}건`);
  }
}

main().then(() => process.exit(0)).catch((e) => {
  console.error("스크립트 실패:", e);
  process.exit(1);
});
