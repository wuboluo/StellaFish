import Foundation
import SwiftData

@Model
final class PlaceRecord {
    var id: UUID
    var trip: Trip?
    var title: String         // 地点名称
    var category: String      // 酒店/车站/机场/景点/餐厅/集合点/其他
    var address: String       // 详细地址
    var phone: String         // 可选电话
    var note: String          // 备注
    var createdAt: Date
    var updatedAt: Date

    static let categories = ["酒店", "车站", "机场", "景点", "餐厅", "集合点", "其他"]

    init(title: String = "", category: String = "其他") {
        self.id = UUID()
        self.title = title
        self.category = category
        self.address = ""
        self.phone = ""
        self.note = ""
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}
