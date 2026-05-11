import Foundation
import SwiftData
import Observation

@Observable
final class TransportViewModel {
    private(set) var tasks: [TransportTask] = []
    private let context: ModelContext
    let trip: Trip

    init(trip: Trip, context: ModelContext) {
        self.trip = trip
        self.context = context
    }

    func load() {
        tasks = trip.transportTasks.sorted { $0.date < $1.date }
    }

    func addTask(_ task: TransportTask) {
        task.trip = trip
        context.insert(task)
        try? context.save()
        load()
    }

    func deleteTask(_ task: TransportTask) {
        context.delete(task)
        try? context.save()
        load()
    }

    func addSnapshot(_ snapshot: TicketSnapshot, to task: TransportTask) {
        snapshot.task = task
        context.insert(snapshot)
        try? context.save()
        load()
    }

    func deleteSnapshot(_ snapshot: TicketSnapshot) {
        context.delete(snapshot)
        try? context.save()
        load()
    }
}
