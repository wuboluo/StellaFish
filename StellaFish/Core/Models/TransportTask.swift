import Foundation
import SwiftData

@Model
final class TransportTask {
    var id: UUID
    var trip: Trip?
    var title: String
    var fromPlace: String
    var toPlace: String
    var date: Date
    var transportTypesRaw: [String]
    var targetPrice: Double
    var targetSeatStatusRaw: String
    var reminderIntervalMinutes: Int
    var nextReminderAt: Date?
    var note: String
    var createdAt: Date
    var updatedAt: Date

    @Relationship(deleteRule: .cascade, inverse: \TicketSnapshot.task)
    var snapshots: [TicketSnapshot]

    init(
        trip: Trip? = nil,
        title: String,
        fromPlace: String = "",
        toPlace: String = "",
        date: Date = Date(),
        transportTypes: [TransportType] = [.highSpeedTrain],
        targetPrice: Double = 0,
        targetSeatStatus: SeatStatus = .notChecked,
        reminderIntervalMinutes: Int = ReminderInterval.oneHour.rawValue,
        note: String = ""
    ) {
        self.id = UUID()
        self.trip = trip
        self.title = title
        self.fromPlace = fromPlace
        self.toPlace = toPlace
        self.date = date
        self.transportTypesRaw = transportTypes.map(\.rawValue)
        self.targetPrice = targetPrice
        self.targetSeatStatusRaw = targetSeatStatus.rawValue
        self.reminderIntervalMinutes = reminderIntervalMinutes
        self.note = note
        self.createdAt = Date()
        self.updatedAt = Date()
        self.snapshots = []
    }

    var transportTypes: [TransportType] {
        get { transportTypesRaw.compactMap { TransportType(rawValue: $0) } }
        set { transportTypesRaw = newValue.map(\.rawValue) }
    }

    var targetSeatStatus: SeatStatus {
        get { SeatStatus(rawValue: targetSeatStatusRaw) ?? .notChecked }
        set { targetSeatStatusRaw = newValue.rawValue }
    }
}
