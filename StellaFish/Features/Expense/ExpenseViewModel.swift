import Foundation
import SwiftData
import Observation

@Observable
final class ExpenseViewModel {
    private(set) var expenses: [ExpenseRecord] = []
    private let context: ModelContext
    let trip: Trip?

    init(trip: Trip?, context: ModelContext) {
        self.trip = trip
        self.context = context
    }

    func load() {
        if let trip {
            expenses = trip.expenses.sorted { $0.createdAt > $1.createdAt }
        } else {
            let descriptor = FetchDescriptor<ExpenseRecord>(
                sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
            )
            expenses = (try? context.fetch(descriptor)) ?? []
        }
    }

    func save(_ expense: ExpenseRecord) {
        expense.trip = trip
        context.insert(expense)
        try? context.save()
        load()
    }

    func saveAll(_ records: [ExpenseRecord]) {
        records.forEach { r in
            r.trip = trip
            context.insert(r)
        }
        try? context.save()
        load()
    }

    func delete(_ expense: ExpenseRecord) {
        context.delete(expense)
        try? context.save()
        load()
    }

    var totalAmount: Double {
        expenses.reduce(0) { $0 + $1.amount }
    }

    var byDate: [(String, [ExpenseRecord])] {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "M月d日 EEEE"
        let dict = Dictionary(grouping: expenses) { formatter.string(from: $0.createdAt) }
        return dict.keys.sorted(by: >).map { key in (key, dict[key]!.sorted { $0.createdAt > $1.createdAt }) }
    }

    var summaryByCategory: [(ExpenseCategory, Double)] {
        let dict = Dictionary(grouping: expenses, by: \.category)
            .mapValues { $0.reduce(0) { $0 + $1.amount } }
        return dict.sorted { $0.value > $1.value }
    }
}
