//
//  LaunchScreen.swift
//  Campusmealsv2
//
//  Created by sarp akar on 02/10/2025.
//

import SwiftUI

struct LaunchScreen: View {
    @State private var showButton: Bool = false
    @State private var showText: Bool = false
    @Binding var isActive: Bool

    var body: some View {
        ZStack {
            // White background
            Color.white
                .edgesIgnoringSafeArea(.all)

            VStack(spacing: 0) {
                Spacer()

                // Logo (stays in same position throughout)
                Image("logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200, height: 200)

                Spacer()

                // Bottom content with staggered animation
                VStack(spacing: 16) {
                    // Get Started Button - slides up with bounce
                    Button(action: {}) {
                        Text("Get Started")
                            .font(.custom("Helvetica-Bold", size: 18))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color.black)
                            .cornerRadius(28)
                    }
                    .padding(.horizontal, 40)
                    .opacity(showButton ? 1 : 0)
                    .scaleEffect(showButton ? 1 : 0.9)
                    .offset(y: showButton ? 0 : 30)

                    // Text - fades in slightly after button
                    Text("Ready to start your journey? Get started")
                        .font(.custom("HelveticaNeue", size: 14))
                        .foregroundColor(.gray)
                        .opacity(showText ? 1 : 0)
                        .offset(y: showText ? 0 : 20)
                }
                .padding(.bottom, 50)
            }
        }
        .onAppear {
            print("🚀 LaunchScreen appeared")

            // Show button with spring animation (Gen Z bouncy effect)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.7, blendDuration: 0)) {
                    showButton = true
                }
            }

            // Show text slightly after button
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                withAnimation(.easeOut(duration: 0.5)) {
                    showText = true
                }
            }

            // Transition to actual onboarding
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                print("🚀 Transitioning to onboarding")
                isActive = false
            }
        }
    }
}

#Preview {
    LaunchScreen(isActive: .constant(false))
}
