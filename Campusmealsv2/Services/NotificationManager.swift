//
//  NotificationManager.swift
//  Campusmealsv2
//
//  Push notification management for Squad Up & Eat
//

import Foundation
import UIKit
import UserNotifications
import FirebaseMessaging
import FirebaseAuth

class NotificationManager: NSObject, ObservableObject {
    static let shared = NotificationManager()

    @Published var hasPermission = false
    @Published var fcmToken: String?

    private override init() {
        super.init()
    }

    // MARK: - Permission Request

    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            DispatchQueue.main.async {
                self.hasPermission = granted

                if granted {
                    print("✅ Notification permission granted")
                    DispatchQueue.main.async {
                        UIApplication.shared.registerForRemoteNotifications()
                    }
                } else {
                    print("❌ Notification permission denied")
                }

                if let error = error {
                    print("❌ Error requesting notification permission: \(error.localizedDescription)")
                }
            }
        }
    }

    func checkPermissionStatus() async -> Bool {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        return settings.authorizationStatus == .authorized
    }

    // MARK: - FCM Token Management

    func saveFCMToken(_ token: String?, userId: String) async {
        guard let token = token else { return }

        self.fcmToken = token
        print("📱 FCM Token: \(token)")

        // Save to Firestore
        do {
            try await SquadFirestoreManager.shared.updateFCMToken(token, for: userId)
            print("✅ FCM token saved to Firestore")
        } catch {
            print("❌ Error saving FCM token: \(error.localizedDescription)")
        }
    }

    // MARK: - Local Notifications

    func scheduleLocalNotification(title: String, body: String, timeInterval: TimeInterval, identifier: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Error scheduling notification: \(error.localizedDescription)")
            } else {
                print("✅ Notification scheduled: \(title)")
            }
        }
    }

    func cancelNotification(identifier: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
        print("✅ Cancelled notification: \(identifier)")
    }

    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        print("✅ Cancelled all notifications")
    }

    // MARK: - Badge Management

    func updateBadgeCount(_ count: Int) {
        DispatchQueue.main.async {
            UIApplication.shared.applicationIconBadgeNumber = count
        }
    }

    func clearBadge() {
        updateBadgeCount(0)
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension NotificationManager: UNUserNotificationCenterDelegate {
    // Foreground notification
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                              willPresent notification: UNNotification,
                              withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        print("📬 Foreground notification received: \(notification.request.content.title)")
        completionHandler([.banner, .sound, .badge])
    }

    // Notification tap
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                              didReceive response: UNNotificationResponse,
                              withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        print("👆 Notification tapped, userInfo: \(userInfo)")

        // Handle notification tap based on type
        if let type = userInfo["type"] as? String {
            handleNotificationTap(type: type, data: userInfo)
        }

        completionHandler()
    }

    private func handleNotificationTap(type: String, data: [AnyHashable: Any]) {
        print("🔔 Handling notification type: \(type)")

        switch type {
        case "match_invite":
            if let matchId = data["matchId"] as? String {
                // Navigate to match invites screen
                NotificationCenter.default.post(name: .navigateToMatchInvites, object: matchId)
            }

        case "match_confirmed":
            if let matchId = data["matchId"] as? String {
                // Navigate to match details
                NotificationCenter.default.post(name: .navigateToMatch, object: matchId)
            }

        case "level_up":
            // Navigate to profile
            NotificationCenter.default.post(name: .navigateToProfile, object: nil)

        case "episode_reaction":
            if let episodeId = data["episodeId"] as? String {
                // Navigate to episode feed
                NotificationCenter.default.post(name: .navigateToEpisodes, object: episodeId)
            }

        default:
            print("⚠️ Unknown notification type: \(type)")
        }
    }
}

// MARK: - MessagingDelegate

extension NotificationManager: MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        print("📱 FCM registration token: \(fcmToken ?? "nil")")

        guard let token = fcmToken else { return }
        self.fcmToken = token

        // Save to Firestore if user is logged in
        if let userId = Auth.auth().currentUser?.uid {
            Task {
                await saveFCMToken(token, userId: userId)
            }
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let navigateToMatchInvites = Notification.Name("navigateToMatchInvites")
    static let navigateToMatch = Notification.Name("navigateToMatch")
    static let navigateToProfile = Notification.Name("navigateToProfile")
    static let navigateToEpisodes = Notification.Name("navigateToEpisodes")
}
