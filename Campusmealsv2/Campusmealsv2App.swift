//
//  Campusmealsv2App.swift
//  Campusmealsv2
//
//  Created by sarp akar on 02/10/2025.
//

import SwiftUI
import SwiftData
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore
import FirebaseMessaging
import UserNotifications

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()

        // Completely disable App Check to avoid warnings
        #if DEBUG
        let settings = Firestore.firestore().settings
        settings.isSSLEnabled = true
        Firestore.firestore().settings = settings

        // Seed sample data (commented out - using sample data directly)
        // Uncomment the line below to populate Firestore with sample vendors and menu items
        // FirestoreSeedData.seedAll()
        #endif

        // Set up push notifications
        UNUserNotificationCenter.current().delegate = NotificationManager.shared
        Messaging.messaging().delegate = NotificationManager.shared

        // Request notification permission
        NotificationManager.shared.requestPermission()

        return true
    }

    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Auth.auth().setAPNSToken(deviceToken, type: .unknown)
        Messaging.messaging().apnsToken = deviceToken
        print("📱 APNs device token registered")
    }

    func application(_ application: UIApplication,
                     didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("❌ Failed to register for remote notifications: \(error.localizedDescription)")
    }

    func application(_ application: UIApplication,
                     didReceiveRemoteNotification notification: [AnyHashable : Any],
                     fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        if Auth.auth().canHandleNotification(notification) {
            completionHandler(.noData)
            return
        }

        // Handle remote notification
        print("📬 Remote notification received: \(notification)")
        completionHandler(.newData)
    }

    func application(_ application: UIApplication,
                     open url: URL,
                     options: [UIApplication.OpenURLOptionsKey : Any]) -> Bool {
        if Auth.auth().canHandle(url) {
            return true
        }
        return false
    }
}

@main
struct Campusmealsv2App: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            AppLaunchView()
        }
        .modelContainer(sharedModelContainer)
    }
}

struct AppLaunchView: View {
    @StateObject private var authManager = AuthenticationManager.shared
    @State private var isCheckingAuth = true

    var body: some View {
        ZStack {
            if isCheckingAuth {
                Color.white
                    .edgesIgnoringSafeArea(.all)
            } else {
                OnboardingFlowView()
            }
        }
        .task {
            // Quick auth check - no delay
            isCheckingAuth = false
        }
    }
}
