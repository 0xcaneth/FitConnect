const functions = require("firebase-functions");
const admin = require("firebase-admin");
const { getStorage } = require("firebase-admin/storage");

admin.initializeApp();

exports.deleteExpiredContent = functions.pubsub.schedule("every 1 hours").onRun(async (context) => {
  const db = admin.firestore();
  const storage = getStorage().bucket();
  const now = admin.firestore.Timestamp.now();

  // 🔥 1. Expired Workout Videos
  const expiredVideos = await db.collection("videos")
    .where("expiresAt", "<=", now)
    .get();

  for (const doc of expiredVideos.docs) {
    const data = doc.data();
    const videoURL = data.videoURL;
    const path = extractPathFromURL(videoURL);

    try {
      if (path) await storage.file(path).delete();
      await doc.ref.delete();
      console.log(`✅ Deleted video + Firestore: ${path}`);
    } catch (error) {
      console.error(`❌ Error deleting video: ${path}`, error);
    }
  }

  // 🍽 2. Expired Meal Images
  const expiredMeals = await db.collection("meals")
    .where("expiresAt", "<=", now)
    .get();

  for (const doc of expiredMeals.docs) {
    const data = doc.data();
    const imageURL = data.imageURL;
    const path = extractPathFromURL(imageURL);

    try {
      if (path) await storage.file(path).delete();
      await doc.ref.delete();
      console.log(`✅ Deleted image + Firestore: ${path}`);
    } catch (error) {
      console.error(`❌ Error deleting image: ${path}`, error);
    }
  }

  return null;
});

// 🔍 Yardımcı: URL'den dosya yolu çıkarır
function extractPathFromURL(url) {
  try {
    const decoded = decodeURIComponent(url);
    const match = decoded.match(/(?:app\/|\/o\/)(.+?)\?/);
    return match ? match[1].replace(/%2F/g, "/") : "";
  } catch (err) {
    console.error("❌ Failed to extract path:", url, err);
    return "";
  }
}