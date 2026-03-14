import Foundation
import Observation

protocol DateProvider {
    var now: Date { get }
}

struct SystemDateProvider: DateProvider {
    var now: Date { Date() }
}

@Observable
final class MockDateProvider: DateProvider {
    var now: Date

    init(now: Date) {
        self.now = now
    }
}

enum DebugTimePreset: String, CaseIterable, Identifiable {
    case h2300
    case h0030
    case h0359
    case h0401
    case h0959
    case h1001

    var id: String { rawValue }

    var label: String {
        switch self {
        case .h2300: return "23:00"
        case .h0030: return "00:30"
        case .h0359: return "03:59"
        case .h0401: return "04:01"
        case .h0959: return "09:59"
        case .h1001: return "10:01"
        }
    }

    var hourMinute: (hour: Int, minute: Int) {
        switch self {
        case .h2300: return (23, 0)
        case .h0030: return (0, 30)
        case .h0359: return (3, 59)
        case .h0401: return (4, 1)
        case .h0959: return (9, 59)
        case .h1001: return (10, 1)
        }
    }
}

@Observable
final class AppDateProvider: DateProvider {
    private let systemDateProvider = SystemDateProvider()
    private let calendar: Calendar

    var mockDateProvider: MockDateProvider
    var usesMockDate: Bool = false

    init(calendar: Calendar = .current, initialMockDate: Date = Date()) {
        var configuredCalendar = calendar
        configuredCalendar.timeZone = .current
        self.calendar = configuredCalendar
        self.mockDateProvider = MockDateProvider(now: initialMockDate)
    }

    var now: Date {
#if DEBUG
        usesMockDate ? mockDateProvider.now : systemDateProvider.now
#else
        systemDateProvider.now
#endif
    }

    var mockNow: Date {
        get { mockDateProvider.now }
        set { mockDateProvider.now = newValue }
    }

    func applyPreset(_ preset: DebugTimePreset) {
#if DEBUG
        let sourceDate = usesMockDate ? mockNow : now
        var components = calendar.dateComponents([.year, .month, .day], from: sourceDate)
        components.hour = preset.hourMinute.hour
        components.minute = preset.hourMinute.minute
        mockNow = calendar.date(from: components) ?? sourceDate
        usesMockDate = true
#else
        _ = preset
#endif
    }
}
