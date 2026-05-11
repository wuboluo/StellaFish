import SwiftUI
import SwiftData

struct PackingTemplateView: View {
    @Environment(\.modelContext) private var ctx
    @Query(sort: \PackingTemplateItem.sortOrder) private var templates: [PackingTemplateItem]
    @State private var showAdd = false
    @State private var editingItem: PackingTemplateItem? = nil

    private var grouped: [(String, [PackingTemplateItem])] {
        let cats = PackingTemplateItem.categoryOrder
        let dict = Dictionary(grouping: templates) { $0.category }
        var result: [(String, [PackingTemplateItem])] = []
        for cat in cats {
            if let g = dict[cat], !g.isEmpty { result.append((cat, g.sorted { $0.sortOrder < $1.sortOrder })) }
        }
        let known = Set(cats)
        for (cat, g) in dict where !known.contains(cat) && !g.isEmpty {
            result.append((cat, g.sorted { $0.sortOrder < $1.sortOrder }))
        }
        return result
    }

    var body: some View {
        List {
            if templates.isEmpty {
                Section {
                    VStack(spacing: 12) {
                        Text("模板为空").foregroundStyle(.secondary)
                        Button("恢复默认模板") { resetToDefault() }
                            .buttonStyle(.borderedProminent).tint(AppColors.primary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .listRowBackground(Color.clear)
                }
            } else {
                ForEach(grouped, id: \.0) { cat, items in
                    Section(cat) {
                        ForEach(items) { item in
                            HStack {
                                Circle()
                                    .fill(tagColor(item.colorTag))
                                    .frame(width: 8, height: 8)
                                Text(item.title).font(.subheadline)
                                Spacer()
                                Button { editingItem = item } label: {
                                    Image(systemName: "pencil").foregroundStyle(.secondary)
                                }
                                .buttonStyle(.plain)
                            }
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) { ctx.delete(item); try? ctx.save() } label: {
                                    Label("删除", systemImage: "trash")
                                }
                            }
                        }
                    }
                }

                Section {
                    Button("恢复默认模板", role: .destructive) { resetToDefault() }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("默认清单模板")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button { showAdd = true } label: { Image(systemName: "plus") }
            }
        }
        .sheet(isPresented: $showAdd) {
            TemplateItemFormView(item: nil) { newItem in ctx.insert(newItem); try? ctx.save() }
        }
        .sheet(item: $editingItem) { item in
            TemplateItemFormView(item: item) { _ in try? ctx.save() }
        }
    }

    private func tagColor(_ tag: String) -> Color {
        switch tag {
        case "blue":  return AppColors.primary
        case "green": return .green
        case "red":   return .red
        default:      return Color(.systemGray4)
        }
    }

    private func resetToDefault() {
        templates.forEach { ctx.delete($0) }
        for (i, item) in PackingTemplateItem.defaultItems.enumerated() {
            ctx.insert(PackingTemplateItem(title: item.title, category: item.category,
                                          colorTag: item.colorTag, sortOrder: i))
        }
        try? ctx.save()
    }
}

private struct TemplateItemFormView: View {
    @Environment(\.dismiss) private var dismiss
    let item: PackingTemplateItem?
    let onSave: (PackingTemplateItem) -> Void

    @State private var title = ""
    @State private var category = "证件与重要物品"
    @State private var colorTag = "blue"

    private let categories = PackingTemplateItem.categoryOrder + ["其他"]
    private let tags = [("蓝色（默认必带）", "blue"), ("绿色", "green"), ("红色（重要）", "red"), ("灰色（可选）", "gray")]

    var body: some View {
        NavigationStack {
            Form {
                Section("名称") { TextField("例如：驾驶证", text: $title) }
                Section("分类") {
                    Picker("分类", selection: $category) {
                        ForEach(categories, id: \.self) { Text($0) }
                    }.pickerStyle(.menu)
                }
                Section("颜色标签") {
                    Picker("颜色", selection: $colorTag) {
                        ForEach(tags, id: \.1) { label, val in Text(label).tag(val) }
                    }.pickerStyle(.menu)
                }
            }
            .navigationTitle(item == nil ? "新增模板项" : "编辑模板项")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("取消") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        let t = item ?? PackingTemplateItem(title: title, category: category, colorTag: colorTag)
                        t.title = title; t.category = category; t.colorTag = colorTag; t.updatedAt = Date()
                        onSave(t); dismiss()
                    }.disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear {
                if let item { title = item.title; category = item.category; colorTag = item.colorTag }
            }
        }
    }
}
