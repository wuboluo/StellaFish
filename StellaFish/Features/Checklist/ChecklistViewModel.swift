import Foundation
import SwiftData
import Observation

@Observable
final class ChecklistViewModel {
    private(set) var items: [ChecklistItem] = []
    private let context: ModelContext
    let trip: Trip?

    init(trip: Trip?, context: ModelContext) {
        self.trip = trip
        self.context = context
    }

    func load() {
        if let trip {
            items = trip.checklistItems.sorted { $0.sortOrder < $1.sortOrder }
        } else {
            let descriptor = FetchDescriptor<ChecklistItem>(
                predicate: #Predicate { $0.trip == nil },
                sortBy: [SortDescriptor(\.sortOrder)]
            )
            items = (try? context.fetch(descriptor)) ?? []
        }
    }

    var grouped: [(ChecklistCategory, [ChecklistItem])] {
        let order = ChecklistCategory.allCases
        return order.compactMap { category in
            let group = items.filter { $0.category == category }
            return group.isEmpty ? nil : (category, group)
        }
    }

    func toggle(_ item: ChecklistItem) {
        item.isDone.toggle()
        item.updatedAt = Date()
        try? context.save()
    }

    func add(_ item: ChecklistItem) {
        item.trip = trip
        item.sortOrder = items.count
        context.insert(item)
        try? context.save()
        load()
    }

    func update(_ item: ChecklistItem) {
        item.updatedAt = Date()
        try? context.save()
        load()
    }

    func delete(_ item: ChecklistItem) {
        context.delete(item)
        try? context.save()
        load()
    }

    func move(from source: IndexSet, to destination: Int, in category: ChecklistCategory) {
        var group = items.filter { $0.category == category }
        group.move(fromOffsets: source, toOffset: destination)
        for (i, item) in group.enumerated() {
            item.sortOrder = i
        }
        try? context.save()
        load()
    }

    func insertDefaults(for trip: Trip) {
        let defaults = ChecklistItem.defaultItems(for: trip)
        defaults.forEach { context.insert($0) }
        try? context.save()
        load()
    }
}
