import Foundation
import UserNotifications

enum NotificationError: LocalizedError {
    case permissionDenied

    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            "通知が許可されていません。設定アプリから通知を有効化してください。"
        }
    }
}

struct NotificationService {
    static let reminderIdentifier = "daily-mission-reminder"

    static func refreshReminder(using settingsStore: SettingsStore) async throws {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [reminderIdentifier])

        guard settingsStore.notificationsEnabled else {
            return
        }

        let granted = try await ensureAuthorization()
        guard granted else {
            throw NotificationError.permissionDenied
        }

        let content = UNMutableNotificationContent()
        content.title = "StartShot"
        content.body = settingsStore.selfMessage.isEmpty ? "明日のスタート地点を記録しましょう。" : settingsStore.selfMessage
        content.sound = .default

        let trigger = UNCalendarNotificationTrigger(dateMatching: settingsStore.reminderComponents, repeats: true)
        let request = UNNotificationRequest(identifier: reminderIdentifier, content: content, trigger: trigger)
        try await addRequest(center: center, request: request)
    }

    private static func ensureAuthorization() async throws -> Bool {
        let center = UNUserNotificationCenter.current()
        let settings = await notificationSettings(center: center)

        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return true
        case .denied:
            return false
        case .notDetermined:
            return try await requestAuthorization(center: center)
        @unknown default:
            return false
        }
    }

    private static func notificationSettings(center: UNUserNotificationCenter) async -> UNNotificationSettings {
        await withCheckedContinuation { continuation in
            center.getNotificationSettings { settings in
                continuation.resume(returning: settings)
            }
        }
    }

    private static func requestAuthorization(center: UNUserNotificationCenter) async throws -> Bool {
        try await withCheckedThrowingContinuation { continuation in
            center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: granted)
                }
            }
        }
    }

    private static func addRequest(center: UNUserNotificationCenter, request: UNNotificationRequest) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            center.add(request) { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
    }
}
