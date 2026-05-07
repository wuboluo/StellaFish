import Foundation

protocol TripRepositoryProtocol {
    func fetchAll() throws -> [Trip]
    func save(_ trip: Trip) throws
    func delete(_ trip: Trip) throws
}
