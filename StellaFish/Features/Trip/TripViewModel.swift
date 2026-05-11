import Foundation
import Observation

@Observable
final class TripViewModel {
    private(set) var trips: [Trip] = []
    private let tripRepo: TripRepositoryProtocol

    init(tripRepo: TripRepositoryProtocol) {
        self.tripRepo = tripRepo
    }

    func load() {
        trips = (try? tripRepo.fetchAll()) ?? []
    }

    func save(_ trip: Trip) {
        try? tripRepo.save(trip)
        load()
    }

    func delete(_ trip: Trip) {
        try? tripRepo.delete(trip)
        load()
    }
}
