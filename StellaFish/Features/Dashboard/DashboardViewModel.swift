import Foundation
import Observation

@Observable
final class DashboardViewModel {
    private(set) var currentTrip: Trip?
    private(set) var upcomingTrips: [Trip] = []
    private(set) var totalExpenses: Double = 0
    private(set) var pendingChecklistCount: Int = 0
    private(set) var nextReminderTask: TransportTask?

    private let tripRepo: TripRepositoryProtocol

    init(tripRepo: TripRepositoryProtocol) {
        self.tripRepo = tripRepo
    }

    func load() {
        guard let trips = try? tripRepo.fetchAll() else { return }
        let now = Date()

        currentTrip = trips.first { $0.departDate <= now && $0.returnDate >= now }
        upcomingTrips = trips
            .filter { $0.departDate > now }
            .sorted { $0.departDate < $1.departDate }

        let featured = currentTrip ?? upcomingTrips.first
        totalExpenses = featured?.totalExpenses ?? 0
        pendingChecklistCount = featured?.pendingChecklistCount ?? 0

        nextReminderTask = featured?.transportTasks
            .compactMap { task -> (TransportTask, Date)? in
                guard let d = task.nextReminderAt, d > now else { return nil }
                return (task, d)
            }
            .min { $0.1 < $1.1 }
            .map { $0.0 }
    }
}
