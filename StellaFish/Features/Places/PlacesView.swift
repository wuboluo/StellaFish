import SwiftUI
import SwiftData

// MARK: - Places Tab

struct PlacesView: View {
    @Environment(\.modelContext) private var ctx
    @Environment(AppState.self) private var appState
    @Query(sort: \Trip.departDate) private var trips: [Trip]
    @Query(sort: \PlaceRecord.createdAt, order: .reverse) private var allPlaces: [PlaceRecord]
    @State private var showAdd = false
    @State private var editingPlace: PlaceRecord? = nil
    @State private var copiedID: UUID? = nil
    @State private var listID = UUID()

    private var activeTrip: Trip? {
        guard let id = appState.activeTripID else { return nil }
        return trips.first { $0.id == id }
    }

    private var places: [PlaceRecord] {
        guard let trip = activeTrip else { return [] }
        return allPlaces.filter { $0.trip?.id == trip.id }
    }

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()
            if activeTrip == nil {
                noTripState
            } else if places.isEmpty {
                emptyState
            } else {
                placesList
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { listID = UUID() }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button { showAdd = true } label: { Image(systemName: "plus") }
                    .disabled(activeTrip == nil)
            }
        }
        .sheet(isPresented: $showAdd) {
            PlaceFormView(trip: activeTrip)
        }
        .sheet(item: $editingPlace) { place in
            PlaceFormView(editing: place)
        }
    }

    // MARK: - List

    private var placesList: some View {
        List {
            ForEach(places) { place in
                PlaceCard(place: place, copiedID: $copiedID)
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            ctx.delete(place)
                        } label: { Label("删除", systemImage: "trash") }
                        Button { editingPlace = place } label: {
                            Label("编辑", systemImage: "pencil")
                        }.tint(.blue)
                    }
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
            }
        }
        .listStyle(.plain)
        .id(listID)
    }

    // MARK: - Empty States

    private var noTripState: some View {
        ContentUnavailableView(
            "未选择旅行",
            systemImage: "map",
            description: Text("请先在「旅行」页选择一个旅行")
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "mappin.and.ellipse")
                .font(.system(size: 44))
                .foregroundStyle(AppColors.textSecondary.opacity(0.35))
            Text("还没有常用地点")
                .font(.headline)
            Text("点击右上角 + 添加酒店、车站、机场等")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

// MARK: - Place Card

struct PlaceCard: View {
    let place: PlaceRecord
    @Binding var copiedID: UUID?

    private var justCopied: Bool { copiedID == place.id }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack(spacing: 8) {
                Text(place.title)
                    .font(.subheadline.weight(.semibold))
                categoryBadge
                Spacer()
            }

            // Address
            if !place.address.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "location")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(place.address)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            // Phone
            if !place.phone.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "phone")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(place.phone)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            // Note
            if !place.note.isEmpty {
                Text(place.note)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            // Copy Buttons
            HStack(spacing: 8) {
                copyButton("复制地址", value: place.address, disabled: place.address.isEmpty)
                copyButton("复制名称", value: place.title, disabled: false)
                copyAllButton
                Spacer()
                if justCopied {
                    Label("已复制", systemImage: "checkmark.circle.fill")
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(AppColors.success)
                        .transition(.opacity.combined(with: .scale(scale: 0.8)))
                }
            }
        }
        .padding(12)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
        .softShadow()
    }

    @ViewBuilder
    private var categoryBadge: some View {
        Text(place.category)
            .font(.caption2.weight(.medium))
            .foregroundStyle(categoryColor)
            .padding(.horizontal, 7).padding(.vertical, 3)
            .background(categoryColor.opacity(0.12))
            .clipShape(Capsule())
    }

    private var categoryColor: Color {
        switch place.category {
        case "酒店": return .blue
        case "车站": return .orange
        case "机场": return AppColors.primary
        case "景点": return .green
        case "餐厅": return .red
        case "集合点": return .purple
        default: return AppColors.textSecondary
        }
    }

    private func copyButton(_ label: String, value: String, disabled: Bool) -> some View {
        Button {
            UIPasteboard.general.string = value
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            withAnimation { copiedID = place.id }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                if copiedID == place.id { copiedID = nil }
            }
        } label: {
            Text(label)
                .font(.caption.weight(.medium))
                .foregroundStyle(disabled ? .secondary : AppColors.primary)
                .padding(.horizontal, 10).padding(.vertical, 5)
                .background((disabled ? Color.secondary : AppColors.primary).opacity(0.1))
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .disabled(disabled)
    }

    private var copyAllButton: some View {
        Button {
            var parts: [String] = []
            parts.append("地点：\(place.title)")
            if !place.address.isEmpty { parts.append("地址：\(place.address)") }
            if !place.note.isEmpty { parts.append("备注：\(place.note)") }
            UIPasteboard.general.string = parts.joined(separator: "\n")
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            withAnimation { copiedID = place.id }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                if copiedID == place.id { copiedID = nil }
            }
        } label: {
            Text("复制全部")
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 10).padding(.vertical, 5)
                .background(Color.secondary.opacity(0.1))
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Place Form

struct PlaceFormView: View {
    @Environment(\.modelContext) private var ctx
    @Environment(\.dismiss) private var dismiss
    var editing: PlaceRecord? = nil
    var trip: Trip? = nil

    @State private var title = ""
    @State private var category = "其他"
    @State private var address = ""
    @State private var phone = ""
    @State private var note = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("地点名称") {
                    TextField("例如：全季酒店成都春熙路店", text: $title)
                }
                Section("分类") {
                    Picker("分类", selection: $category) {
                        ForEach(PlaceRecord.categories, id: \.self) { Text($0) }
                    }
                    .pickerStyle(.menu)
                }
                Section("地址") {
                    TextField("详细地址", text: $address, axis: .vertical)
                        .lineLimit(2...4)
                }
                Section("联系电话（可选）") {
                    TextField("电话", text: $phone)
                        .keyboardType(.phonePad)
                }
                Section("备注（可选）") {
                    TextField("例如：前台在3楼", text: $note, axis: .vertical)
                        .lineLimit(2...5)
                }
            }
            .navigationTitle(editing == nil ? "添加地点" : "编辑地点")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("取消") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") { save() }
                        .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear { loadExisting() }
        }
    }

    private func loadExisting() {
        if let e = editing {
            title = e.title; category = e.category
            address = e.address; phone = e.phone; note = e.note
        }
    }

    private func save() {
        let t = title.trimmingCharacters(in: .whitespaces)
        guard !t.isEmpty else { return }
        if let e = editing {
            e.title = t; e.category = category
            e.address = address; e.phone = phone; e.note = note
            e.updatedAt = Date()
        } else {
            let p = PlaceRecord(title: t, category: category)
            p.address = address; p.phone = phone; p.note = note
            p.trip = trip
            ctx.insert(p)
        }
        dismiss()
    }
}
