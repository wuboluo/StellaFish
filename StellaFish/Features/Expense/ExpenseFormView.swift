import SwiftUI

struct ExpenseFormView: View {
    @Environment(\.dismiss) private var dismiss
    var expense: ExpenseRecord?
    var onSave: (ExpenseRecord) -> Void

    @State private var title = ""
    @State private var amountText = ""
    @State private var category: ExpenseCategory = .other
    @State private var paymentMethod: PaymentMethod? = nil
    @State private var note = ""

    private var isEditing: Bool { expense != nil }
    private var canSave: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty && Double(amountText) != nil
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("金额") {
                    HStack {
                        Text("¥")
                            .foregroundStyle(.secondary)
                        TextField("0.00", text: $amountText)
                            .keyboardType(.decimalPad)
                    }
                    TextField("事项名称", text: $title)
                }
                Section("分类") {
                    Picker("分类", selection: $category) {
                        ForEach(ExpenseCategory.allCases, id: \.self) { cat in
                            Label(cat.rawValue, systemImage: cat.icon).tag(cat)
                        }
                    }
                }
                Section("支付方式（可选）") {
                    Picker("支付方式", selection: $paymentMethod) {
                        Text("未选择").tag(Optional<PaymentMethod>.none)
                        ForEach(PaymentMethod.allCases, id: \.self) { method in
                            Text(method.rawValue).tag(Optional(method))
                        }
                    }
                }
                Section("备注") {
                    TextField("可选", text: $note, axis: .vertical)
                        .lineLimit(2...3)
                }
            }
            .navigationTitle(isEditing ? "编辑花费" : "添加花费")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") { save() }
                        .disabled(!canSave)
                }
            }
        }
        .onAppear { populateIfEditing() }
    }

    private func populateIfEditing() {
        guard let e = expense else { return }
        title = e.title
        amountText = String(e.amount)
        category = e.category
        paymentMethod = e.paymentMethod
        note = e.note
    }

    private func save() {
        let amount = Double(amountText) ?? 0
        if let existing = expense {
            existing.title = title.trimmingCharacters(in: .whitespaces)
            existing.amount = amount
            existing.category = category
            existing.paymentMethod = paymentMethod
            existing.note = note
            existing.updatedAt = Date()
            onSave(existing)
        } else {
            let record = ExpenseRecord(
                title: title.trimmingCharacters(in: .whitespaces),
                amount: amount,
                category: category,
                paymentMethod: paymentMethod,
                note: note,
                source: .manual
            )
            onSave(record)
        }
        dismiss()
    }
}
