import Foundation
import SwiftData

@Model
final class Trip {
    var id: UUID
    var title: String
    var fromCity: String
    var toCity: String
    var departDate: Date
    var returnDate: Date
    var peopleCount: Int
    var timeValuePerHour: Double
    var preference: String
    var note: String
    var createdAt: Date
    var updatedAt: Date

    @Relationship(deleteRule: .cascade, inverse: \TransportTask.trip)
    var transportTasks: [TransportTask]

    @Relationship(deleteRule: .cascade, inverse: \HotelCandidate.trip)
    var hotelCandidates: [HotelCandidate]

    @Relationship(deleteRule: .cascade, inverse: \ChecklistItem.trip)
    var checklistItems: [ChecklistItem]

    @Relationship(deleteRule: .cascade, inverse: \ExpenseRecord.trip)
    var expenses: [ExpenseRecord]

    @Relationship(deleteRule: .cascade, inverse: \PackingItem.trip)
    var packingItems: [PackingItem] = []

    @Relationship(deleteRule: .cascade, inverse: \TrainTicketRecord.trip)
    var trainTickets: [TrainTicketRecord] = []

    @Relationship(deleteRule: .cascade, inverse: \FlightTicketRecord.trip)
    var flightTickets: [FlightTicketRecord] = []

    @Relationship(deleteRule: .cascade, inverse: \ReminderItem.trip)
    var reminders: [ReminderItem] = []

    @Relationship(deleteRule: .cascade, inverse: \MetroRecord.trip)
    var metroRoutes: [MetroRecord] = []

    @Relationship(deleteRule: .cascade, inverse: \PlaceRecord.trip)
    var places: [PlaceRecord] = []

    var startDate: Date { departDate }
    var endDate: Date { returnDate }

    var ticketCount: Int { trainTickets.count + flightTickets.count + metroRoutes.count }

    var pendingReminderCount: Int {
        reminders.filter { !$0.isDone && $0.remindAt > Date() }.count
    }

    var nextReminder: ReminderItem? {
        reminders.filter { !$0.isDone && $0.remindAt > Date() }
            .min { $0.remindAt < $1.remindAt }
    }

    var packingCompletedCount: Int { packingItems.filter { $0.isDone }.count }
    var packingTotalCount: Int { packingItems.count }

    init(
        title: String,
        fromCity: String = "",
        toCity: String = "",
        departDate: Date = Date(),
        returnDate: Date = Calendar.current.date(byAdding: .day, value: 3, to: Date()) ?? Date(),
        peopleCount: Int = 1,
        timeValuePerHour: Double = 50,
        preference: TripPreference = .balanced,
        note: String = ""
    ) {
        self.id = UUID()
        self.title = title
        self.fromCity = fromCity
        self.toCity = toCity
        self.departDate = departDate
        self.returnDate = returnDate
        self.peopleCount = peopleCount
        self.timeValuePerHour = timeValuePerHour
        self.preference = preference.rawValue
        self.note = note
        self.createdAt = Date()
        self.updatedAt = Date()
        self.transportTasks = []
        self.hotelCandidates = []
        self.checklistItems = []
        self.expenses = []
    }

    var tripPreference: TripPreference {
        get { TripPreference(rawValue: preference) ?? .balanced }
        set { preference = newValue.rawValue }
    }

    var totalExpenses: Double {
        expenses.reduce(0) { $0 + $1.amount }
    }

    var pendingChecklistCount: Int {
        checklistItems.filter { !$0.isDone }.count
    }

    var durationDays: Int {
        Calendar.current.dateComponents([.day], from: departDate, to: returnDate).day ?? 0
    }
}
