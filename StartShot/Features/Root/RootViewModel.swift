import Observation
import UIKit

@Observable
@MainActor
final class RootViewModel {
    var selectedTab: AppTab = .home
    var activeFlow: ActiveFlow?
    var pendingNightImage: UIImage?
    var pendingMorningImage: UIImage?

    func showSettings() {
        activeFlow = .settings
    }

    func handleHomePrimaryAction(status: DailyMissionStatus) {
        switch status {
        case .notConfigured:
            activeFlow = .nightCapture
        case .readyForToday:
            activeFlow = .morningCapture
        case .configuredForTomorrow, .completedToday:
            return
        }
    }

    func handleConfiguredMissionEdit(status: DailyMissionStatus, configuredImagePath: String?) {
        guard status == .configuredForTomorrow else {
            return
        }
        guard
            let configuredImagePath,
            let image = PhotoFileStore.image(for: configuredImagePath)
        else {
            activeFlow = .nightCapture
            return
        }

        pendingNightImage = image
        activeFlow = .nightSetupConfirm
    }

    func handleNightCapture(_ image: UIImage) {
        pendingNightImage = image
        activeFlow = .nightSetupConfirm
    }

    func handleMorningCapture(_ image: UIImage) {
        pendingMorningImage = image
        activeFlow = .morningStartConfirm
    }

    func retakeNightCapture() {
        activeFlow = .nightCapture
    }

    func retakeMorningCapture() {
        activeFlow = .morningCapture
    }

    func closeFlow() {
        activeFlow = nil
    }

    func returnHomeAndCloseFlow() {
        selectedTab = .home
        closeFlow()
    }

    func clearTransientState() {
        pendingNightImage = nil
        pendingMorningImage = nil
    }
}
