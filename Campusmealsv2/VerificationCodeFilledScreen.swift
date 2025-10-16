//
//  VerificationCodeFilledScreen.swift
//  Campusmealsv2
//
//  Created by sarp akar on 02/10/2025.
//

import SwiftUI

struct VerificationCodeFilledScreen: View {
    @State private var code: String = ""
    @FocusState private var isCodeFieldFocused: Bool
    let phoneNumber: String = "+65 8379 4988"

    var onVerify: () -> Void

    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header with back button
                HStack {
                    Button(action: {}) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20))
                            .foregroundColor(.black)
                    }
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)

                // Title and subtitle
                VStack(alignment: .leading, spacing: 8) {
                    Text("What's the code?")
                        .font(.custom("Helvetica-Bold", size: 28))
                        .foregroundColor(.black)

                    Text("Enter the code sent to \(phoneNumber)")
                        .font(.custom("HelveticaNeue", size: 16))
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.top, 24)

                // Code input (filled)
                TextField("Enter 6-digit code", text: $code)
                    .font(.custom("HelveticaNeue", size: 32))
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.black)
                    .padding(.horizontal, 20)
                    .padding(.top, 40)
                    .focused($isCodeFieldFocused)
                    .onChange(of: code) { oldValue, newValue in
                        if newValue.count > 6 {
                            code = String(newValue.prefix(6))
                        }
                    }

                // Divider
                Rectangle()
                    .fill(Color.black)
                    .frame(height: 2)
                    .padding(.horizontal, 20)
                    .padding(.top, 12)

                Spacer()

                // Verify button
                Button(action: onVerify) {
                    Text("Verify")
                        .font(.custom("Helvetica-Bold", size: 18))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(code.count == 6 ? Color.black : Color.gray)
                        .cornerRadius(28)
                }
                .disabled(code.count != 6)
                .padding(.horizontal, 40)
                .padding(.bottom, 20)

                // Resend link
                Button(action: {}) {
                    Text("Resend Code")
                        .font(.custom("HelveticaNeue", size: 16))
                        .foregroundColor(.gray)
                }
                .padding(.bottom, 50)
            }
        }
        .onAppear {
            code = "495651"
        }
    }
}

#Preview {
    VerificationCodeFilledScreen(onVerify: {})
}
