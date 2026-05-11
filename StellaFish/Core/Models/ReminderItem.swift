import Foundation
import SwiftData

@Model
final class ReminderItem {
    var id: UUID
    var trip: Trip?
    var title: String
    var remindAt: Date
    var note: String
    var isDone: Bool
    var priority: String      // normal / important
    var notificationId: String
    var createdAt: Date
    var updatedAt: Date

    init(title: String, remindAt: Date = Date(), note: String = "", priority: String = "normal") {
        self.id = UUID()
        self.title = title
        self.remindAt = remindAt
        self.note = note
        self.isDone = false
        self.priority = priority
        self.notificationId = UUID().uuidString
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}
