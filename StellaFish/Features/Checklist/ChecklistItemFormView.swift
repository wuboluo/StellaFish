import SwiftUI

struct ChecklistItemFormView: View {
    @Environment(\.dismiss) private var dismiss
    var item: ChecklistItem?
    var onSave: (ChecklistItem) -> Void

    @State private var title = ""
    @State private var category: ChecklistCategory = .other
    @State private var note = ""
    @State private var dueDate: Date = Date()
    @State private var hasDueDate = false

    private var isEditing: Bool { item != nil }

    var body: some View {
        NavigationStack {
            Form {
                Section("清单项") {
                    TextField("事项名称", text: $title)
                    Picker("分类", selection: $category) {
                        ForEach(ChecklistCategory.allCases, id: \.self) { cat in
                            Label(cat.rawValue, systemImage: cat.icon).tag(cat)
                        }
                    }
                }
                Section("提醒日期（可选）") {
                    Toggle("设置提醒日期", isOn: $hasDueDate)
                    if hasDueDate {
                        DatePicker("日期", selection: $dueDate, displayedComponents: [.date])
                    }
                }
                Section("备注") {
                    TextField("可选", text: $note, axis: .vertical)
                        .lineLimit(2...4)
                }
            }
            .navigationTitle(isEditing ? "编辑清单项" : "添加清单项")
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
        .onAppear { populateIfEditing() }
    }

    private func populateIfEditing() {
        guard let i = item else { return }
        title = i.title
        category = i.category
        note = i.note
        if let d = i.dueDate {
            hasDueDate = true
            dueDate = d
        }
    }

    private func save() {
        if let existing = item {
            existing.title = title.trimmingCharacters(in: .whitespaces)
            existing.category = category
            existing.note = note
            existing.dueDate = hasDueDate ? dueDate : nil
            onSave(existing)
        } else {
            let newItem = ChecklistItem(
                title: title.trimmingCharacters(in: .whitespaces),
                category: category,
                note: note,
                dueDate: hasDueDate ? dueDate : nil
            )
            onSave(newItem)
        }
        dismiss()
    }
}
