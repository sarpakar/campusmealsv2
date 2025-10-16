//
//  WelcomeScreen.swift
//  Campusmealsv2
//
//  Created by sarp akar on 02/10/2025.
//

import SwiftUI
import CoreLocation

struct WelcomeScreen: View {
    @StateObject private var locationManager = LocationManager.shared
    @StateObject private var authManager = AuthenticationManager.shared
    @State private var showButton = false
    @State private var showLogoutMenu = false
    @State private var selectedTab: TabItem = .browse
    var onGetStarted: () -> Void
    

    
    var body: some View {
        ZStack {
            Color.white
                .edgesIgnoringSafeArea(.all)

            VStack(spacing: 0) {
                // Top bar with logout button (only if user is logged in)
                if authManager.currentUser != nil {
                    HStack {
                        Button(action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                showLogoutMenu.toggle()
                            }
                        }) {
                            Image(systemName: "line.3.horizontal")
                                .font(.system(size: 22, weight: .medium))
                                .foregroundColor(.black)
                                .frame(width: 44, height: 44)
                        }

                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 60)
                }

                Spacer()

                // Logo
                Image("logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200, height: 200)

                Spacer()

                VStack(spacing: 16) {
                    // Get Started Button
                    Button(action: {
                        Task {
                            // Request permission if not determined
                            if locationManager.authorizationStatus == .notDetermined {
                                _ = await locationManager.requestLocationPermission()
                            }
                            onGetStarted()
                        }
                    }) {

                        Text("Get Started")
                            .font(.custom("HelveticaNeue-Bold", size: 18))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color.black)
                            .cornerRadius(28)
                    }
                    .padding(.horizontal, 40)
                    .offset(y: showButton ? 0 : 20)
                    .opacity(showButton ? 1 : 0)

                    Text("Ready to start your journey? Get started")
                        .font(.custom("HelveticaNeue-Thin", size: 14))
                        .foregroundColor(.gray)
                        .offset(y: showButton ? 0 : 20)
                        .opacity(showButton ? 1 : 0)
                }
                .padding(.bottom, 16)

                // Liquid glass tab bar
                LiquidTabBar(selectedTab: $selectedTab)
                    .offset(y: showButton ? 0 : 100)
                    .opacity(showButton ? 1 : 0)
                    .padding(.bottom, 8)
            }
            .onChange(of: selectedTab) { oldValue, newValue in
                // Handle tab changes on welcome screen
                HapticFeedback.light()
                // For now, tabs are just for display on welcome screen
                // Actual navigation happens after login
            }

            // Logout menu overlay
            if showLogoutMenu {
                Color.black.opacity(0.3)
                    .edgesIgnoringSafeArea(.all)
                    .onTapGesture {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            showLogoutMenu = false
                        }
                    }

                VStack {
                    HStack {
                        VStack(alignment: .leading, spacing: 0) {
                            // User info
                            if let phoneNumber = authManager.currentUser?.phoneNumber {
                                Text(phoneNumber)
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.black)
                                    .padding(.horizontal, 20)
                                    .padding(.top, 20)
                                    .padding(.bottom, 12)
                            }

                            Divider()

                            // Logout button
                            Button(action: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    showLogoutMenu = false
                                }
                                try? authManager.signOut()
                            }) {
                                HStack {
                                    Image(systemName: "rectangle.portrait.and.arrow.right")
                                        .font(.system(size: 18, weight: .medium))
                                    Text("Logout")
                                        .font(.system(size: 16, weight: .medium))
                                }
                                .foregroundColor(.red)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 16)
                            }
                        }
                        .frame(width: 250)
                        .background(Color.white)
                        .cornerRadius(12)
                        .shadow(color: Color.black.opacity(0.15), radius: 20, x: 0, y: 8)
                        .padding(.leading, 20)
                        .padding(.top, 100)

                        Spacer()
                    }

                    Spacer()
                }
                .transition(.move(edge: .leading))
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.3)) {
                showButton = true
            }
        }
    }
}

#Preview {
    WelcomeScreen(onGetStarted: {})
}

  
