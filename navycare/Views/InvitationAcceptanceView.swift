// InvitationAcceptanceView.swift
// navycare — Views
//
// Handles the complete invitation acceptance flow triggered by a deep link.
//
// State machine:
//   validating  → Calls validateInvitationToken to confirm the token is valid
//   details     → Shows invitation summary and Accept / Decline buttons
//   phoneVerify → Presents PhoneVerificationView (phone not yet verified)
//   accepting   → Calls acceptInvitation Cloud Function
//   success     → Joined the circle
//   error       → Invalid / expired / already accepted

import SwiftUI
import FirebaseAuth
import Observation

// MARK: - View Model

@Observable
@MainActor
final class InvitationAcceptanceViewModel {

    // MARK: State

    enum Phase {
        case validating
        case details(phoneLast4: String?)
        case phoneVerify
        case accepting
        case success(circleId: String)
        case error(String)
    }

    var phase: Phase = .validating
    var requiresPhoneVerification: Bool = false

    private let token:   String
    private let cf:      CloudFunctionCaller

    init(token: String, cf: CloudFunctionCaller = .shared) {
        self.token = token
        self.cf    = cf
    }

    // MARK: - Actions

    func validate() async {
        phase = .validating
        do {
            let response: ValidateTokenResponse = try await cf.callPublic(
                "validateInvitationToken",
                data: ValidateTokenRequest(token: token)
            )

            if response.valid {
                phase = .details(phoneLast4: response.receiverPhoneLast4)
            } else {
                phase = .error(friendlyError(for: response.status))
            }
        } catch {
            phase = .error(error.localizedDescription)
        }
    }

    func accept() async {
        // Check if phone is already verified on the current Firebase Auth account
        let phoneVerified = Auth.auth().currentUser?.phoneNumber != nil
        if !phoneVerified {
            phase = .phoneVerify
            return
        }
        await performAccept()
    }

    func phoneVerificationCompleted() async {
        await performAccept()
    }

    func decline() {
        // Dismiss — no server call needed for decline from link
        phase = .error("You declined the invitation.")
    }

    // MARK: - Private

    private func performAccept() async {
        phase = .accepting
        do {
            let response: AcceptInvitationResponse = try await cf.call(
                "acceptInvitation",
                data: AcceptInvitationRequest(token: token)
            )
            phase = .success(circleId: response.circleId)
        } catch let cfError as CloudFunctionError {
            phase = .error(cfError.localizedDescription ?? "Something went wrong.")
        } catch {
            phase = .error(error.localizedDescription)
        }
    }

    private func friendlyError(for status: String) -> String {
        switch status {
        case "expired":         return "This invitation has expired. Ask the sender to resend it."
        case "accepted":        return "This invitation has already been accepted."
        case "declined":        return "This invitation was declined."
        case "not_found":       return "This invitation link is invalid or has been revoked."
        default:                return "Unable to process this invitation. Please try again."
        }
    }
}

// MARK: - View

/// Full-screen sheet presented when the app is opened via an invitation deep link.
struct InvitationAcceptanceView: View {

    let token:      String
    let onDismiss:  () -> Void

    @State private var viewModel: InvitationAcceptanceViewModel

    init(token: String, onDismiss: @escaping () -> Void) {
        self.token     = token
        self.onDismiss = onDismiss
        _viewModel = State(initialValue: InvitationAcceptanceViewModel(token: token))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()
                contentForPhase
            }
            .navigationTitle("Care Circle Invitation")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { onDismiss() }
                        .foregroundStyle(.secondary)
                }
            }
        }
        .task { await viewModel.validate() }
        .interactiveDismissDisabled(isProcessing)
    }

    // MARK: - Phase Views

    @ViewBuilder
    private var contentForPhase: some View {
        switch viewModel.phase {

        case .validating:
            validatingView

        case .details(let phoneLast4):
            detailsView(phoneLast4: phoneLast4)

        case .phoneVerify:
            PhoneVerificationView {
                Task { await viewModel.phoneVerificationCompleted() }
            }

        case .accepting:
            acceptingView

        case .success(let circleId):
            successView(circleId: circleId)

        case .error(let message):
            errorView(message: message)
        }
    }

    // MARK: - Sub-Views

    private var validatingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.4)
            Text("Validating invitation…")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private func detailsView(phoneLast4: String?) -> some View {
        ScrollView {
            VStack(spacing: 28) {
                // Header
                VStack(spacing: 12) {
                    Image(systemName: "person.3.fill")
                        .font(.system(size: 56))
                        .foregroundStyle(.tint)
                        .symbolRenderingMode(.hierarchical)

                    Text("You've been invited")
                        .font(.title2.weight(.bold))

                    Text("Someone has added you to their care circle on Navy Care.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }
                .padding(.top, 12)

                // Phone confirmation
                if let last4 = phoneLast4 {
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundStyle(.green)
                        Text("Invitation sent to number ending in \(last4)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(.white.opacity(0.15), lineWidth: 0.5))
                }

                // What you get
                infoCard(
                    icon: "heart.fill",
                    title: "Care access",
                    body: "You'll be able to view and support your loved one's care information."
                )

                infoCard(
                    icon: "lock.shield.fill",
                    title: "Private & secure",
                    body: "Your data stays local. Only what's needed is shared across the circle."
                )

                // Actions
                VStack(spacing: 12) {
                    Button {
                        Task { await viewModel.accept() }
                    } label: {
                        Text("Join the Circle")
                            .font(.body.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 15)
                            .background(Color.accentColor, in: RoundedRectangle(cornerRadius: 14))
                            .foregroundStyle(.white)
                    }

                    Button(role: .cancel) {
                        viewModel.decline()
                        onDismiss()
                    } label: {
                        Text("Decline")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(20)
        }
    }

    private var acceptingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.4)
            Text("Joining the circle…")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private func successView(circleId: String) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 72))
                .foregroundStyle(.green)
                .symbolRenderingMode(.hierarchical)

            Text("You're in the Circle!")
                .font(.title2.weight(.bold))

            Text("You now have access to your loved one's care information.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            Button("Get Started") { onDismiss() }
                .font(.body.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .background(Color.accentColor, in: RoundedRectangle(cornerRadius: 14))
                .foregroundStyle(.white)
                .padding(.horizontal, 24)
                .padding(.top, 8)
        }
    }

    private func errorView(message: String) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 64))
                .foregroundStyle(.orange)
                .symbolRenderingMode(.hierarchical)

            Text("Couldn't process invitation")
                .font(.title3.weight(.bold))

            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            Button("Dismiss") { onDismiss() }
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.tint)
                .padding(.top, 4)
        }
    }

    private func infoCard(icon: String, title: String, body: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.tint)
                .symbolRenderingMode(.hierarchical)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.subheadline.weight(.semibold))
                Text(body).font(.subheadline).foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(.white.opacity(0.12), lineWidth: 0.5))
    }

    // MARK: - Helpers

    private var isProcessing: Bool {
        switch viewModel.phase {
        case .validating, .accepting: return true
        default: return false
        }
    }
}

// MARK: - Preview

#Preview {
    InvitationAcceptanceView(token: "preview-token-abc123", onDismiss: {})
}
