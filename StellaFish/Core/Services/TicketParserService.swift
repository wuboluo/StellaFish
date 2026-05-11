import Foundation

struct TrainTicketFields {
    var trainNo = ""
    var departStation = ""
    var arriveStation = ""
    var departDate = ""
    var departTime = ""
    var arriveTime = ""
    var seatType = ""
    var carriageNo = ""
    var seatNo = ""
    var ticketPrice = ""
    var ticketStatus = ""
    var checkInGate = ""
    var passengerName = ""
    var note = ""
}

struct FlightTicketFields {
    var airline = ""
    var flightNo = ""
    var departAirport = ""
    var arriveAirport = ""
    var departTerminal = ""
    var arriveTerminal = ""
    var departDate = ""
    var departTime = ""
    var arriveTime = ""
    var seatClass = ""
    var ticketPrice = ""
    var ticketStatus = ""
    var bookingNo = ""
    var passengerName = ""
    var baggageInfo = ""
    var note = ""
}

final class TicketParserService {
    static let shared = TicketParserService()
    private init() {}

    private let trainSystemPrompt = """
    你是票据信息提取助手。从以下高铁/动车票据 OCR 文字中提取关键字段，以纯 JSON 格式返回，所有字段值必须是字符串类型，不要添加任何其他说明。无法确定的字段返回空字符串，不要编造。
    时间格式要求：departTime 和 arriveTime 必须是 HH:mm 格式（24小时制），例如 08:30、14:30。中文冒号「：」请转换为英文冒号「:」。
    日期格式要求：departDate 格式为 yyyy-MM-dd，如 2026-05-01；若只有月日，年份默认 2026。
    """

    private let flightSystemPrompt = """
    你是票据信息提取助手。从以下机票/订单 OCR 文字中提取关键字段，以纯 JSON 格式返回，所有字段值必须是字符串类型，不要添加任何其他说明。无法确定的字段返回空字符串，不要编造。
    时间格式要求：departTime 和 arriveTime 必须是 HH:mm 格式（24小时制），例如 06:40、09:20。中文冒号「：」请转换为英文冒号「:」。
    日期格式要求：departDate 格式为 yyyy-MM-dd，如 2026-05-01；若只有月日，年份默认 2026。
    """

    func parseTrainTicket(ocrText: String) async throws -> TrainTicketFields {
        let userPrompt = """
        OCR 文字：
        \(ocrText)

        请提取以下字段并以 JSON 格式返回：
        {"trainNo":"","departStation":"","arriveStation":"","departDate":"","departTime":"","arriveTime":"","seatType":"","carriageNo":"","seatNo":"","ticketPrice":"","ticketStatus":"","checkInGate":"","passengerName":"","note":""}
        """
        let raw = try await DeepSeekService.shared.sendMessage(systemPrompt: trainSystemPrompt, userPrompt: userPrompt)
        return decodeTrainFields(extractJSON(raw))
    }

    func parseFlightTicket(ocrText: String) async throws -> FlightTicketFields {
        let userPrompt = """
        OCR 文字：
        \(ocrText)

        请提取以下字段并以 JSON 格式返回：
        {"airline":"","flightNo":"","departAirport":"","arriveAirport":"","departTerminal":"","arriveTerminal":"","departDate":"","departTime":"","arriveTime":"","seatClass":"","ticketPrice":"","ticketStatus":"","bookingNo":"","passengerName":"","baggageInfo":"","note":""}
        """
        let raw = try await DeepSeekService.shared.sendMessage(systemPrompt: flightSystemPrompt, userPrompt: userPrompt)
        return decodeFlightFields(extractJSON(raw))
    }

    private func extractJSON(_ text: String) -> String {
        var s = text
        if let r1 = s.range(of: "```json"), let r2 = s.range(of: "```", range: r1.upperBound..<s.endIndex) {
            s = String(s[r1.upperBound..<r2.lowerBound])
        } else if let start = s.firstIndex(of: "{"), let end = s.lastIndex(of: "}") {
            s = String(s[start...end])
        }
        return s.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func decodeTrainFields(_ json: String) -> TrainTicketFields {
        guard let data = json.data(using: .utf8),
              let raw = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return TrainTicketFields()
        }
        func str(_ key: String) -> String {
            guard let v = raw[key], !(v is NSNull) else { return "" }
            let s = "\(v)"
            return s == "<null>" ? "" : s
        }
        var f = TrainTicketFields()
        f.trainNo       = str("trainNo")
        f.departStation = str("departStation")
        f.arriveStation = str("arriveStation")
        f.departDate    = str("departDate")
        f.departTime    = normalizeTime(str("departTime"))
        f.arriveTime    = normalizeTime(str("arriveTime"))
        f.seatType      = str("seatType")
        f.carriageNo    = str("carriageNo")
        f.seatNo        = str("seatNo")
        f.ticketPrice   = str("ticketPrice")
        f.ticketStatus  = str("ticketStatus")
        f.checkInGate   = str("checkInGate")
        f.passengerName = str("passengerName")
        f.note          = str("note")
        return f
    }

    private func decodeFlightFields(_ json: String) -> FlightTicketFields {
        guard let data = json.data(using: .utf8),
              let raw = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return FlightTicketFields()
        }
        func str(_ key: String) -> String {
            guard let v = raw[key], !(v is NSNull) else { return "" }
            let s = "\(v)"
            return s == "<null>" ? "" : s
        }
        var f = FlightTicketFields()
        f.airline         = str("airline")
        f.flightNo        = str("flightNo")
        f.departAirport   = str("departAirport")
        f.arriveAirport   = str("arriveAirport")
        f.departTerminal  = str("departTerminal")
        f.arriveTerminal  = str("arriveTerminal")
        f.departDate      = str("departDate")
        f.departTime      = normalizeTime(str("departTime"))
        f.arriveTime      = normalizeTime(str("arriveTime"))
        f.seatClass       = str("seatClass")
        f.ticketPrice     = str("ticketPrice")
        f.ticketStatus    = str("ticketStatus")
        f.bookingNo       = str("bookingNo")
        f.passengerName   = str("passengerName")
        f.baggageInfo     = str("baggageInfo")
        f.note            = str("note")
        return f
    }

    // Normalize time strings: "08：30" → "08:30", "0830" → "08:30"
    private func normalizeTime(_ s: String) -> String {
        if s.isEmpty { return s }
        // Replace Chinese full-width colon
        var t = s.replacingOccurrences(of: "：", with: ":")
        // If it's 4 digits like "0830", convert to "08:30"
        let digits = t.filter { $0.isNumber }
        if !t.contains(":") && digits.count == 4 {
            t = "\(digits.prefix(2)):\(digits.suffix(2))"
        }
        return t
    }
}
