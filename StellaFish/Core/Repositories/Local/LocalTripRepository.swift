import Foundation
import SwiftData

final class LocalTripRepository: TripRepositoryProtocol {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func fetchAll() throws -> [Trip] {
        let descriptor = FetchDescriptor<Trip>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }

    func save(_ trip: Trip) throws {
        context.insert(trip)
        try context.save()
    }

    func delete(_ trip: Trip) throws {
        context.delete(trip)
        try context.save()
    }
}
