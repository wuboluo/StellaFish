import Foundation
import SwiftData

@Model
final class PackingItem {
    var id: UUID
    var trip: Trip?
    var title: String
    var category: String
    var colorTag: String      // blue / green / red / gray
    var isFromDefault: Bool
    var isDone: Bool
    var isImportant: Bool
    var note: String
    var sortOrder: Int
    var createdAt: Date
    var updatedAt: Date

    init(title: String, category: String, colorTag: String = "gray",
         isFromDefault: Bool = false, sortOrder: Int = 0,
         isImportant: Bool = false, note: String = "") {
        self.id = UUID()
        self.title = title
        self.category = category
        self.colorTag = colorTag
        self.isFromDefault = isFromDefault
        self.isDone = false
        self.isImportant = isImportant
        self.note = note
        self.sortOrder = sortOrder
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}
