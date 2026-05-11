import Foundation

enum TripPreference: String, Codable, CaseIterable {
    case balanced = "balanced"
    case money = "money"
    case time = "time"
    case easy = "easy"

    var label: String {
        switch self {
        case .balanced: return "综合性价比"
        case .money: return "省钱优先"
        case .time: return "省时间优先"
        case .easy: return "少折腾优先"
        }
    }
}

enum TransportType: String, Codable, CaseIterable {
    case plane = "飞机"
    case highSpeedTrain = "高铁/动车"
    case bus = "汽车/大巴"
    case selfDrive = "自驾"
    case other = "其他"

    var defaultExtraMinutes: Int {
        switch self {
        case .plane: return 120
        case .highSpeedTrain: return 40
        case .bus: return 30
        case .selfDrive: return 0
        case .other: return 30
        }
    }

    var defaultRiskCost: Double {
        switch self {
        case .plane: return 50
        case .highSpeedTrain: return 10
        case .bus: return 40
        case .selfDrive: return 60
        case .other: return 20
        }
    }

    var defaultHassleCost: Double {
        switch self {
        case .plane: return 40
        case .highSpeedTrain: return 10
        case .bus: return 40
        case .selfDrive: return 80
        case .other: return 20
        }
    }

    var supportsStationPicker: Bool {
        self == .plane || self == .highSpeedTrain
    }
}

enum SeatStatus: String, Codable, CaseIterable {
    case notChecked = "未查询"
    case available = "充足"
    case scarce = "紧张"
    case waitlist = "候补"
    case noTicket = "无票"
}

enum ExpenseCategory: String, Codable, CaseIterable {
    case food = "餐饮"
    case transport = "交通"
    case accommodation = "住宿"
    case ticket = "门票"
    case shopping = "购物"
    case entertainment = "娱乐"
    case other = "其他"

    var icon: String {
        switch self {
        case .food: return "fork.knife"
        case .transport: return "tram.fill"
        case .accommodation: return "bed.double.fill"
        case .ticket: return "ticket.fill"
        case .shopping: return "bag.fill"
        case .entertainment: return "theatermasks.fill"
        case .other: return "ellipsis.circle.fill"
        }
    }
}

enum PaymentMethod: String, Codable, CaseIterable {
    case cash = "现金"
    case wechat = "微信"
    case alipay = "支付宝"
    case bankCard = "银行卡"
    case other = "其他"
}

enum ExpenseSource: String, Codable {
    case manual = "manual"
    case voice = "voice"
    case ai = "ai"
}

enum ChecklistCategory: String, Codable, CaseIterable {
    case document = "证件"
    case clothing = "衣物"
    case electronics = "数码"
    case medicine = "药品"
    case ticketing = "订票"
    case hotel = "酒店"
    case attraction = "景点"
    case other = "其他"

    var icon: String {
        switch self {
        case .document: return "creditcard.fill"
        case .clothing: return "tshirt.fill"
        case .electronics: return "iphone"
        case .medicine: return "pills.fill"
        case .ticketing: return "ticket.fill"
        case .hotel: return "building.2.fill"
        case .attraction: return "camera.fill"
        case .other: return "tag.fill"
        }
    }
}

enum BookingStatus: String, Codable, CaseIterable {
    case notBooked = "未预订"
    case booked = "已预订"
    case abandoned = "已放弃"
}

enum ReminderInterval: Int, CaseIterable {
    case fifteenMin = 15
    case thirtyMin = 30
    case oneHour = 60
    case threeHours = 180
    case daily = 1440

    var label: String {
        switch self {
        case .fifteenMin: return "15 分钟"
        case .thirtyMin: return "30 分钟"
        case .oneHour: return "1 小时"
        case .threeHours: return "3 小时"
        case .daily: return "每天"
        }
    }
}
