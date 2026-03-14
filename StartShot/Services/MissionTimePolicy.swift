import Foundation

struct MissionTimePolicy {
    private let dateProvider: DateProvider
    private let dateService: DateService

    init(dateProvider: DateProvider, dateService: DateService = .shared) {
        self.dateProvider = dateProvider
        self.dateService = dateService
    }

    var now: Date {
        dateProvider.now
    }

    var todayTargetDate: Date {
        dateService.startOfDay(for: now)
    }

    var tomorrowTargetDate: Date {
        dateService.tomorrow(from: todayTargetDate)
    }

    var planningTargetDate: Date {
        dateService.missionTargetDateForNewPlan(from: now)
    }
}
