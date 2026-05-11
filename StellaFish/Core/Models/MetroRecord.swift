import Foundation
import SwiftData

@Model
final class MetroRecord {
    var id: UUID
    var trip: Trip?
    var title: String           // 酒店 → 成都东站
    var city: String            // 可选城市
    var fromStation: String
    var toStation: String
    var lineInfo: String        // 2号线 → 7号线
    var direction: String       // 往龙泉驿方向
    var transferInfo: String    // 换乘信息
    var exitInfo: String        // A口出
    var estimatedDuration: String // 约42分钟
    var note: String            // 完整路线步骤（多行）
    var createdAt: Date
    var updatedAt: Date

    init(title: String = "") {
        self.id = UUID()
        self.title = title
        self.city = ""
        self.fromStation = ""
        self.toStation = ""
        self.lineInfo = ""
        self.direction = ""
        self.transferInfo = ""
        self.exitInfo = ""
        self.estimatedDuration = ""
        self.note = ""
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}
