import SwiftUI
import SwiftData

@main
struct StellaFishApp: App {
    let container: ModelContainer

    init() {
        do {
            container = try ModelContainer(for:
                Trip.self,
                TransportTask.self,
                TicketSnapshot.self,
                HotelCandidate.self,
                ChecklistItem.self,
                ExpenseRecord.self
            )
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(container)
        }
    }
}
