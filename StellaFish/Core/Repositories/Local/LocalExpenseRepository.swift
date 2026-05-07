import Foundation
import SwiftData

final class LocalExpenseRepository: ExpenseRepositoryProtocol {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func fetchAll(tripId: UUID?) throws -> [ExpenseRecord] {
        var descriptor = FetchDescriptor<ExpenseRecord>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        let records = try context.fetch(descriptor)
        if let tripId {
            return records.filter { $0.trip?.id == tripId }
        }
        return records
    }

    func save(_ expense: ExpenseRecord) throws {
        context.insert(expense)
        try context.save()
    }

    func delete(_ expense: ExpenseRecord) throws {
        context.delete(expense)
        try context.save()
    }

    func totalAmount(tripId: UUID?) throws -> Double {
        let records = try fetchAll(tripId: tripId)
        return records.reduce(0) { $0 + $1.amount }
    }

    func summaryByCategory(tripId: UUID?) throws -> [ExpenseCategory: Double] {
        let records = try fetchAll(tripId: tripId)
        return Dictionary(grouping: records, by: \.category)
            .mapValues { $0.reduce(0) { $0 + $1.amount } }
    }
}
