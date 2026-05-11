import Foundation
import SwiftData

@Model
final class TrainTicketRecord {
    var id: UUID
    var trip: Trip?
    var trainNo: String
    var departStation: String
    var arriveStation: String
    var departDate: Date?
    var departTime: String
    var arriveTime: String
    var seatType: String
    var carriageNo: String
    var seatNo: String
    var ticketPrice: Double
    var ticketStatus: String  // 未购买/已购买/候补/无票/待确认
    var checkInGate: String
    var passengerName: String
    var note: String
    var ocrText: String
    var createdAt: Date
    var updatedAt: Date

    init(trainNo: String = "") {
        self.id = UUID()
        self.trainNo = trainNo
        self.departStation = ""
        self.arriveStation = ""
        self.departDate = nil
        self.departTime = ""
        self.arriveTime = ""
        self.seatType = "二等座"
        self.carriageNo = ""
        self.seatNo = ""
        self.ticketPrice = 0
        self.ticketStatus = "已购买"
        self.checkInGate = ""
        self.passengerName = ""
        self.note = ""
        self.ocrText = ""
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}
