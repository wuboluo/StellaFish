import Foundation
import SwiftData

@Model
final class TicketSnapshot {
    var id: UUID
    var task: TransportTask?
    var platform: String
    var transportTypeRaw: String
    var code: String
    var price: Double
    var seatStatusRaw: String
    var departTime: Date
    var arriveTime: Date
    var fromStation: String
    var toStation: String
    var transferCost: Double
    var transferMinutes: Int
    var extraMinutes: Int
    var baggageCost: Double
    var riskCost: Double
    var hassleCost: Double
    var note: String
    var createdAt: Date

    init(
        task: TransportTask? = nil,
        platform: String = "12306",
        transportType: TransportType = .highSpeedTrain,
        code: String = "",
        price: Double = 0,
        seatStatus: SeatStatus = .notChecked,
        departTime: Date = Date(),
        arriveTime: Date = Date(),
        fromStation: String = "",
        toStation: String = "",
        transferCost: Double = 0,
        transferMinutes: Int = 0,
        extraMinutes: Int? = nil,
        baggageCost: Double = 0,
        riskCost: Double? = nil,
        hassleCost: Double? = nil,
        note: String = ""
    ) {
        self.id = UUID()
        self.task = task
        self.platform = platform
        self.transportTypeRaw = transportType.rawValue
        self.code = code
        self.price = price
        self.seatStatusRaw = seatStatus.rawValue
        self.departTime = departTime
        self.arriveTime = arriveTime
        self.fromStation = fromStation
        self.toStation = toStation
        self.transferCost = transferCost
        self.transferMinutes = transferMinutes
        self.extraMinutes = extraMinutes ?? transportType.defaultExtraMinutes
        self.baggageCost = baggageCost
        self.riskCost = riskCost ?? transportType.defaultRiskCost
        self.hassleCost = hassleCost ?? transportType.defaultHassleCost
        self.note = note
        self.createdAt = Date()
    }

    var transportType: TransportType {
        get { TransportType(rawValue: transportTypeRaw) ?? .other }
        set { transportTypeRaw = newValue.rawValue }
    }

    var seatStatus: SeatStatus {
        get { SeatStatus(rawValue: seatStatusRaw) ?? .notChecked }
        set { seatStatusRaw = newValue.rawValue }
    }

    var mainDurationMinutes: Int {
        Int(arriveTime.timeIntervalSince(departTime) / 60)
    }

    var doorToDoorMinutes: Int {
        mainDurationMinutes + transferMinutes + extraMinutes
    }

    func totalCost(people: Int, timeValuePerHour: Double = 0) -> Double {
        guard seatStatus != .noTicket else { return Double.infinity }
        let ticketTotal = price * Double(people)
        return ticketTotal + transferCost + baggageCost + riskCost + hassleCost
    }
}
