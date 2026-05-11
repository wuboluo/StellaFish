import SwiftUI
import SwiftData

struct TransportTaskListView: View {
    @Environment(\.modelContext) private var modelContext
    let trip: Trip
    @State private var viewModel: TransportViewModel?
    @State private var showAddTask = false

    var body: some View {
        Group {
            if let vm = viewModel {
                if vm.tasks.isEmpty {
                    emptyState()
                } else {
                    taskList(vm: vm)
                }
            } else {
                ProgressView()
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button { showAddTask = true } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showAddTask) {
            TransportTaskFormView { task in
                viewModel?.addTask(task)
            }
        }
        .onAppear {
            if viewModel == nil {
                let vm = TransportViewModel(trip: trip, context: modelContext)
                vm.load()
                viewModel = vm
            }
        }
    }

    private func emptyState() -> some View {
        ContentUnavailableView(
            "暂无交通任务",
            systemImage: "tram.fill",
            description: Text("点击 + 添加一个交通任务，开始比价")
        )
        .background(AppColors.background)
    }

    private func taskList(vm: TransportViewModel) -> some View {
        List {
            ForEach(vm.tasks) { task in
                NavigationLink {
                    TransportTaskDetailView(task: task, vm: vm)
                } label: {
                    TransportTaskRowView(task: task)
                }
                .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
            }
            .onDelete { indexSet in
                indexSet.forEach { vm.deleteTask(vm.tasks[$0]) }
            }
        }
        .listStyle(.plain)
        .background(AppColors.background)
    }
}

private struct TransportTaskRowView: View {
    let task: TransportTask

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(task.title)
                    .font(.headline)
                Spacer()
                Text(task.date, style: .date)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Text("\(task.fromPlace) → \(task.toPlace)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            HStack(spacing: 8) {
                Text(task.primaryTransportType.rawValue)
                    .font(.caption2.weight(.semibold))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(AppColors.primary.opacity(0.12))
                    .foregroundStyle(AppColors.primary)
                    .clipShape(Capsule())
                Spacer()
                Text("\(task.snapshots.count) 个快照")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(12)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 3, y: 1)
    }
}

// Inline form for creating a transport task
private struct TransportTaskFormView: View {
    @Environment(\.dismiss) private var dismiss
    var onSave: (TransportTask) -> Void

    @State private var title = ""
    @State private var fromPlace = ""
    @State private var toPlace = ""
    @State private var date = Date()
    @State private var selectedType: TransportType = .highSpeedTrain
    @State private var targetPrice = ""
    @State private var note = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("任务信息") {
                    TextField("任务名称（如：去程）", text: $title)
                    TextField("出发地", text: $fromPlace)
                    TextField("目的地", text: $toPlace)
                    DatePicker("出行日期", selection: $date, displayedComponents: .date)
                }
                Section("交通方式") {
                    Picker("交通方式", selection: $selectedType) {
                        ForEach(TransportType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                }
                Section("目标价格（可选）") {
                    TextField("¥ 每人", text: $targetPrice)
                        .keyboardType(.decimalPad)
                }
                Section("备注") {
                    TextField("可选", text: $note, axis: .vertical)
                        .lineLimit(2...4)
                }
            }
            .navigationTitle("新建交通任务")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") { save() }
                        .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func save() {
        let task = TransportTask(
            title: title.trimmingCharacters(in: .whitespaces),
            fromPlace: fromPlace,
            toPlace: toPlace,
            date: date,
            transportTypes: [selectedType],
            targetPrice: Double(targetPrice) ?? 0,
            note: note
        )
        onSave(task)
        dismiss()
    }
}
