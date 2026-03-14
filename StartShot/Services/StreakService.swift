import Foundation

struct StreakService {
    static func currentStreak(
        records: [DailyMissionRecord],
        referenceDate: Date = .now,
        dateService: DateService = .shared
    ) -> Int {
        streakCount(
            achievedDates: achievedDates(from: records, additionalAchievedDate: nil, dateService: dateService),
            referenceDate: referenceDate,
            dateService: dateService
        )
    }

    static func projectedStreakIfCompletedToday(
        records: [DailyMissionRecord],
        referenceDate: Date = .now,
        dateService: DateService = .shared
    ) -> Int {
        let today = dateService.startOfDay(for: referenceDate)
        return streakCount(
            achievedDates: achievedDates(from: records, additionalAchievedDate: today, dateService: dateService),
            referenceDate: referenceDate,
            dateService: dateService
        )
    }

    private static func achievedDates(
        from records: [DailyMissionRecord],
        additionalAchievedDate: Date?,
        dateService: DateService
    ) -> Set<Date> {
        var dates = Set(records.compactMap { record in
            record.completionConfirmedAt != nil ? dateService.startOfDay(for: record.targetDate) : nil
        })

        if let additionalAchievedDate {
            dates.insert(dateService.startOfDay(for: additionalAchievedDate))
        }

        return dates
    }

    private static func streakCount(
        achievedDates: Set<Date>,
        referenceDate: Date,
        dateService: DateService
    ) -> Int {
        var cursor = dateService.startOfDay(for: referenceDate)
        if !achievedDates.contains(cursor) {
            cursor = dateService.yesterday(from: cursor)
        }

        var count = 0
        while achievedDates.contains(cursor) {
            count += 1
            cursor = dateService.yesterday(from: cursor)
        }

        return count
    }
}
