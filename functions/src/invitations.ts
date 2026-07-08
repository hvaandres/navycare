// invitations.ts
// navycare — Cloud Functions
//
// Invitation lifecycle: create, validate, accept, revoke, scheduled expiry.
// All writes use server-side timestamps. Client timestamps are never trusted.

import * as functions from "firebase-functions/v2";
import * as admin      from "firebase-admin";
import {
  generateToken,
  hashToken,
  verifyToken,
  checkAndIncrementRateLimit,
  isValidE164,
  writeAuditLog,
} from "./security";

const MAX_CAREGIVERS  = 5;
const INVITE_TTL_DAYS = 7;
const HOSTING_URL     = process.env.FIREBASE_HOSTING_URL ?? "https://navycare-6cd3e.web.app";

// MARK: - createInvitation

export const createInvitation = functions.https.onCall(
  { region: "us-central1", enforceAppCheck: true },
  async (request) => {
    const uid = request.auth?.uid;
    if (!uid) throw new functions.https.HttpsError("unauthenticated", "Sign in required.");

    const { receiverPhone, receiverName, relationship, permission } = request.data as {
      receiverPhone: string;
      receiverName:  string;
      relationship:  string;
      permission:    string;
    };

    // Input validation
    if (!isValidE164(receiverPhone)) {
      throw new functions.https.HttpsError("invalid-argument", "Invalid phone number format.");
    }
    if (!receiverName?.trim() || !relationship?.trim()) {
      throw new functions.https.HttpsError("invalid-argument", "Name and relationship are required.");
    }
    if (!["admin", "caregiver", "viewer"].includes(permission)) {
      throw new functions.https.HttpsError("invalid-argument", "Invalid permission level.");
    }

    const db = admin.firestore();

    // Verify sender role
    const userDoc = await db.collection("users").doc(uid).get();
    if (!userDoc.exists || userDoc.data()?.role !== "lovedOne") {
      throw new functions.https.HttpsError(
        "failed-precondition",
        "Only a Loved One can send invitations."
      );
    }

    // Check rate limit
    await checkAndIncrementRateLimit(db, uid);

    // Check circle capacity
    const circleRef = db.collection("circles").doc(uid);
    const circleDoc = await circleRef.get();
    const memberCount: number = circleDoc.data()?.memberCount ?? 0;
    if (memberCount >= MAX_CAREGIVERS) {
      throw new functions.https.HttpsError(
        "resource-exhausted",
        `Circle is full (max ${MAX_CAREGIVERS} caregivers).`
      );
    }

    // Duplicate check — pending invitation to same phone
    const dupeSnap = await db
      .collection("invitations")
      .where("senderUID",     "==", uid)
      .where("receiverPhone", "==", receiverPhone)
      .where("status",        "==", "pending")
      .limit(1)
      .get();
    if (!dupeSnap.empty) {
      throw new functions.https.HttpsError(
        "already-exists",
        "A pending invitation already exists for this contact."
      );
    }

    // Generate token and hash
    const plainToken = generateToken();
    const tokenHash  = hashToken(plainToken);

    const expiresAt = new Date();
    expiresAt.setDate(expiresAt.getDate() + INVITE_TTL_DAYS);

    // Write invitation to Firestore
    const invitationRef = db.collection("invitations").doc();
    await invitationRef.set({
      circleId:      uid,
      senderUID:     uid,
      receiverPhone,
      receiverName:  receiverName.trim(),
      relationship:  relationship.trim(),
      permission,
      status:        "pending",
      tokenHash,
      createdAt:     admin.firestore.FieldValue.serverTimestamp(),
      expiresAt:     admin.firestore.Timestamp.fromDate(expiresAt),
      acceptedAt:    null,
      acceptedByUID: null,
    });

    // Build invite URL — returned to the iOS client which presents a share sheet.
    // No SMS service needed; the user chooses how to send (iMessage, WhatsApp, etc.).
    const inviteURL = `${HOSTING_URL}/invite/${plainToken}`;

    await writeAuditLog(db, "invitation_sent", "invitation", invitationRef.id, uid, {
      receiverPhone: receiverPhone.slice(-4), // last 4 digits only
      permission,
    });

    return {
      invitationId: invitationRef.id,
      expiresAt:    expiresAt.toISOString(),
      inviteURL,            // client displays share sheet with this URL
    };
  }
);

// MARK: - validateInvitationToken (pre-auth, no enforceAppCheck)

export const validateInvitationToken = functions.https.onCall(
  { region: "us-central1", enforceAppCheck: false },
  async (request) => {
    const { token } = request.data as { token: string };
    if (!token?.trim()) {
      throw new functions.https.HttpsError("invalid-argument", "Token is required.");
    }

    const db = admin.firestore();
    const tokenHash = hashToken(token);

    const snap = await db
      .collection("invitations")
      .where("tokenHash", "==", tokenHash)
      .limit(1)
      .get();

    if (snap.empty) {
      return { valid: false, status: "not_found", receiverPhoneLast4: null };
    }

    const data = snap.docs[0].data();
    const phone: string = data.receiverPhone ?? "";

    return {
      valid:              data.status === "pending",
      status:             data.status as string,
      receiverPhoneLast4: phone.slice(-4),
    };
  }
);

// MARK: - acceptInvitation

export const acceptInvitation = functions.https.onCall(
  { region: "us-central1", enforceAppCheck: true },
  async (request) => {
    const uid = request.auth?.uid;
    if (!uid) throw new functions.https.HttpsError("unauthenticated", "Sign in required.");

    const { token } = request.data as { token: string };
    if (!token?.trim()) {
      throw new functions.https.HttpsError("invalid-argument", "Token is required.");
    }

    const db = admin.firestore();
    const tokenHash = hashToken(token);

    // Find invitation by token hash
    const snap = await db
      .collection("invitations")
      .where("tokenHash", "==", tokenHash)
      .limit(1)
      .get();

    if (snap.empty) {
      throw new functions.https.HttpsError("not-found", "Invalid invitation token.");
    }

    const invitationDoc  = snap.docs[0];
    const invitationData = invitationDoc.data();

    // Status checks
    if (invitationData.status !== "pending") {
      throw new functions.https.HttpsError(
        "already-exists",
        `Invitation is ${invitationData.status as string}.`
      );
    }

    const expiresAt: Date = (invitationData.expiresAt as admin.firestore.Timestamp).toDate();
    if (new Date() > expiresAt) {
      throw new functions.https.HttpsError("deadline-exceeded", "Invitation has expired.");
    }

    // Phone number verification — must match Firebase Auth verified phone
    const caregiverAuth = await admin.auth().getUser(uid);
    const verifiedPhone = caregiverAuth.phoneNumber;
    if (!verifiedPhone || verifiedPhone !== invitationData.receiverPhone) {
      throw new functions.https.HttpsError(
        "permission-denied",
        "Phone number does not match the invitation."
      );
    }

    const circleId = invitationData.circleId as string;
    const circleRef = db.collection("circles").doc(circleId);

    // Atomic transaction
    const result = await db.runTransaction(async (tx) => {
      const circleSnap = await tx.get(circleRef);
      const currentCount: number = circleSnap.data()?.memberCount ?? 0;

      if (currentCount >= MAX_CAREGIVERS) {
        throw new functions.https.HttpsError(
          "resource-exhausted",
          "Circle is full."
        );
      }

      // Use uid as membershipId so isActiveMember() security rule works
      const memberRef = circleRef.collection("members").doc(uid);
      const memberSnap = await tx.get(memberRef);
      if (memberSnap.exists) {
        throw new functions.https.HttpsError("already-exists", "Already a member.");
      }

      const membershipId = uid;

      tx.set(memberRef, {
        caregiverUID:  uid,
        relationship:  invitationData.relationship,
        permission:    invitationData.permission,
        joinedAt:      admin.firestore.FieldValue.serverTimestamp(),
        invitationId:  invitationDoc.id,
      });

      tx.update(circleRef, {
        memberCount: admin.firestore.FieldValue.increment(1),
        updatedAt:   admin.firestore.FieldValue.serverTimestamp(),
      });

      tx.update(invitationDoc.ref, {
        status:        "accepted",
        acceptedAt:    admin.firestore.FieldValue.serverTimestamp(),
        acceptedByUID: uid,
      });

      // Update caregiver role
      tx.set(db.collection("users").doc(uid), { role: "caregiver" }, { merge: true });

      return { circleId, membershipId };
    });

    // Push notification to Loved One
    try {
      const lovedOneDoc = await db.collection("users").doc(circleId).get();
      const fcmTokens: string[] = lovedOneDoc.data()?.fcmTokens ?? [];
      const caregiverName = caregiverAuth.displayName ?? invitationData.receiverName;

      if (fcmTokens.length > 0) {
        await admin.messaging().sendEachForMulticast({
          tokens: fcmTokens,
          notification: {
            title: "New Circle Member",
            body:  `${caregiverName} joined your care circle.`,
          },
          data: {
            type:        "invitation_accepted",
            caregiverUID: uid,
            circleId,
          },
        });
      }
    } catch (fcmError) {
      functions.logger.warn("FCM push failed", { fcmError });
    }

    await writeAuditLog(db, "invitation_accepted", "invitation", invitationDoc.id, uid, {
      circleId,
    });

    return result;
  }
);

// MARK: - revokeInvitation

export const revokeInvitation = functions.https.onCall(
  { region: "us-central1", enforceAppCheck: true },
  async (request) => {
    const uid = request.auth?.uid;
    if (!uid) throw new functions.https.HttpsError("unauthenticated", "Sign in required.");

    const { invitationId } = request.data as { invitationId: string };
    const db = admin.firestore();

    const invRef  = db.collection("invitations").doc(invitationId);
    const invSnap = await invRef.get();

    if (!invSnap.exists) {
      throw new functions.https.HttpsError("not-found", "Invitation not found.");
    }

    const data = invSnap.data()!;
    if (data.senderUID !== uid) {
      throw new functions.https.HttpsError("permission-denied", "Not your invitation.");
    }
    if (data.status !== "pending") {
      return { success: true }; // Already resolved — idempotent
    }

    await invRef.update({
      status:    "expired",
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    await writeAuditLog(db, "invitation_revoked", "invitation", invitationId, uid);

    return { success: true };
  }
);

// MARK: - expireInvitations (scheduled)

export const expireInvitations = functions.scheduler.onSchedule(
  { schedule: "every 1 hours", region: "us-central1" },
  async () => {
    const db  = admin.firestore();
    const now = admin.firestore.Timestamp.now();

    const snap = await db
      .collection("invitations")
      .where("status",    "==", "pending")
      .where("expiresAt", "<=", now)
      .limit(500)
      .get();

    if (snap.empty) return;

    const batch = db.batch();
    snap.docs.forEach((doc) => {
      batch.update(doc.ref, {
        status:    "expired",
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    });

    await batch.commit();
    functions.logger.info(`Expired ${snap.size} invitations.`);
  }
);
