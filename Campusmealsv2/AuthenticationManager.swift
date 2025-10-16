//
//  AuthenticationManager.swift
//  Campusmealsv2
//
//  Created by sarp akar on 02/10/2025.
//

import Foundation
import FirebaseAuth

class AuthenticationManager: ObservableObject {
    @Published var verificationID: String?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var currentUser: User?

    static let shared = AuthenticationManager()

    private init() {
        checkAuthState()
    }

    func checkAuthState() {
        currentUser = Auth.auth().currentUser
    }

    func sendVerificationCode(to phoneNumber: String) async throws {
        await MainActor.run { isLoading = true; errorMessage = nil }

        do {
            let verificationID = try await PhoneAuthProvider.provider()
                .verifyPhoneNumber(phoneNumber, uiDelegate: nil)

            await MainActor.run {
                self.verificationID = verificationID
                self.isLoading = false
            }

            UserDefaults.standard.set(verificationID, forKey: "authVerificationID")
            print("✅ Verification code sent to \(phoneNumber)")

        } catch {
            await MainActor.run {
                self.isLoading = false
                self.errorMessage = error.localizedDescription
            }
            print("❌ Error sending code: \(error.localizedDescription)")
            throw error
        }
    }

    func verifyCode(_ code: String) async throws {
        await MainActor.run { isLoading = true; errorMessage = nil }

        guard let verificationID = await MainActor.run(body: { verificationID }) ?? UserDefaults.standard.string(forKey: "authVerificationID") else {
            let error = NSError(domain: "AuthError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Verification ID not found"])
            await MainActor.run {
                self.errorMessage = "Verification ID not found. Please request a new code."
                self.isLoading = false
            }
            throw error
        }

        do {
            let credential = PhoneAuthProvider.provider().credential(
                withVerificationID: verificationID,
                verificationCode: code
            )

            let authResult = try await Auth.auth().signIn(with: credential)

            await MainActor.run {
                self.currentUser = authResult.user
                self.isLoading = false
            }

            print("✅ User signed in successfully: \(authResult.user.phoneNumber ?? "Unknown")")

        } catch {
            await MainActor.run {
                self.isLoading = false
                self.errorMessage = error.localizedDescription
            }
            print("❌ Error verifying code: \(error.localizedDescription)")
            throw error
        }
    }

    func signOut() throws {
        try Auth.auth().signOut()
        Task { @MainActor in
            currentUser = nil
            verificationID = nil
        }
        UserDefaults.standard.removeObject(forKey: "authVerificationID")
        print("✅ User signed out")
    }
}
