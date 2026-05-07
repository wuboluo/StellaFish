import Foundation

protocol ExpenseRepositoryProtocol {
    func fetchAll(tripId: UUID?) throws -> [ExpenseRecord]
    func save(_ expense: ExpenseRecord) throws
    func delete(_ expense: ExpenseRecord) throws
    func totalAmount(tripId: UUID?) throws -> Double
    func summaryByCategory(tripId: UUID?) throws -> [ExpenseCategory: Double]
}
