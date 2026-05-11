import Foundation
import SwiftData

@Model
final class FlightTicketRecord {
    var id: UUID
    var trip: Trip?
    var airline: String
    var flightNo: String
    var departAirport: String
    var arriveAirport: String
    var departTerminal: String
    var arriveTerminal: String
    var departDate: Date?
    var departTime: String
    var arriveTime: String
    var seatClass: String     // 经济舱/公务舱/头等舱
    var ticketPrice: Double
    var ticketStatus: String  // 未购买/已购买/待确认
    var bookingNo: String
    var passengerName: String
    var baggageInfo: String
    var note: String
    var ocrText: String
    var createdAt: Date
    var updatedAt: Date

    init(flightNo: String = "", airline: String = "") {
        self.id = UUID()
        self.airline = airline
        self.flightNo = flightNo
        self.departAirport = ""
        self.arriveAirport = ""
        self.departTerminal = ""
        self.arriveTerminal = ""
        self.departDate = nil
        self.departTime = ""
        self.arriveTime = ""
        self.seatClass = "经济舱"
        self.ticketPrice = 0
        self.ticketStatus = "已购买"
        self.bookingNo = ""
        self.passengerName = ""
        self.baggageInfo = ""
        self.note = ""
        self.ocrText = ""
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}
