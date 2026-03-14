import Foundation
import Observation

@Observable
final class SettingsStore {
    private enum Keys {
        static let notificationHour = "notificationHour"
        static let notificationMinute = "notificationMinute"
        static let selfMessage = "selfMessage"
        static let notificationsEnabled = "notificationsEnabled"
    }

    private let defaults: UserDefaults

    var notificationHour: Int {
        didSet { persist() }
    }

    var notificationMinute: Int {
        didSet { persist() }
    }

    var selfMessage: String {
        didSet { persist() }
    }

    var notificationsEnabled: Bool {
        didSet { persist() }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        let hour = defaults.object(forKey: Keys.notificationHour) as? Int ?? 21
        let minute = defaults.object(forKey: Keys.notificationMinute) as? Int ?? 0
        let message = defaults.string(forKey: Keys.selfMessage) ?? "明日の自分を助けよう"
        let enabled = defaults.bool(forKey: Keys.notificationsEnabled)

        self.notificationHour = hour
        self.notificationMinute = minute
        self.selfMessage = message
        self.notificationsEnabled = enabled
    }

    var reminderDate: Date {
        var components = Calendar.current.dateComponents([.year, .month, .day], from: .now)
        components.hour = notificationHour
        components.minute = notificationMinute
        return Calendar.current.date(from: components) ?? .now
    }

    var reminderComponents: DateComponents {
        var components = DateComponents()
        components.hour = notificationHour
        components.minute = notificationMinute
        return components
    }

    func updateReminderTime(_ date: Date) {
        let components = Calendar.current.dateComponents([.hour, .minute], from: date)
        notificationHour = components.hour ?? 21
        notificationMinute = components.minute ?? 0
    }

    private func persist() {
        defaults.set(notificationHour, forKey: Keys.notificationHour)
        defaults.set(notificationMinute, forKey: Keys.notificationMinute)
        defaults.set(selfMessage, forKey: Keys.selfMessage)
        defaults.set(notificationsEnabled, forKey: Keys.notificationsEnabled)
    }
}
