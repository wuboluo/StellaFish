import SwiftUI
import SwiftData
import UserNotifications

@main
struct StellaFishApp: App {
    let container: ModelContainer
    @State private var appState = AppState()

    init() {
        do {
            container = try ModelContainer(for:
                Trip.self,
                TransportTask.self,
                TicketSnapshot.self,
                HotelCandidate.self,
                ChecklistItem.self,
                ExpenseRecord.self,
                PackingTemplateItem.self,
                PackingItem.self,
                TrainTicketRecord.self,
                FlightTicketRecord.self,
                ReminderItem.self,
                MetroRecord.self,
                PlaceRecord.self
            )
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
        UNUserNotificationCenter.current().delegate = NotificationService.shared
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(container)
                .environment(appState)
                .task {
                    await NotificationService.shared.requestAuthorization()
                }
        }
    }
}
