import Foundation

enum AppTab: Hashable {
    case home
    case calendar
}

enum HomeMissionState {
    case empty
    case configured
    case completed
}

enum DailyMissionStatus {
    case notConfigured
    case configuredForTomorrow
    case readyForToday
    case completedToday
}

enum ActiveFlow: Identifiable {
    case nightCapture
    case nightSetupConfirm
    case morningCapture
    case morningStartConfirm
    case settings

    var id: String {
        switch self {
        case .nightCapture:
            return "nightCapture"
        case .nightSetupConfirm:
            return "nightSetupConfirm"
        case .morningCapture:
            return "morningCapture"
        case .morningStartConfirm:
            return "morningStartConfirm"
        case .settings:
            return "settings"
        }
    }
}
