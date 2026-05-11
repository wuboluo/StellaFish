import Foundation
import SwiftData
import Observation

@Observable
final class HotelViewModel {
    private(set) var candidates: [HotelCandidate] = []
    private let context: ModelContext
    let trip: Trip

    init(trip: Trip, context: ModelContext) {
        self.trip = trip
        self.context = context
    }

    func load() {
        candidates = trip.hotelCandidates.sorted { $0.createdAt < $1.createdAt }
    }

    func save(_ candidate: HotelCandidate) {
        candidate.trip = trip
        context.insert(candidate)
        try? context.save()
        load()
    }

    func update() {
        try? context.save()
        load()
    }

    func delete(_ candidate: HotelCandidate) {
        context.delete(candidate)
        try? context.save()
        load()
    }

    var grouped: [(BookingStatus, [HotelCandidate])] {
        let order: [BookingStatus] = [.booked, .notBooked, .abandoned]
        return order.compactMap { status in
            let items = candidates.filter { $0.bookingStatus == status }
            return items.isEmpty ? nil : (status, items)
        }
    }
}
