import SwiftUI
import SwiftData

struct ChecklistView: View {
    @Environment(\.modelContext) private var modelContext
    var trip: Trip? = nil
    @State private var viewModel: ChecklistViewModel?
    @State private var showAdd = false
    @State private var editingItem: ChecklistItem?

    var body: some View {
        Group {
            if let vm = viewModel {
                if vm.items.isEmpty {
                    emptyState(vm: vm)
                } else {
                    checklistContent(vm: vm)
                }
            } else {
                ProgressView()
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button { showAdd = true } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showAdd) {
            ChecklistItemFormView(item: nil) { item in
                viewModel?.add(item)
            }
        }
        .sheet(item: $editingItem) { item in
            ChecklistItemFormView(item: item) { _ in
                viewModel?.update(item)
            }
        }
        .onAppear {
            if viewModel == nil {
                let vm = ChecklistViewModel(trip: trip, context: modelContext)
                vm.load()
                viewModel = vm
            }
        }
    }

    private func emptyState(vm: ChecklistViewModel) -> some View {
        VStack(spacing: 16) {
            ContentUnavailableView(
                "清单为空",
                systemImage: "checklist",
                description: Text(trip != nil ? "点击 + 添加行程清单项" : "点击 + 添加待办事项")
            )
            if trip != nil {
                Button("插入默认模板（12项）") {
                    if let t = trip { vm.insertDefaults(for: t) }
                }
                .buttonStyle(.borderedProminent)
                .tint(AppColors.primary)
            }
        }
        .background(AppColors.background)
    }

    private func checklistContent(vm: ChecklistViewModel) -> some View {
        List {
            ForEach(vm.grouped, id: \.0) { category, items in
                Section {
                    ForEach(items) { item in
                        ChecklistRowView(item: item) {
                            vm.toggle(item)
                        } onEdit: {
                            editingItem = item
                        } onDelete: {
                            vm.delete(item)
                        }
                    }
                } header: {
                    Label(category.rawValue, systemImage: category.icon)
                }
            }
        }
        .background(AppColors.background)
    }
}

private struct ChecklistRowView: View {
    let item: ChecklistItem
    let onToggle: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onToggle) {
                Image(systemName: item.isDone ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundStyle(item.isDone ? .green : .secondary)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .strikethrough(item.isDone, color: .secondary)
                    .foregroundStyle(item.isDone ? .secondary : .primary)
                if let due = item.dueDate {
                    Text(due, style: .date)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
        }
        .padding(.vertical, 2)
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive, action: onDelete) {
                Label("删除", systemImage: "trash")
            }
        }
        .swipeActions(edge: .leading, allowsFullSwipe: false) {
            Button(action: onEdit) {
                Label("编辑", systemImage: "pencil")
            }
            .tint(.blue)
        }
    }
}
