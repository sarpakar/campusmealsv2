//
//  PhoneNumberConfirmationScreen.swift
//  Campusmealsv2
//
//  Created by sarp akar on 02/10/2025.
//

import SwiftUI

struct PhoneNumberConfirmationScreen: View {
    @State private var phoneNumber: String = ""
    @FocusState private var isPhoneFieldFocused: Bool

    var onContinue: () -> Void

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
                    Text("Confirm your number")
                        .font(.custom("Helvetica-Bold", size: 28))
                        .foregroundColor(.black)

                    Text("We'll text a code to verify your phone")
                        .font(.custom("HelveticaNeue", size: 16))
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.top, 24)

                // Phone number display
                TextField("Phone Number", text: $phoneNumber)
                    .font(.custom("HelveticaNeue", size: 24))
                    .keyboardType(.phonePad)
                    .foregroundColor(.black)
                    .padding(.horizontal, 20)
                    .padding(.top, 32)
                    .focused($isPhoneFieldFocused)

                // Divider
                Rectangle()
                    .fill(Color.black)
                    .frame(height: 2)
                    .padding(.horizontal, 20)
                    .padding(.top, 12)

                Spacer()

                // Continue button
                Button(action: onContinue) {
                    Text("Send Code")
                        .font(.custom("Helvetica-Bold", size: 18))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.black)
                        .cornerRadius(28)
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 50)
            }
        }
        .onAppear {
            phoneNumber = "+65 8379 4988"
        }
    }
}

#Preview {
    PhoneNumberConfirmationScreen(onContinue: {})
}
