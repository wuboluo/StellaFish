import Foundation
import SwiftData

@Model
final class ChecklistItem {
    var id: UUID
    var trip: Trip?
    var title: String
    var categoryRaw: String
    var isDone: Bool
    var note: String
    var sortOrder: Int
    var dueDate: Date?
    var createdAt: Date
    var updatedAt: Date

    init(
        trip: Trip? = nil,
        title: String,
        category: ChecklistCategory = .other,
        isDone: Bool = false,
        note: String = "",
        sortOrder: Int = 0,
        dueDate: Date? = nil
    ) {
        self.id = UUID()
        self.trip = trip
        self.title = title
        self.categoryRaw = category.rawValue
        self.isDone = isDone
        self.note = note
        self.sortOrder = sortOrder
        self.dueDate = dueDate
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    var category: ChecklistCategory {
        get { ChecklistCategory(rawValue: categoryRaw) ?? .other }
        set { categoryRaw = newValue.rawValue }
    }
}

extension ChecklistItem {
    static func defaultItems(for trip: Trip) -> [ChecklistItem] {
        let templates: [(String, ChecklistCategory)] = [
            ("身份证", .document),
            ("手机", .electronics),
            ("充电器", .electronics),
            ("充电宝", .electronics),
            ("耳机", .electronics),
            ("换洗衣物", .clothing),
            ("雨伞", .clothing),
            ("常用药", .medicine),
            ("纸巾", .other),
            ("酒店确认", .hotel),
            ("去程票", .ticketing),
            ("返程票", .ticketing),
        ]
        return templates.enumerated().map { index, template in
            ChecklistItem(trip: trip, title: template.0, category: template.1, sortOrder: index)
        }
    }
}
