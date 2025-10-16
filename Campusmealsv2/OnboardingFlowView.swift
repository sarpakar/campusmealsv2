//
//  OnboardingFlowView.swift
//  Campusmealsv2
//
//  Created by sarp akar on 02/10/2025.
//

import SwiftUI

struct OnboardingFlowView: View {
    @StateObject private var authManager = AuthenticationManager.shared
    @State private var navigationPath = NavigationPath()
    @State private var phoneNumber: String = ""

    var body: some View {
        if authManager.currentUser != nil {
            HomeScreen()
        } else {
            NavigationStack(path: $navigationPath) {
                WelcomeScreen(onGetStarted: {
                    navigationPath.append("phoneInput")
                })
                .navigationDestination(for: String.self) { destination in
                    switch destination {
                    case "phoneInput":
                        PhoneNumberInputScreen(onContinue: { number in
                            phoneNumber = number
                            navigationPath.append("verificationCode")
                        })
                    case "verificationCode":
                        VerificationCodeScreen(phoneNumber: phoneNumber, onVerify: { code in
                            // Authentication is handled in VerificationCodeScreen
                            // authManager.currentUser will update automatically
                        })
                    default:
                        EmptyView()
                    }
                }
                .navigationBarBackButtonHidden(true)
            }
        }
    }
}

#Preview {
    OnboardingFlowView()
}
