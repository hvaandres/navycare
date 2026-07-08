// index.ts
// navycare — Cloud Functions
//
// Entry point. Initializes Firebase Admin and exports all functions.

import * as admin from "firebase-admin";

// Initialize Admin SDK once
admin.initializeApp();

// Re-export all callable functions
export {
  createInvitation,
  validateInvitationToken,
  acceptInvitation,
  revokeInvitation,
  expireInvitations,
} from "./invitations";

export { removeCaregiver, onUserCreated } from "./circle";
