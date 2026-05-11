import SwiftUI

struct TransportTaskDetailView: View {
    let task: TransportTask
    var vm: TransportViewModel
    @State private var showAddSnapshot = false
    @State private var showComparison = false

    var body: some View {
        List {
            // Task summary
            Section {
                taskInfoRow("出发地", value: task.fromPlace)
                taskInfoRow("目的地", value: task.toPlace)
                taskInfoRow("日期", value: task.date.shortDateLabel)
                taskInfoRow("交通方式", value: task.transportTypes.map(\.rawValue).joined(separator: "、"))
                if task.targetPrice > 0 {
                    taskInfoRow("目标价格", value: task.targetPrice.currencyString + "/人")
                }
            } header: {
                Text("任务信息")
            }

            // Snapshots
            Section {
                if task.snapshots.isEmpty {
                    Text("暂无快照，点击右上角 + 添加")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .listRowBackground(Color.clear)
                } else {
                    ForEach(task.snapshots.sorted { $0.createdAt < $1.createdAt }) { snapshot in
                        NavigationLink {
                            TicketSnapshotFormView(
                                snapshot: snapshot,
                                trip: task.trip
                            ) { updated in
                                vm.load()
                            }
                        } label: {
                            SnapshotRowView(snapshot: snapshot, trip: task.trip)
                        }
                    }
                    .onDelete { indexSet in
                        let sorted = task.snapshots.sorted { $0.createdAt < $1.createdAt }
                        indexSet.forEach { vm.deleteSnapshot(sorted[$0]) }
                    }
                }
            } header: {
                HStack {
                    Text("票价快照")
                    Spacer()
                    if task.snapshots.count >= 2 {
                        Button("比较") { showComparison = true }
                            .font(.caption)
                    }
                }
            }
        }
        .navigationTitle(task.title)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button { showAddSnapshot = true } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showAddSnapshot) {
            TicketSnapshotFormView(snapshot: nil, trip: task.trip) { snapshot in
                vm.addSnapshot(snapshot, to: task)
            }
        }
        .sheet(isPresented: $showComparison) {
            CostComparisonView(snapshots: task.snapshots, trip: task.trip)
        }
    }

    private func taskInfoRow(_ label: String, value: String) -> some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value.isEmpty ? "—" : value)
                .foregroundStyle(.primary)
        }
    }
}

private struct SnapshotRowView: View {
    let snapshot: TicketSnapshot
    let trip: Trip?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(snapshot.code.isEmpty ? snapshot.transportType.rawValue : "\(snapshot.transportType.rawValue) \(snapshot.code)")
                    .font(.headline)
                Spacer()
                seatStatusBadge
            }
            HStack {
                Text(snapshot.fromStation.isEmpty ? "—" : snapshot.fromStation)
                Image(systemName: "arrow.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(snapshot.toStation.isEmpty ? "—" : snapshot.toStation)
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
            HStack {
                Text(snapshot.price.currencyString + "/人")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppColors.accent)
                Spacer()
                if let trip {
                    let total = snapshot.totalCost(people: trip.peopleCount, timeValuePerHour: trip.timeValuePerHour)
                    if total.isFinite {
                        Text("综合 \(total.currencyShortString)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Text(snapshot.platform)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    private var seatStatusBadge: some View {
        let color: Color = switch snapshot.seatStatus {
        case .available: .green
        case .scarce: .orange
        case .waitlist: .yellow
        case .noTicket: .red
        case .notChecked: .secondary
        }
        return Text(snapshot.seatStatus.rawValue)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(color)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.15))
            .clipShape(Capsule())
    }
}
