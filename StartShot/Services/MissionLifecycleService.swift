import Foundation
import SwiftData
import UIKit

enum MissionError: LocalizedError {
    case plannedMissionMissing
    case actualPhotoMissing
    case missionExecutionDeadlinePassed

    var errorDescription: String? {
        switch self {
        case .plannedMissionMissing:
            "前日に設定した写真がありません。まず明日のスタート地点を登録してください。"
        case .actualPhotoMissing:
            "当日の写真がまだ保存されていません。"
        case .missionExecutionDeadlinePassed:
            "朝ミッションの実行期限を過ぎています。次のミッションを設定しましょう。"
        }
    }
}

struct MissionLifecycleService {
    static func resolvedStatus(
        for record: DailyMissionRecord,
        referenceDate: Date = .now,
        dateService: DateService = .shared
    ) -> AchievementStatus {
        let today = dateService.startOfDay(for: referenceDate)

        // Resolution order is intentional:
        // 1) confirmed completion always wins
        // 2) past date/deadline is missed
        // 3) otherwise infer progress from saved photos
        if record.completionConfirmedAt != nil {
            return .achieved
        }

        if record.targetDate < today {
            return .missed
        }

        if dateService.isSameDay(record.targetDate, today),
           dateService.isPastMissionExecutionDeadline(targetDate: record.targetDate, at: referenceDate) {
            return .missed
        }

        if record.actualPhotoPath != nil {
            return .started
        }
        if !record.plannedPhotoPath.isEmpty {
            return .planned
        }

        return .notSet
    }

    static func record(
        for targetDate: Date,
        in records: [DailyMissionRecord],
        dateService: DateService = .shared
    ) -> DailyMissionRecord? {
        let normalizedTargetDate = dateService.startOfDay(for: targetDate)
        return records.first { dateService.isSameDay($0.targetDate, normalizedTargetDate) }
    }

    private static func status(
        for targetDate: Date,
        in records: [DailyMissionRecord],
        referenceDate: Date = .now,
        dateService: DateService = .shared
    ) -> AchievementStatus {
        guard let record = record(for: targetDate, in: records, dateService: dateService) else {
            return .notSet
        }

        return resolvedStatus(for: record, referenceDate: referenceDate, dateService: dateService)
    }

    static func dailyStatus(
        records: [DailyMissionRecord],
        referenceDate: Date = .now,
        dateService: DateService = .shared
    ) -> DailyMissionStatus {
        let todayStatus = status(
            for: dateService.startOfDay(for: referenceDate),
            in: records,
            referenceDate: referenceDate,
            dateService: dateService
        )

        switch todayStatus {
        case .planned, .started:
            return .readyForToday
        case .achieved:
            return .completedToday
        case .notSet, .missed:
            let tomorrowStatus = status(
                for: dateService.tomorrow(from: dateService.startOfDay(for: referenceDate)),
                in: records,
                referenceDate: referenceDate,
                dateService: dateService
            )
            return tomorrowStatus == .planned ? .configuredForTomorrow : .notConfigured
        }
    }

    static func homeMissionState(for dailyStatus: DailyMissionStatus) -> HomeMissionState {
        switch dailyStatus {
        case .completedToday:
            return .completed
        case .configuredForTomorrow, .readyForToday:
            return .configured
        case .notConfigured:
            return .empty
        }
    }

    @discardableResult
    static func upsertPlan(
        for targetDate: Date,
        image: UIImage,
        messageForTomorrow: String,
        notificationHour: Int,
        notificationMinute: Int,
        in records: [DailyMissionRecord],
        modelContext: ModelContext,
        dateService: DateService = .shared,
        currentDate: Date = .now
    ) throws -> DailyMissionRecord {
        let normalizedTargetDate = dateService.startOfDay(for: targetDate)
        let relativePath = try PhotoFileStore.saveImage(image, targetDate: normalizedTargetDate, role: .planned, dateService: dateService)

        // Reuse if the same target date exists; otherwise create.
        let record = record(for: normalizedTargetDate, in: records, dateService: dateService) ?? DailyMissionRecord(
            targetDate: normalizedTargetDate,
            plannedPhotoPath: relativePath,
            plannedCapturedAt: currentDate
        )

        record.targetDate = normalizedTargetDate
        record.plannedPhotoPath = relativePath
        record.plannedCapturedAt = currentDate
        record.messageForTomorrow = messageForTomorrow
        record.notificationHour = notificationHour
        record.notificationMinute = notificationMinute
        record.actualPhotoPath = nil
        record.actualCapturedAt = nil
        record.completionConfirmedAt = nil
        record.lastUpdatedAt = currentDate

        if record.modelContext == nil {
            modelContext.insert(record)
        }

        try modelContext.save()
        return record
    }

    static func completeMorningMission(
        for targetDate: Date,
        image: UIImage,
        in records: [DailyMissionRecord],
        modelContext: ModelContext,
        dateService: DateService = .shared,
        currentDate: Date = .now
    ) throws {
        let normalizedTargetDate = dateService.startOfDay(for: targetDate)
        try ensureMorningMissionCanBeCompleted(
            targetDate: normalizedTargetDate,
            currentDate: currentDate,
            dateService: dateService
        )

        let record = try saveActualStart(
            for: normalizedTargetDate,
            image: image,
            in: records,
            modelContext: modelContext,
            dateService: dateService,
            currentDate: currentDate
        )

        record.completionConfirmedAt = currentDate
        record.lastUpdatedAt = currentDate
        try modelContext.save()
    }

    @discardableResult
    static func saveActualStart(
        for targetDate: Date,
        image: UIImage,
        in records: [DailyMissionRecord],
        modelContext: ModelContext,
        dateService: DateService = .shared,
        currentDate: Date = .now
    ) throws -> DailyMissionRecord {
        let normalizedTargetDate = dateService.startOfDay(for: targetDate)
        guard let record = record(for: normalizedTargetDate, in: records, dateService: dateService) else {
            throw MissionError.plannedMissionMissing
        }

        let relativePath = try PhotoFileStore.saveImage(image, targetDate: normalizedTargetDate, role: .actual, dateService: dateService)
        record.actualPhotoPath = relativePath
        record.actualCapturedAt = currentDate
        record.completionConfirmedAt = nil
        record.lastUpdatedAt = currentDate

        try modelContext.save()
        return record
    }

    static func confirmAchievement(
        for targetDate: Date,
        in records: [DailyMissionRecord],
        modelContext: ModelContext,
        dateService: DateService = .shared,
        currentDate: Date = .now
    ) throws {
        let normalizedTargetDate = dateService.startOfDay(for: targetDate)
        try ensureMorningMissionCanBeCompleted(
            targetDate: normalizedTargetDate,
            currentDate: currentDate,
            dateService: dateService
        )

        guard let record = record(for: normalizedTargetDate, in: records, dateService: dateService) else {
            throw MissionError.plannedMissionMissing
        }
        guard record.actualPhotoPath != nil else {
            throw MissionError.actualPhotoMissing
        }

        record.completionConfirmedAt = currentDate
        record.lastUpdatedAt = currentDate
        try modelContext.save()
    }

    private static func ensureMorningMissionCanBeCompleted(
        targetDate: Date,
        currentDate: Date,
        dateService: DateService
    ) throws {
        if dateService.isPastMissionExecutionDeadline(targetDate: targetDate, at: currentDate) {
            throw MissionError.missionExecutionDeadlinePassed
        }
    }
}
