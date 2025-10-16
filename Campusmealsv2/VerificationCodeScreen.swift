//
//  VerificationCodeScreen.swift
//  Campusmealsv2
//
//  Created by sarp akar on 02/10/2025.
//

import SwiftUI

struct VerificationCodeScreen: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var authManager = AuthenticationManager.shared
    @State private var code: String = ""
    @State private var showError = false
    @FocusState private var isCodeFieldFocused: Bool
    let phoneNumber: String

    var onVerify: (String) -> Void

    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header with back button
                HStack {
                    Button(action: {
                        dismiss()
                    }) {
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

                // Code input boxes
                HStack(spacing: 12) {
                    ForEach(0..<6) { index in
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(index < code.count ? Color.black : Color.gray.opacity(0.3), lineWidth: 2)
                                .frame(width: 48, height: 56)

                            if index < code.count {
                                Text(String(code[code.index(code.startIndex, offsetBy: index)]))
                                    .font(.custom("HelveticaNeue-Bold", size: 32))
                                    .foregroundColor(.black)
                            }
                        }
                    }
                }
                .padding(.top, 40)
                .padding(.horizontal, 20)

                // Hidden text field for input
                TextField("", text: $code)
                    .keyboardType(.numberPad)
                    .focused($isCodeFieldFocused)
                    .opacity(0)
                    .frame(height: 1)
                    .onChange(of: code) { oldValue, newValue in
                        // Limit to 6 digits
                        if newValue.count > 6 {
                            code = String(newValue.prefix(6))
                        }
                        // Filter non-numeric characters
                        code = code.filter { $0.isNumber }
                    }

                Spacer()

                // Verify button
                Button(action: {
                    if code.count == 6 {
                        Task {
                            do {
                                try await authManager.verifyCode(code)
                                onVerify(code)
                            } catch {
                                showError = true
                            }
                        }
                    }
                }) {
                    HStack(spacing: 8) {
                        Text("Verify")
                            .font(.custom("Helvetica-Bold", size: 18))
                            .foregroundColor(.white)

                        if authManager.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background((code.count == 6 && !authManager.isLoading) ? Color.black : Color.gray)
                    .cornerRadius(28)
                }
                .disabled(code.count != 6 || authManager.isLoading)
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
            isCodeFieldFocused = true
        }
        .onTapGesture {
            isCodeFieldFocused = true
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(authManager.errorMessage ?? "Invalid verification code. Please try again.")
        }
        .onChange(of: code) { oldValue, newValue in
            // Auto-verify when 6 digits entered
            if newValue.count == 6 && !authManager.isLoading {
                Task {
                    do {
                        try await authManager.verifyCode(newValue)
                        onVerify(newValue)
                    } catch {
                        showError = true
                    }
                }
            }
        }
    }
}

#Preview {
    VerificationCodeScreen(phoneNumber: "+1 234 567 8900", onVerify: { _ in })
}
