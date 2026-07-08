// PhoneVerificationView.swift
// navycare — Views (Step 7)
//
// Two-step phone verification screen using Firebase Phone Auth.
//
// Flow:
//   1. User enters phone number → verifyPhoneNumber sends OTP via SMS
//   2. User enters 6-digit OTP → credential is linked to their Firebase Auth account
//
// This ensures `user.phoneNumber` on the Firebase Auth user matches the
// invited phone number — required by the `acceptInvitation` Cloud Function.

import SwiftUI
import FirebaseAuth
import Observation

// MARK: - View Model

@Observable
@MainActor
final class PhoneVerificationViewModel {

    // MARK: State
    var phoneNumber:      String = ""
    var otpCode:          String = ""
    var verificationID:   String?
    var step:             Step   = .enterPhone

    var isLoading:        Bool   = false
    var errorMessage:     String?
    var isVerified:       Bool   = false

    enum Step { case enterPhone, enterOTP }

    // MARK: Computed

    var canSendOTP: Bool {
        let digits = phoneNumber.filter(\.isNumber)
        return digits.count >= 10
    }

    var canVerifyOTP: Bool { otpCode.count == 6 }

    var formattedPhone: String {
        // Keep E.164 format for Firebase
        let digits = phoneNumber.filter(\.isNumber)
        return phoneNumber.hasPrefix("+") ? phoneNumber : "+1\(digits)"
    }

    // MARK: Actions

    func sendOTP() async {
        guard canSendOTP else { return }
        isLoading    = true
        errorMessage = nil

        do {
            let id = try await PhoneAuthProvider.provider()
                .verifyPhoneNumber(formattedPhone, uiDelegate: nil)
            verificationID = id
            step = .enterOTP
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func verifyOTP() async {
        guard canVerifyOTP, let verificationID else { return }
        isLoading    = true
        errorMessage = nil

        let credential = PhoneAuthProvider.provider().credential(
            withVerificationID: verificationID,
            verificationCode: otpCode
        )

        do {
            if let currentUser = Auth.auth().currentUser {
                // Link phone to existing account (Google/Apple sign-in)
                try await currentUser.link(with: credential)
            } else {
                // Sign in fresh (shouldn't happen in normal flow)
                try await Auth.auth().signIn(with: credential)
            }
            isVerified = true
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func resendOTP() async {
        step       = .enterPhone
        otpCode    = ""
        verificationID = nil
        await sendOTP()
    }
}

// MARK: - View

/// Phone number verification screen shown to caregivers accepting an invitation.
struct PhoneVerificationView: View {

    let onVerified: () -> Void

    @State private var viewModel = PhoneVerificationViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    headerSection
                    if viewModel.step == .enterPhone {
                        phoneInputSection
                    } else {
                        otpInputSection
                    }
                    if let error = viewModel.errorMessage {
                        errorBanner(error)
                    }
                }
                .padding(24)
            }
            .navigationTitle("Verify Phone")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onChange(of: viewModel.isVerified) { _, verified in
            if verified { onVerified() }
        }
        .interactiveDismissDisabled(viewModel.isLoading)
    }

    // MARK: - Sections

    private var headerSection: some View {
        VStack(spacing: 10) {
            Image(systemName: "phone.badge.checkmark.fill")
                .font(.system(size: 52))
                .foregroundStyle(.tint)
                .symbolRenderingMode(.hierarchical)

            Text(viewModel.step == .enterPhone ? "Verify your phone" : "Enter the code")
                .font(.title2.weight(.bold))

            Text(viewModel.step == .enterPhone
                 ? "We'll send a one-time code to confirm your number."
                 : "Enter the 6-digit code sent to \(viewModel.phoneNumber).")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
        }
    }

    private var phoneInputSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("🇺🇸 +1")
                    .font(.body.weight(.medium))
                    .padding(.leading, 14)

                TextField("(555) 000-0000", text: $viewModel.phoneNumber)
                    .textFieldStyle(.plain)
                    .keyboardType(.phonePad)
                    .textContentType(.telephoneNumber)
                    .padding(.vertical, 14)
                    .padding(.trailing, 14)
            }
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(.white.opacity(0.15), lineWidth: 0.5))

            primaryButton(
                title: viewModel.isLoading ? "Sending…" : "Send Code",
                disabled: !viewModel.canSendOTP || viewModel.isLoading
            ) {
                Task { await viewModel.sendOTP() }
            }
        }
    }

    private var otpInputSection: some View {
        VStack(spacing: 16) {
            TextField("6-digit code", text: $viewModel.otpCode)
                .textFieldStyle(.plain)
                .keyboardType(.numberPad)
                .textContentType(.oneTimeCode)
                .font(.system(size: 28, weight: .semibold, design: .monospaced))
                .multilineTextAlignment(.center)
                .padding(16)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(.white.opacity(0.15), lineWidth: 0.5))
                .onChange(of: viewModel.otpCode) { _, new in
                    // Auto-submit when 6 digits entered
                    if new.count == 6 {
                        Task { await viewModel.verifyOTP() }
                    }
                }

            primaryButton(
                title: viewModel.isLoading ? "Verifying…" : "Verify Code",
                disabled: !viewModel.canVerifyOTP || viewModel.isLoading
            ) {
                Task { await viewModel.verifyOTP() }
            }

            Button("Resend Code") {
                Task { await viewModel.resendOTP() }
            }
            .font(.subheadline)
            .foregroundStyle(.tint)
            .disabled(viewModel.isLoading)
        }
    }

    private func errorBanner(_ message: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.red)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.red)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.red.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(.red.opacity(0.2), lineWidth: 0.5))
    }

    private func primaryButton(
        title:    String,
        disabled: Bool,
        action:   @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Text(title)
                .font(.body.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .background(disabled ? Color.secondary.opacity(0.2) : Color.accentColor,
                            in: RoundedRectangle(cornerRadius: 14))
            .foregroundStyle(disabled ? AnyShapeStyle(.secondary) : AnyShapeStyle(Color.white))
        }
        .disabled(disabled)
        .animation(.easeInOut(duration: 0.2), value: disabled)
    }
}

// MARK: - Preview

#Preview {
    PhoneVerificationView(onVerified: {})
}
