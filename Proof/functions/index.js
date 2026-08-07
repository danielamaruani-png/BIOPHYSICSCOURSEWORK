const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore } = require("firebase-admin/firestore");
const { getMessaging } = require("firebase-admin/messaging");

initializeApp();

/**
 * Fires when someone posts today's proof, and notifies their
 * *accepted* accountability partners only — plain followers never get
 * pinged, the same boundary firestore.rules already draws around who
 * can see actual proof photos vs. just today's ✅/⭕.
 *
 * Deliberately the only server-side logic in Phase 1: everything else
 * (streaks, resolutions) stays client-side per the read-only rules
 * already in place. This one needs to run server-side because it has
 * to fan out to *other* people's devices, which a client can't do.
 */
exports.notifyPartnersOnProof = onDocumentCreated(
  "users/{uid}/resolutions/{resolutionId}/proofs/{day}",
  async (event) => {
    const { uid } = event.params;
    const db = getFirestore();

    const [profileSnap, asA, asB] = await Promise.all([
      db.collection("users").doc(uid).get(),
      db.collection("partnerRequests")
        .where("uidA", "==", uid)
        .where("status", "==", "accepted")
        .get(),
      db.collection("partnerRequests")
        .where("uidB", "==", uid)
        .where("status", "==", "accepted")
        .get(),
    ]);

    const partnerIds = [...asA.docs, ...asB.docs].map((doc) => {
      const data = doc.data();
      return data.uidA === uid ? data.uidB : data.uidA;
    });
    if (partnerIds.length === 0) return;

    const name = profileSnap.data()?.name ?? "Your partner";

    // 'in' queries cap at 30 — matches the same cap FirestoreService
    // uses client-side for publicProfiles lookups.
    const partnerDocs = await db.collection("users")
      .where("__name__", "in", partnerIds.slice(0, 30))
      .get();

    const tokens = partnerDocs.docs
      .map((doc) => doc.data().pushToken)
      .filter(Boolean);
    if (tokens.length === 0) return;

    await getMessaging().sendEachForMulticast({
      tokens,
      notification: {
        title: `${name} completed today's proof! 🎉`,
        body: "Complete yours to check it out.",
      },
      data: { type: "partner_proof", fromUid: uid },
      apns: { payload: { aps: { sound: "default" } } },
    });
  }
);
