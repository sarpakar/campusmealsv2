//
//  PhoneNumberInputScreen.swift
//  Campusmealsv2
//
//  Created by sarp akar on 02/10/2025.
//

import SwiftUI

struct CountryCode {
    let flag: String
    let code: String
    let name: String
}

struct PhoneNumberInputScreen: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var authManager = AuthenticationManager.shared
    @State private var phoneNumber: String = ""
    @State private var selectedCountry = CountryCode(flag: "🇺🇸", code: "+1", name: "United States")
    @State private var showCountryPicker = false
    @State private var showError = false
    @FocusState private var isPhoneFieldFocused: Bool

    let countries = [
        CountryCode(flag: "🇺🇸", code: "+1", name: "United States"),
        CountryCode(flag: "🇬🇧", code: "+44", name: "United Kingdom"),
        CountryCode(flag: "🇸🇬", code: "+65", name: "Singapore"),
        CountryCode(flag: "🇨🇦", code: "+1", name: "Canada"),
        CountryCode(flag: "🇦🇺", code: "+61", name: "Australia"),
        CountryCode(flag: "🇩🇪", code: "+49", name: "Germany"),
        CountryCode(flag: "🇫🇷", code: "+33", name: "France"),
        CountryCode(flag: "🇯🇵", code: "+81", name: "Japan"),
        CountryCode(flag: "🇨🇳", code: "+86", name: "China"),
        CountryCode(flag: "🇮🇳", code: "+91", name: "India")
    ]

    var onContinue: (String) -> Void

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
                    Text("What's your number?")
                        .font(.custom("Helvetica-Bold", size: 28))
                        .foregroundColor(.black)

                    Text("We'll text a code to verify your phone")
                        .font(.custom("HelveticaNeue", size: 16))
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.top, 24)

                // Phone number input with country code
                HStack(spacing: 12) {
                    // Country code selector
                    Button(action: {
                        isPhoneFieldFocused = false
                        showCountryPicker = true
                    }) {
                        HStack(spacing: 8) {
                            Text(selectedCountry.flag)
                                .font(.system(size: 24))
                            Text(selectedCountry.code)
                                .font(.custom("HelveticaNeue", size: 18))
                                .foregroundColor(.black)
                            Image(systemName: "chevron.down")
                                .font(.system(size: 12))
                                .foregroundColor(.gray)
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                    }

                    // Phone number field
                    TextField("Phone Number", text: $phoneNumber)
                        .font(.custom("HelveticaNeue", size: 24))
                        .keyboardType(.phonePad)
                        .foregroundColor(.black)
                        .focused($isPhoneFieldFocused)
                }
                .padding(.horizontal, 20)
                .padding(.top, 32)

                // Divider
                Rectangle()
                    .fill(Color.black)
                    .frame(height: 2)
                    .padding(.horizontal, 20)
                    .padding(.top, 12)

                Spacer()

                // Continue button
                Button(action: {
                    if !phoneNumber.isEmpty {
                        let fullNumber = selectedCountry.code + phoneNumber
                        Task {
                            do {
                                try await authManager.sendVerificationCode(to: fullNumber)
                                onContinue(fullNumber)
                            } catch {
                                showError = true
                            }
                        }
                    }
                }) {
                    HStack(spacing: 8) {
                        Text("Continue")
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
                    .background((phoneNumber.isEmpty || authManager.isLoading) ? Color.gray : Color.black)
                    .cornerRadius(28)
                }
                .disabled(phoneNumber.isEmpty || authManager.isLoading)
                .padding(.horizontal, 40)
                .padding(.bottom, 50)
            }
        }
        .onAppear {
            isPhoneFieldFocused = true
        }
        .sheet(isPresented: $showCountryPicker) {
            CountryPickerView(countries: countries, selectedCountry: $selectedCountry)
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(authManager.errorMessage ?? "Failed to send verification code. Please try again.")
        }
    }
}

struct CountryPickerView: View {
    let countries: [CountryCode]
    @Binding var selectedCountry: CountryCode
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            List(countries, id: \.code) { country in
                Button(action: {
                    selectedCountry = country
                    dismiss()
                }) {
                    HStack {
                        Text(country.flag)
                            .font(.system(size: 32))
                        VStack(alignment: .leading, spacing: 4) {
                            Text(country.name)
                                .font(.custom("Helvetica-Bold", size: 16))
                                .foregroundColor(.black)
                            Text(country.code)
                                .font(.custom("HelveticaNeue", size: 14))
                                .foregroundColor(.gray)
                        }
                        Spacer()
                        if country.code == selectedCountry.code && country.name == selectedCountry.name {
                            Image(systemName: "checkmark")
                                .foregroundColor(.black)
                        }
                    }
                }
            }
            .navigationTitle("Select Country")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    PhoneNumberInputScreen(onContinue: { _ in })
}

#Preview {
    PhoneNumberInputScreen(onContinue: { _ in })
}
