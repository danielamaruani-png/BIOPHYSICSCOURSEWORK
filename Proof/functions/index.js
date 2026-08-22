const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore } = require("firebase-admin/firestore");
const { getMessaging } = require("firebase-admin/messaging");

initializeApp();

/**
 * Fires when someone posts a proof to a crew's feed, and notifies their
 * *accepted* accountability partners — a partnership no longer unlocks
 * any data access (crew feed visibility is membership-based now), but
 * it's still what the Friends tab uses to decide who gets nudged with
 * "X completed today's proof!" when they post anywhere.
 *
 * Deliberately still the only server-side logic in the app: everything
 * else (streaks, crews, reactions) stays client-side per the read-only
 * rules already in place. This one has to run server-side because it
 * fans out to *other* people's devices, which a client can't do.
 */
exports.notifyPartnersOnProof = onDocumentCreated(
  "crews/{crewId}/feed/{itemId}",
  async (event) => {
    const item = event.data.data();
    if (item.type !== "proof") return;
    const uid = item.authorUid;
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
