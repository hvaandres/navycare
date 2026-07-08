// circle.ts
// navycare — Cloud Functions
//
// Circle membership management and Auth lifecycle hooks.

import * as functions from "firebase-functions/v2";
import * as admin      from "firebase-admin";
import { writeAuditLog } from "./security";

// MARK: - removeCaregiver

export const removeCaregiver = functions.https.onCall(
  { region: "us-central1", enforceAppCheck: true },
  async (request) => {
    const uid = request.auth?.uid;
    if (!uid) throw new functions.https.HttpsError("unauthenticated", "Sign in required.");

    const { caregiverUID } = request.data as { caregiverUID: string };
    if (!caregiverUID) {
      throw new functions.https.HttpsError("invalid-argument", "caregiverUID is required.");
    }

    const db        = admin.firestore();
    const circleRef = db.collection("circles").doc(uid);
    const circleDoc = await circleRef.get();

    if (!circleDoc.exists || circleDoc.data()?.lovedOneUID !== uid) {
      throw new functions.https.HttpsError(
        "permission-denied",
        "Only the Loved One can remove caregivers."
      );
    }

    const memberRef  = circleRef.collection("members").doc(caregiverUID);
    const memberSnap = await memberRef.get();

    if (!memberSnap.exists) {
      return { success: true }; // Already removed — idempotent
    }

    await db.runTransaction(async (tx) => {
      tx.delete(memberRef);
      tx.update(circleRef, {
        memberCount: admin.firestore.FieldValue.increment(-1),
        updatedAt:   admin.firestore.FieldValue.serverTimestamp(),
      });
    });

    // Notify removed caregiver via FCM
    try {
      const caregiverDoc  = await db.collection("users").doc(caregiverUID).get();
      const fcmTokens: string[] = caregiverDoc.data()?.fcmTokens ?? [];
      const lovedOneDoc   = await db.collection("users").doc(uid).get();
      const lovedOneName  = lovedOneDoc.data()?.firstName ?? "Your Loved One";

      if (fcmTokens.length > 0) {
        await admin.messaging().sendEachForMulticast({
          tokens: fcmTokens,
          notification: {
            title: "Removed from Circle",
            body:  `You have been removed from ${lovedOneName}'s care circle.`,
          },
          data: { type: "caregiver_removed", circleId: uid },
        });
      }
    } catch (fcmError) {
      functions.logger.warn("FCM push failed on removeCaregiver", { fcmError });
    }

    await writeAuditLog(db, "caregiver_removed", "member", caregiverUID, uid);

    return { success: true };
  }
);

// MARK: - onUserCreated

/**
 * Fires when a new Firebase Auth user is created.
 * Creates the Firestore /users/{uid} and /circles/{uid} documents.
 */
export const onUserCreated = functions.identity.beforeUserCreated(
  { region: "us-central1" },
  async (event) => {
    const user = event.data;
    if (!user.uid) return;

    const db = admin.firestore();

    const batch = db.batch();

    // User document — default role is lovedOne
    batch.set(db.collection("users").doc(user.uid), {
      uid:          user.uid,
      firstName:    user.displayName?.split(" ")[0] ?? "",
      lastName:     user.displayName?.split(" ").slice(1).join(" ") ?? "",
      email:        user.email ?? "",
      phoneNumber:  user.phoneNumber ?? "",
      role:         "lovedOne",
      fcmTokens:    [],
      createdAt:    admin.firestore.FieldValue.serverTimestamp(),
      updatedAt:    admin.firestore.FieldValue.serverTimestamp(),
    });

    // Circle document — circleId equals lovedOneUID
    batch.set(db.collection("circles").doc(user.uid), {
      lovedOneUID:  user.uid,
      memberCount:  0,
      createdAt:    admin.firestore.FieldValue.serverTimestamp(),
      updatedAt:    admin.firestore.FieldValue.serverTimestamp(),
    });

    await batch.commit();

    await writeAuditLog(db, "user_created", "user", user.uid, user.uid);
  }
);
