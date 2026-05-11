import SwiftUI
import SwiftData

struct ExpenseListView: View {
    @Environment(\.modelContext) private var modelContext
    var trip: Trip? = nil
    @State private var viewModel: ExpenseViewModel?
    @State private var showAdd = false
    @State private var showVoice = false
    @State private var showSummary = false
    @State private var editingExpense: ExpenseRecord?

    var body: some View {
        content
            .onAppear {
                if viewModel == nil {
                    let vm = ExpenseViewModel(trip: trip, context: modelContext)
                    vm.load()
                    viewModel = vm
                }
            }
    }

    private var content: some View {
        Group {
            if let vm = viewModel {
                if vm.expenses.isEmpty {
                    emptyState()
                } else {
                    expenseList(vm: vm)
                }
            } else {
                ProgressView()
            }
        }
        .navigationTitle(trip == nil ? "记账" : "花费")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack {
                    if viewModel?.expenses.isEmpty == false {
                        Button {
                            showSummary = true
                        } label: {
                            Image(systemName: "chart.bar.xaxis")
                        }
                    }
                    Button { showVoice = true } label: {
                        Image(systemName: "mic.fill")
                    }
                    Button { showAdd = true } label: {
                        Image(systemName: "plus")
                    }
                }
            }
        }
        .sheet(isPresented: $showAdd) {
            ExpenseFormView(expense: nil) { record in
                viewModel?.save(record)
            }
        }
        .sheet(isPresented: $showVoice) {
            VoiceExpenseView { records in
                viewModel?.saveAll(records)
            }
        }
        .sheet(isPresented: $showSummary) {
            if let vm = viewModel {
                NavigationStack {
                    ExpenseSummaryView(summary: vm.summaryByCategory, total: vm.totalAmount)
                        .toolbar {
                            ToolbarItem(placement: .confirmationAction) {
                                Button("完成") { showSummary = false }
                            }
                        }
                }
            }
        }
        .sheet(item: $editingExpense) { expense in
            ExpenseFormView(expense: expense) { _ in
                viewModel?.load()
            }
        }
    }

    private func emptyState() -> some View {
        VStack(spacing: 16) {
            ContentUnavailableView(
                "暂无花费记录",
                systemImage: "yensign.circle",
                description: Text("点击 + 手动添加，或点击麦克风语音记账")
            )
            FloatingVoiceButton { showVoice = true }
        }
        .background(AppColors.background)
    }

    private func expenseList(vm: ExpenseViewModel) -> some View {
        ZStack(alignment: .bottomTrailing) {
            List {
                Section {
                    HStack {
                        Text("合计")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(vm.totalAmount.currencyString)
                            .font(.headline)
                            .foregroundStyle(AppColors.accent)
                    }
                }

                ForEach(vm.byDate, id: \.0) { date, records in
                    Section(date) {
                        ForEach(records) { record in
                            ExpenseRowView(record: record)
                                .contentShape(Rectangle())
                                .onTapGesture { editingExpense = record }
                        }
                        .onDelete { indexSet in
                            indexSet.forEach { vm.delete(records[$0]) }
                        }
                    }
                }
            }
            .background(AppColors.background)

            FloatingVoiceButton { showVoice = true }
                .padding(20)
        }
    }
}

private struct ExpenseRowView: View {
    let record: ExpenseRecord

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: record.category.icon)
                .font(.system(size: 18))
                .foregroundStyle(AppColors.primary)
                .frame(width: 36, height: 36)
                .background(AppColors.primary.opacity(0.1))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(record.title)
                    .font(.subheadline)
                HStack(spacing: 6) {
                    Text(record.category.rawValue)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if let method = record.paymentMethod {
                        Text("·")
                            .foregroundStyle(.secondary)
                        Text(method.rawValue)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    if record.source == .voice {
                        Image(systemName: "mic.fill")
                            .font(.caption2)
                            .foregroundStyle(AppColors.accent.opacity(0.7))
                    }
                }
            }

            Spacer()

            Text(record.amount.currencyString)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppColors.accent)
        }
    }
}
