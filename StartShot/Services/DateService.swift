import Foundation

struct DateService {
    static let shared = DateService()

    // 0:00-3:59 is treated as the previous night's extension for planning behavior.
    let morningCutoffHour: Int = 4
    // Morning missions must be completed by this time.
    let missionExecutionDeadlineHour: Int = 10

    private let calendar: Calendar
    private let dayFormatter: DateFormatter
    private let monthFormatter: DateFormatter
    private let dayNumberFormatter: DateFormatter

    init(calendar: Calendar = .current) {
        var configuredCalendar = calendar
        configuredCalendar.timeZone = .current
        self.calendar = configuredCalendar

        let dayFormatter = DateFormatter()
        dayFormatter.calendar = configuredCalendar
        dayFormatter.locale = .current
        dayFormatter.timeZone = .current
        dayFormatter.dateFormat = "yyyy-MM-dd"
        self.dayFormatter = dayFormatter

        let monthFormatter = DateFormatter()
        monthFormatter.calendar = configuredCalendar
        monthFormatter.locale = .current
        monthFormatter.timeZone = .current
        monthFormatter.dateFormat = "yyyy年M月"
        self.monthFormatter = monthFormatter

        let dayNumberFormatter = DateFormatter()
        dayNumberFormatter.calendar = configuredCalendar
        dayNumberFormatter.locale = .current
        dayNumberFormatter.timeZone = .current
        dayNumberFormatter.dateFormat = "d"
        self.dayNumberFormatter = dayNumberFormatter
    }

    func startOfDay(for date: Date) -> Date {
        calendar.startOfDay(for: date)
    }

    func tomorrow(from date: Date) -> Date {
        calendar.date(byAdding: .day, value: 1, to: startOfDay(for: date)) ?? startOfDay(for: date)
    }

    func yesterday(from date: Date) -> Date {
        calendar.date(byAdding: .day, value: -1, to: startOfDay(for: date)) ?? startOfDay(for: date)
    }

    func missionTargetDateForNewPlan(from date: Date) -> Date {
        if isBeforeMorningCutoff(date) {
            return startOfDay(for: date)
        }
        return tomorrow(from: date)
    }

    func missionExecutionDeadline(for targetDate: Date) -> Date {
        let base = startOfDay(for: targetDate)
        return calendar.date(byAdding: .hour, value: missionExecutionDeadlineHour, to: base) ?? base
    }

    func isBeforeMorningCutoff(_ date: Date) -> Bool {
        let hour = calendar.component(.hour, from: date)
        return hour < morningCutoffHour
    }

    func isPastMissionExecutionDeadline(targetDate: Date, at referenceDate: Date) -> Bool {
        referenceDate > missionExecutionDeadline(for: targetDate)
    }

    func startOfMonth(for date: Date) -> Date {
        let components = calendar.dateComponents([.year, .month], from: date)
        return calendar.date(from: components) ?? startOfDay(for: date)
    }

    func isSameDay(_ lhs: Date, _ rhs: Date) -> Bool {
        calendar.isDate(lhs, inSameDayAs: rhs)
    }

    func isSameMonth(_ lhs: Date, _ rhs: Date) -> Bool {
        calendar.isDate(lhs, equalTo: rhs, toGranularity: .month)
    }

    func dayString(for date: Date) -> String {
        dayFormatter.string(from: startOfDay(for: date))
    }

    func monthTitle(for date: Date) -> String {
        monthFormatter.string(from: date)
    }

    func dayNumberString(for date: Date) -> String {
        dayNumberFormatter.string(from: date)
    }

    func daysForMonthGrid(containing month: Date) -> [Date] {
        let firstDay = startOfMonth(for: month)
        let weekday = calendar.component(.weekday, from: firstDay)
        let leadingDays = weekday - calendar.firstWeekday
        let normalizedLeadingDays = leadingDays >= 0 ? leadingDays : leadingDays + 7
        let gridStart = calendar.date(byAdding: .day, value: -normalizedLeadingDays, to: firstDay) ?? firstDay

        return (0..<42).compactMap {
            calendar.date(byAdding: .day, value: $0, to: gridStart)
        }
    }

}
