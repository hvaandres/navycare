"use strict";
// circle.ts
// navycare — Cloud Functions
//
// Circle membership management and Auth lifecycle hooks.
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
exports.onUserCreated = exports.removeCaregiver = void 0;
const functions = __importStar(require("firebase-functions/v2"));
const admin = __importStar(require("firebase-admin"));
const security_1 = require("./security");
// MARK: - removeCaregiver
exports.removeCaregiver = functions.https.onCall({ region: "us-central1", enforceAppCheck: true }, async (request) => {
    const uid = request.auth?.uid;
    if (!uid)
        throw new functions.https.HttpsError("unauthenticated", "Sign in required.");
    const { caregiverUID } = request.data;
    if (!caregiverUID) {
        throw new functions.https.HttpsError("invalid-argument", "caregiverUID is required.");
    }
    const db = admin.firestore();
    const circleRef = db.collection("circles").doc(uid);
    const circleDoc = await circleRef.get();
    if (!circleDoc.exists || circleDoc.data()?.lovedOneUID !== uid) {
        throw new functions.https.HttpsError("permission-denied", "Only the Loved One can remove caregivers.");
    }
    const memberRef = circleRef.collection("members").doc(caregiverUID);
    const memberSnap = await memberRef.get();
    if (!memberSnap.exists) {
        return { success: true }; // Already removed — idempotent
    }
    await db.runTransaction(async (tx) => {
        tx.delete(memberRef);
        tx.update(circleRef, {
            memberCount: admin.firestore.FieldValue.increment(-1),
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
    });
    // Notify removed caregiver via FCM
    try {
        const caregiverDoc = await db.collection("users").doc(caregiverUID).get();
        const fcmTokens = caregiverDoc.data()?.fcmTokens ?? [];
        const lovedOneDoc = await db.collection("users").doc(uid).get();
        const lovedOneName = lovedOneDoc.data()?.firstName ?? "Your Loved One";
        if (fcmTokens.length > 0) {
            await admin.messaging().sendEachForMulticast({
                tokens: fcmTokens,
                notification: {
                    title: "Removed from Circle",
                    body: `You have been removed from ${lovedOneName}'s care circle.`,
                },
                data: { type: "caregiver_removed", circleId: uid },
            });
        }
    }
    catch (fcmError) {
        functions.logger.warn("FCM push failed on removeCaregiver", { fcmError });
    }
    await (0, security_1.writeAuditLog)(db, "caregiver_removed", "member", caregiverUID, uid);
    return { success: true };
});
// MARK: - onUserCreated
/**
 * Fires when a new Firebase Auth user is created.
 * Creates the Firestore /users/{uid} and /circles/{uid} documents.
 */
exports.onUserCreated = functions.identity.beforeUserCreated({ region: "us-central1" }, async (event) => {
    const user = event.data;
    if (!user.uid)
        return;
    const db = admin.firestore();
    const batch = db.batch();
    // User document — default role is lovedOne
    batch.set(db.collection("users").doc(user.uid), {
        uid: user.uid,
        firstName: user.displayName?.split(" ")[0] ?? "",
        lastName: user.displayName?.split(" ").slice(1).join(" ") ?? "",
        email: user.email ?? "",
        phoneNumber: user.phoneNumber ?? "",
        role: "lovedOne",
        fcmTokens: [],
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    // Circle document — circleId equals lovedOneUID
    batch.set(db.collection("circles").doc(user.uid), {
        lovedOneUID: user.uid,
        memberCount: 0,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    await batch.commit();
    await (0, security_1.writeAuditLog)(db, "user_created", "user", user.uid, user.uid);
});
//# sourceMappingURL=circle.js.map