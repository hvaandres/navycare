"use strict";
// invitations.ts
// navycare — Cloud Functions
//
// Invitation lifecycle: create, validate, accept, revoke, scheduled expiry.
// All writes use server-side timestamps. Client timestamps are never trusted.
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
exports.expireInvitations = exports.revokeInvitation = exports.acceptInvitation = exports.validateInvitationToken = exports.createInvitation = void 0;
const functions = __importStar(require("firebase-functions/v2"));
const admin = __importStar(require("firebase-admin"));
const twilio = __importStar(require("twilio"));
const security_1 = require("./security");
const MAX_CAREGIVERS = 5;
const INVITE_TTL_DAYS = 7;
// Lazily initialize Twilio client from environment config
function getTwilioClient() {
    const accountSid = process.env.TWILIO_ACCOUNT_SID ?? "";
    const authToken = process.env.TWILIO_AUTH_TOKEN ?? "";
    return twilio.default(accountSid, authToken);
}
// MARK: - createInvitation
exports.createInvitation = functions.https.onCall({ region: "us-central1", enforceAppCheck: true }, async (request) => {
    const uid = request.auth?.uid;
    if (!uid)
        throw new functions.https.HttpsError("unauthenticated", "Sign in required.");
    const { receiverPhone, receiverName, relationship, permission } = request.data;
    // Input validation
    if (!(0, security_1.isValidE164)(receiverPhone)) {
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
        throw new functions.https.HttpsError("failed-precondition", "Only a Loved One can send invitations.");
    }
    // Check rate limit
    await (0, security_1.checkAndIncrementRateLimit)(db, uid);
    // Check circle capacity
    const circleRef = db.collection("circles").doc(uid);
    const circleDoc = await circleRef.get();
    const memberCount = circleDoc.data()?.memberCount ?? 0;
    if (memberCount >= MAX_CAREGIVERS) {
        throw new functions.https.HttpsError("resource-exhausted", `Circle is full (max ${MAX_CAREGIVERS} caregivers).`);
    }
    // Duplicate check — pending invitation to same phone
    const dupeSnap = await db
        .collection("invitations")
        .where("senderUID", "==", uid)
        .where("receiverPhone", "==", receiverPhone)
        .where("status", "==", "pending")
        .limit(1)
        .get();
    if (!dupeSnap.empty) {
        throw new functions.https.HttpsError("already-exists", "A pending invitation already exists for this contact.");
    }
    // Generate token and hash
    const plainToken = (0, security_1.generateToken)();
    const tokenHash = (0, security_1.hashToken)(plainToken);
    const expiresAt = new Date();
    expiresAt.setDate(expiresAt.getDate() + INVITE_TTL_DAYS);
    // Write invitation to Firestore
    const invitationRef = db.collection("invitations").doc();
    await invitationRef.set({
        circleId: uid,
        senderUID: uid,
        receiverPhone,
        receiverName: receiverName.trim(),
        relationship: relationship.trim(),
        permission,
        status: "pending",
        tokenHash,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        expiresAt: admin.firestore.Timestamp.fromDate(expiresAt),
        acceptedAt: null,
        acceptedByUID: null,
    });
    // Send SMS
    // Uses Firebase Hosting URL — no custom domain required.
    // Replace FIREBASE_HOSTING_URL env var with your project's .web.app URL.
    const hostingURL = process.env.FIREBASE_HOSTING_URL ?? "https://navycare-app.web.app";
    const inviteURL = `${hostingURL}/invite/${plainToken}`;
    try {
        await getTwilioClient().messages.create({
            body: `${userDoc.data()?.firstName ?? "Someone"} invited you to join their care circle on Navycare. Tap to accept: ${inviteURL}`,
            from: process.env.TWILIO_PHONE_NUMBER,
            to: receiverPhone,
        });
    }
    catch (smsError) {
        // SMS failure should NOT roll back the invitation — log and continue
        functions.logger.error("SMS send failed", { invitationId: invitationRef.id, smsError });
    }
    await (0, security_1.writeAuditLog)(db, "invitation_sent", "invitation", invitationRef.id, uid, {
        receiverPhone: receiverPhone.slice(-4), // last 4 digits only
        permission,
    });
    return { invitationId: invitationRef.id, expiresAt: expiresAt.toISOString() };
});
// MARK: - validateInvitationToken (pre-auth, no enforceAppCheck)
exports.validateInvitationToken = functions.https.onCall({ region: "us-central1", enforceAppCheck: false }, async (request) => {
    const { token } = request.data;
    if (!token?.trim()) {
        throw new functions.https.HttpsError("invalid-argument", "Token is required.");
    }
    const db = admin.firestore();
    const tokenHash = (0, security_1.hashToken)(token);
    const snap = await db
        .collection("invitations")
        .where("tokenHash", "==", tokenHash)
        .limit(1)
        .get();
    if (snap.empty) {
        return { valid: false, status: "not_found", receiverPhoneLast4: null };
    }
    const data = snap.docs[0].data();
    const phone = data.receiverPhone ?? "";
    return {
        valid: data.status === "pending",
        status: data.status,
        receiverPhoneLast4: phone.slice(-4),
    };
});
// MARK: - acceptInvitation
exports.acceptInvitation = functions.https.onCall({ region: "us-central1", enforceAppCheck: true }, async (request) => {
    const uid = request.auth?.uid;
    if (!uid)
        throw new functions.https.HttpsError("unauthenticated", "Sign in required.");
    const { token } = request.data;
    if (!token?.trim()) {
        throw new functions.https.HttpsError("invalid-argument", "Token is required.");
    }
    const db = admin.firestore();
    const tokenHash = (0, security_1.hashToken)(token);
    // Find invitation by token hash
    const snap = await db
        .collection("invitations")
        .where("tokenHash", "==", tokenHash)
        .limit(1)
        .get();
    if (snap.empty) {
        throw new functions.https.HttpsError("not-found", "Invalid invitation token.");
    }
    const invitationDoc = snap.docs[0];
    const invitationData = invitationDoc.data();
    // Status checks
    if (invitationData.status !== "pending") {
        throw new functions.https.HttpsError("already-exists", `Invitation is ${invitationData.status}.`);
    }
    const expiresAt = invitationData.expiresAt.toDate();
    if (new Date() > expiresAt) {
        throw new functions.https.HttpsError("deadline-exceeded", "Invitation has expired.");
    }
    // Phone number verification — must match Firebase Auth verified phone
    const caregiverAuth = await admin.auth().getUser(uid);
    const verifiedPhone = caregiverAuth.phoneNumber;
    if (!verifiedPhone || verifiedPhone !== invitationData.receiverPhone) {
        throw new functions.https.HttpsError("permission-denied", "Phone number does not match the invitation.");
    }
    const circleId = invitationData.circleId;
    const circleRef = db.collection("circles").doc(circleId);
    // Atomic transaction
    const result = await db.runTransaction(async (tx) => {
        const circleSnap = await tx.get(circleRef);
        const currentCount = circleSnap.data()?.memberCount ?? 0;
        if (currentCount >= MAX_CAREGIVERS) {
            throw new functions.https.HttpsError("resource-exhausted", "Circle is full.");
        }
        // Use uid as membershipId so isActiveMember() security rule works
        const memberRef = circleRef.collection("members").doc(uid);
        const memberSnap = await tx.get(memberRef);
        if (memberSnap.exists) {
            throw new functions.https.HttpsError("already-exists", "Already a member.");
        }
        const membershipId = uid;
        tx.set(memberRef, {
            caregiverUID: uid,
            relationship: invitationData.relationship,
            permission: invitationData.permission,
            joinedAt: admin.firestore.FieldValue.serverTimestamp(),
            invitationId: invitationDoc.id,
        });
        tx.update(circleRef, {
            memberCount: admin.firestore.FieldValue.increment(1),
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        tx.update(invitationDoc.ref, {
            status: "accepted",
            acceptedAt: admin.firestore.FieldValue.serverTimestamp(),
            acceptedByUID: uid,
        });
        // Update caregiver role
        tx.set(db.collection("users").doc(uid), { role: "caregiver" }, { merge: true });
        return { circleId, membershipId };
    });
    // Push notification to Loved One
    try {
        const lovedOneDoc = await db.collection("users").doc(circleId).get();
        const fcmTokens = lovedOneDoc.data()?.fcmTokens ?? [];
        const caregiverName = caregiverAuth.displayName ?? invitationData.receiverName;
        if (fcmTokens.length > 0) {
            await admin.messaging().sendEachForMulticast({
                tokens: fcmTokens,
                notification: {
                    title: "New Circle Member",
                    body: `${caregiverName} joined your care circle.`,
                },
                data: {
                    type: "invitation_accepted",
                    caregiverUID: uid,
                    circleId,
                },
            });
        }
    }
    catch (fcmError) {
        functions.logger.warn("FCM push failed", { fcmError });
    }
    await (0, security_1.writeAuditLog)(db, "invitation_accepted", "invitation", invitationDoc.id, uid, {
        circleId,
    });
    return result;
});
// MARK: - revokeInvitation
exports.revokeInvitation = functions.https.onCall({ region: "us-central1", enforceAppCheck: true }, async (request) => {
    const uid = request.auth?.uid;
    if (!uid)
        throw new functions.https.HttpsError("unauthenticated", "Sign in required.");
    const { invitationId } = request.data;
    const db = admin.firestore();
    const invRef = db.collection("invitations").doc(invitationId);
    const invSnap = await invRef.get();
    if (!invSnap.exists) {
        throw new functions.https.HttpsError("not-found", "Invitation not found.");
    }
    const data = invSnap.data();
    if (data.senderUID !== uid) {
        throw new functions.https.HttpsError("permission-denied", "Not your invitation.");
    }
    if (data.status !== "pending") {
        return { success: true }; // Already resolved — idempotent
    }
    await invRef.update({
        status: "expired",
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    await (0, security_1.writeAuditLog)(db, "invitation_revoked", "invitation", invitationId, uid);
    return { success: true };
});
// MARK: - expireInvitations (scheduled)
exports.expireInvitations = functions.scheduler.onSchedule({ schedule: "every 1 hours", region: "us-central1" }, async () => {
    const db = admin.firestore();
    const now = admin.firestore.Timestamp.now();
    const snap = await db
        .collection("invitations")
        .where("status", "==", "pending")
        .where("expiresAt", "<=", now)
        .limit(500)
        .get();
    if (snap.empty)
        return;
    const batch = db.batch();
    snap.docs.forEach((doc) => {
        batch.update(doc.ref, {
            status: "expired",
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
    });
    await batch.commit();
    functions.logger.info(`Expired ${snap.size} invitations.`);
});
//# sourceMappingURL=invitations.js.map