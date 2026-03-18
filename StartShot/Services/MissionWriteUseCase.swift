import Foundation
import SwiftData
import UIKit

struct NightSetupDraft {
    let image: UIImage
    let targetDate: Date
    let messageForTomorrow: String
    let notificationHour: Int
    let notificationMinute: Int
    let currentDate: Date
}

enum NightSetupSaveResult {
    case saved
    case savedWithNotificationWarning(String)
}

enum MissionWriteUseCase {
    @MainActor
    static func saveNightSetup(
        draft: NightSetupDraft,
        records: [DailyMissionRecord],
        modelContext: ModelContext,
        settingsStore: SettingsStore,
        dateService: DateService
    ) async throws -> NightSetupSaveResult {
        try MissionLifecycleService.upsertPlan(
            for: draft.targetDate,
            image: draft.image,
            messageForTomorrow: draft.messageForTomorrow,
            notificationHour: draft.notificationHour,
            notificationMinute: draft.notificationMinute,
            in: records,
            modelContext: modelContext,
            dateService: dateService,
            currentDate: draft.currentDate
        )

        settingsStore.selfMessage = draft.messageForTomorrow
        settingsStore.notificationHour = draft.notificationHour
        settingsStore.notificationMinute = draft.notificationMinute

        do {
            try await NotificationService.refreshReminder(using: settingsStore)
            return .saved
        } catch {
            return .savedWithNotificationWarning(error.localizedDescription)
        }
    }

    @MainActor
    static func finishMorningStart(
        targetDate: Date,
        capturedImage: UIImage?,
        records: [DailyMissionRecord],
        modelContext: ModelContext,
        currentDate: Date,
        dateService: DateService
    ) throws {
        if let capturedImage {
            try MissionLifecycleService.completeMorningMission(
                for: targetDate,
                image: capturedImage,
                in: records,
                modelContext: modelContext,
                dateService: dateService,
                currentDate: currentDate
            )
            return
        }

        try MissionLifecycleService.confirmAchievement(
            for: targetDate,
            in: records,
            modelContext: modelContext,
            dateService: dateService,
            currentDate: currentDate
        )
    }
}
