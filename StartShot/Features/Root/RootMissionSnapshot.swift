import Foundation

struct RootMissionSnapshot {
    let dailyStatus: DailyMissionStatus
    let homeState: HomeMissionState
    let currentStreak: Int
    let projectedStreak: Int
    let todayRecord: DailyMissionRecord?
    let tomorrowRecord: DailyMissionRecord?
    let nextPlanRecord: DailyMissionRecord?
    let nextPlanTargetDate: Date

    var configuredImagePath: String? {
        switch dailyStatus {
        case .configuredForTomorrow:
            return tomorrowRecord?.plannedPhotoPath
        case .readyForToday, .completedToday:
            return todayRecord?.plannedPhotoPath
        case .notConfigured:
            return nil
        }
    }

    var configuredTargetDate: Date? {
        switch dailyStatus {
        case .configuredForTomorrow:
            return tomorrowRecord?.targetDate
        case .readyForToday, .completedToday:
            return todayRecord?.targetDate
        case .notConfigured:
            return nil
        }
    }
}

extension RootMissionSnapshot {
    static func build(
        records: [DailyMissionRecord],
        timePolicy: MissionTimePolicy,
        dateService: DateService
    ) -> RootMissionSnapshot {
        let dailyStatus = MissionLifecycleService.dailyStatus(
            records: records,
            referenceDate: timePolicy.now,
            dateService: dateService
        )
        let todayRecord = MissionLifecycleService.record(
            for: timePolicy.todayTargetDate,
            in: records,
            dateService: dateService
        )
        let tomorrowRecord = MissionLifecycleService.record(
            for: timePolicy.tomorrowTargetDate,
            in: records,
            dateService: dateService
        )
        let nextPlanTargetDate = timePolicy.planningTargetDate
        let nextPlanRecord = MissionLifecycleService.record(
            for: nextPlanTargetDate,
            in: records,
            dateService: dateService
        )

        return RootMissionSnapshot(
            dailyStatus: dailyStatus,
            homeState: MissionLifecycleService.homeMissionState(for: dailyStatus),
            currentStreak: StreakService.currentStreak(
                records: records,
                referenceDate: timePolicy.now,
                dateService: dateService
            ),
            projectedStreak: StreakService.projectedStreakIfCompletedToday(
                records: records,
                referenceDate: timePolicy.now,
                dateService: dateService
            ),
            todayRecord: todayRecord,
            tomorrowRecord: tomorrowRecord,
            nextPlanRecord: nextPlanRecord,
            nextPlanTargetDate: nextPlanTargetDate
        )
    }
}
