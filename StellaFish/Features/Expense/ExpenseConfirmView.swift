import SwiftUI

struct ExpenseConfirmView: View {
    @Environment(\.dismiss) private var dismiss
    var parsed: [ParsedExpense]
    var onConfirm: ([ExpenseRecord]) -> Void

    @State private var items: [EditableExpense] = []

    struct EditableExpense: Identifiable {
        let id = UUID()
        var title: String
        var amountText: String
        var category: ExpenseCategory
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("请确认或修改每条记录，金额为 0 的条目将被跳过。")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                ForEach($items) { $item in
                    VStack(alignment: .leading, spacing: 8) {
                        TextField("事项名称", text: $item.title)
                            .font(.headline)
                        HStack {
                            Text("¥")
                                .foregroundStyle(.secondary)
                            TextField("0.00", text: $item.amountText)
                                .keyboardType(.decimalPad)
                            Spacer()
                            Picker("分类", selection: $item.category) {
                                ForEach(ExpenseCategory.allCases, id: \.self) { cat in
                                    Text(cat.rawValue).tag(cat)
                                }
                            }
                            .labelsHidden()
                            .pickerStyle(.menu)
                        }
                    }
                    .padding(.vertical, 4)
                }
                .onDelete { items.remove(atOffsets: $0) }
            }
            .navigationTitle("确认记账")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("返回") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存全部") { confirm() }
                }
            }
        }
        .onAppear {
            items = parsed.map { p in
                EditableExpense(
                    title: p.title,
                    amountText: p.amount > 0 ? String(format: "%.2f", p.amount) : "",
                    category: p.category
                )
            }
        }
    }

    private func confirm() {
        let records = items.compactMap { item -> ExpenseRecord? in
            guard let amount = Double(item.amountText), amount > 0 else { return nil }
            return ExpenseRecord(
                title: item.title.trimmingCharacters(in: .whitespaces),
                amount: amount,
                category: item.category,
                source: .voice
            )
        }
        onConfirm(records)
        dismiss()
    }
}
