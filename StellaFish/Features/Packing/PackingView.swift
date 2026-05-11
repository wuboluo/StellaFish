import SwiftUI
import SwiftData

struct PackingView: View {
    @Environment(\.modelContext) private var ctx
    @Environment(AppState.self) private var appState
    @Query(sort: \Trip.departDate) private var trips: [Trip]
    @Query(sort: \PackingItem.sortOrder) private var allItems: [PackingItem]
    @State private var showAdd = false
    @State private var editingItem: PackingItem? = nil
    @State private var listID = UUID()

    private var activeTrip: Trip? {
        guard let id = appState.activeTripID else { return nil }
        return trips.first { $0.id == id }
    }

    private var items: [PackingItem] {
        guard let trip = activeTrip else { return [] }
        return allItems.filter { $0.trip?.id == trip.id }
    }

    private var grouped: [(String, [PackingItem])] {
        let cats = PackingTemplateItem.categoryOrder
        let dict = Dictionary(grouping: items) { $0.category }
        var result: [(String, [PackingItem])] = []
        for cat in cats {
            if let g = dict[cat], !g.isEmpty { result.append((cat, g)) }
        }
        let known = Set(cats)
        for (cat, g) in dict where !known.contains(cat) && !g.isEmpty { result.append((cat, g)) }
        return result
    }

    var body: some View {
        Group {
            if activeTrip == nil {
                noTripState
            } else {
                content
            }
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { listID = UUID() }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button { showAdd = true } label: { Image(systemName: "plus") }
            }
        }
        .sheet(isPresented: $showAdd) {
            PackingItemFormView(item: PackingItem?.none, trip: activeTrip) { newItem in
                ctx.insert(newItem)
                try? ctx.save()
            }
        }
        .sheet(item: $editingItem) { item in
            PackingItemFormView(item: item, trip: activeTrip) { _ in try? ctx.save() }
        }
    }

    // MARK: - Content

    private var content: some View {
        VStack(spacing: 0) {
            // Progress bar
            if !items.isEmpty {
                progressBar
            }
            if items.isEmpty {
                emptyState
            } else {
                List {
                    ForEach(grouped, id: \.0) { category, catItems in
                        Section {
                            ForEach(catItems) { item in
                                CompactPackingRow(item: item,
                                    onToggle: { item.isDone.toggle(); try? ctx.save() },
                                    onEdit: { editingItem = item },
                                    onDelete: { ctx.delete(item); try? ctx.save() })
                            }
                        } header: {
                            Text(category)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                                .textCase(nil)
                        }
                    }
                }
                .listStyle(.plain)
                .id(listID)
            }
        }
    }

    private var progressBar: some View {
        let defaultItems  = items.filter { $0.isFromDefault && !$0.isImportant }
        let importantItems = items.filter { $0.isImportant }
        let newItems       = items.filter { !$0.isFromDefault && !$0.isImportant }
        let total = items.count
        let done  = items.filter { $0.isDone }.count
        let progress = total > 0 ? Double(done) / Double(total) : 0
        return VStack(spacing: 0) {
            HStack(spacing: 10) {
                if !defaultItems.isEmpty {
                    statChip("默认", done: defaultItems.filter(\.isDone).count, total: defaultItems.count, color: AppColors.primary)
                }
                if !importantItems.isEmpty {
                    statChip("重要", done: importantItems.filter(\.isDone).count, total: importantItems.count, color: AppColors.error)
                }
                if !newItems.isEmpty {
                    statChip("新增", done: newItems.filter(\.isDone).count, total: newItems.count, color: AppColors.success)
                }
                Spacer()
                Text("\(Int(progress * 100))%")
                    .font(.system(size: 11).weight(.semibold))
                    .foregroundStyle(AppColors.primary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 7)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Rectangle().fill(AppColors.primary.opacity(0.12))
                    Rectangle().fill(AppColors.primary).frame(width: geo.size.width * progress)
                }
            }
            .frame(height: 2)
            Divider()
        }
        .background(.white)
    }

    private func statChip(_ label: String, done: Int, total: Int, color: Color) -> some View {
        HStack(spacing: 3) {
            Circle().fill(color).frame(width: 5, height: 5)
            Text("\(label) \(done)/\(total)")
                .font(.system(size: 11).weight(.medium))
                .foregroundStyle(color)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "checklist")
                .font(.system(size: 44))
                .foregroundStyle(AppColors.primary.opacity(0.35))
            Text("还没有清单项")
                .font(.headline)
            Text("点击右上角 + 添加单个物品")
                .font(.subheadline).foregroundStyle(.secondary).multilineTextAlignment(.center)
            if let trip = activeTrip {
                Button("导入默认模板") { generateFromTemplate(for: trip) }
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(AppColors.primary)
                    .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    private var noTripState: some View {
        ContentUnavailableView(
            "未选择旅行",
            systemImage: "checklist",
            description: Text("请先在「旅行」页选择一个旅行")
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func generateFromTemplate(for trip: Trip) {
        let templates = (try? ctx.fetch(FetchDescriptor<PackingTemplateItem>(
            sortBy: [SortDescriptor(\.sortOrder)]))) ?? []
        for (i, tmpl) in templates.enumerated() {
            let item = PackingItem(title: tmpl.title, category: tmpl.category,
                                   colorTag: tmpl.colorTag, isFromDefault: true, sortOrder: i)
            item.trip = trip
            ctx.insert(item)
        }
        try? ctx.save()
    }
}

// MARK: - Compact Row

private struct CompactPackingRow: View {
    let item: PackingItem
    let onToggle: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Button(action: onToggle) {
                Image(systemName: item.isDone ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 18))
                    .foregroundStyle(item.isDone ? AppColors.success : Color(.systemGray3))
            }
            .buttonStyle(.plain)

            Circle().fill(tagColor).frame(width: 6, height: 6)

            Text(item.title)
                .font(.system(size: 15))
                .foregroundStyle(item.isDone ? Color.secondary : Color.primary)
                .opacity(item.isDone ? 0.55 : 1)

            if item.isImportant {
                Image(systemName: "exclamationmark.circle.fill")
                    .font(.caption2)
                    .foregroundStyle(AppColors.error)
            }

            Spacer()
        }
        .padding(.vertical, 1)
        .listRowSeparator(.hidden)
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive, action: onDelete) { Label("删除", systemImage: "trash") }
        }
        .swipeActions(edge: .leading, allowsFullSwipe: false) {
            Button(action: onEdit) { Label("编辑", systemImage: "pencil") }.tint(.blue)
        }
    }

    private var tagColor: Color {
        switch item.effectiveTag {
        case "blue": return AppColors.primary
        case "green": return AppColors.success
        case "red": return AppColors.error
        default: return Color(.systemGray4)
        }
    }
}

// MARK: - effectiveTag

extension PackingItem {
    var effectiveTag: String {
        if isImportant { return "red" }
        if isFromDefault { return colorTag }
        return "green"
    }
}

// MARK: - PackingItemFormView

struct PackingItemFormView: View {
    @Environment(\.dismiss) private var dismiss
    let item: PackingItem?
    let trip: Trip?
    let onSave: (PackingItem) -> Void

    @State private var title = ""
    @State private var category = "证件与重要物品"
    @State private var isImportant = false
    @State private var note = ""

    private let categories = PackingTemplateItem.categoryOrder + ["其他"]

    var body: some View {
        NavigationStack {
            Form {
                Section("名称") { TextField("例如：充电器", text: $title) }
                Section("分类") {
                    Picker("分类", selection: $category) {
                        ForEach(categories, id: \.self) { Text($0) }
                    }.pickerStyle(.menu)
                }
                Section { Toggle("标记为重要", isOn: $isImportant) }
                Section("备注") {
                    TextField("可选", text: $note, axis: .vertical).lineLimit(3)
                }
            }
            .navigationTitle(item == nil ? "新增清单项" : "编辑清单项")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("取消") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        let target = item ?? PackingItem(title: title, category: category)
                        target.title = title; target.category = category
                        target.isImportant = isImportant; target.note = note
                        target.updatedAt = Date()
                        if item == nil { target.trip = trip; target.colorTag = "green" }
                        onSave(target)
                        dismiss()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear {
                if let item {
                    title = item.title; category = item.category
                    isImportant = item.isImportant; note = item.note
                } else {
                    category = categories.first ?? "其他"
                }
            }
        }
    }
}
