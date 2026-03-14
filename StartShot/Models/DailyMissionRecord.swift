import Foundation
import SwiftData

@Model
final class DailyMissionRecord {
    @Attribute(.unique) var targetDate: Date
    var plannedPhotoPath: String
    var plannedCapturedAt: Date
    var messageForTomorrow: String
    var notificationHour: Int
    var notificationMinute: Int
    var actualPhotoPath: String?
    var actualCapturedAt: Date?
    // Legacy field kept only for existing store compatibility.
    var statusRaw: String?
    var completionConfirmedAt: Date?
    var lastUpdatedAt: Date

    init(
        targetDate: Date,
        plannedPhotoPath: String,
        plannedCapturedAt: Date,
        messageForTomorrow: String = "",
        notificationHour: Int = 21,
        notificationMinute: Int = 0,
        actualPhotoPath: String? = nil,
        actualCapturedAt: Date? = nil,
        completionConfirmedAt: Date? = nil,
        lastUpdatedAt: Date = .now
    ) {
        self.targetDate = targetDate
        self.plannedPhotoPath = plannedPhotoPath
        self.plannedCapturedAt = plannedCapturedAt
        self.messageForTomorrow = messageForTomorrow
        self.notificationHour = notificationHour
        self.notificationMinute = notificationMinute
        self.actualPhotoPath = actualPhotoPath
        self.actualCapturedAt = actualCapturedAt
        self.completionConfirmedAt = completionConfirmedAt
        self.lastUpdatedAt = lastUpdatedAt
    }
}
