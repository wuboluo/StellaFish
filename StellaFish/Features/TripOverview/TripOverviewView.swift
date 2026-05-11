import SwiftUI
import SwiftData

struct TripOverviewView: View {
    @Environment(\.modelContext) private var ctx
    @Environment(AppState.self) private var appState
    @Query(sort: \Trip.departDate) private var trips: [Trip]
    @State private var showNewTrip = false
    @State private var editingTrip: Trip? = nil
    @State private var tripToDelete: Trip? = nil
    @State private var showSettings = false
    @State private var listID = UUID()

    private var activeTrip: Trip? {
        guard let id = appState.activeTripID else {
            // Auto-select: current trip, then next, then first
            let now = Date()
            return trips.first { $0.departDate <= now && $0.returnDate >= now }
                ?? trips.first { $0.departDate > now }
                ?? trips.first
        }
        return trips.first { $0.id == id }
    }

    var body: some View {
        Group {
            if trips.isEmpty {
                ZStack {
                    AppColors.background.ignoresSafeArea()
                    emptyState
                }
            } else {
                ScrollView {
                    VStack(spacing: 16) {
                        if let trip = activeTrip {
                            tripCard(trip: trip)
                            statsRow(trip: trip)
                            if let next = trip.nextReminder {
                                nextReminderCard(next)
                            }
                        }
                        Divider().padding(.horizontal)
                        tripList
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 32)
                }
                .background(AppColors.background)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button { showSettings = true } label: {
                    Image(systemName: "gearshape")
                }
            }
        }
        .sheet(isPresented: $showNewTrip) {
            TripEditView(trip: nil) { newTrip in
                appState.activeTripID = newTrip.id
            }
        }
        .sheet(item: $editingTrip) { trip in
            TripEditView(trip: trip) { _ in }
        }
        .sheet(isPresented: $showSettings) {
            SettingsSheetView()
        }
        .alert(
            "删除旅行",
            isPresented: Binding(get: { tripToDelete != nil }, set: { if !$0 { tripToDelete = nil } })
        ) {
            Button("删除", role: .destructive) {
                if let trip = tripToDelete { performDelete(trip) }
            }
            Button("取消", role: .cancel) { tripToDelete = nil }
        } message: {
            Text("会同时删除该旅行下的清单、交通记录、地点和提醒，无法恢复。")
        }
        .task { seedTemplateIfNeeded() }
        .onAppear { listID = UUID() }
    }

    // MARK: - Active Trip Card

    private func tripCard(trip: Trip) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 5) {
                    statusBadge(trip)
                    Text(trip.title)
                        .font(.title3.weight(.bold))
                    if !trip.fromCity.isEmpty || !trip.toCity.isEmpty {
                        HStack(spacing: 5) {
                            Text(trip.fromCity.isEmpty ? "出发地" : trip.fromCity)
                            Image(systemName: "arrow.right").font(.caption2)
                            Text(trip.toCity.isEmpty ? "目的地" : trip.toCity)
                        }
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                Button { editingTrip = trip } label: {
                    Image(systemName: "pencil.circle")
                        .font(.system(size: 20))
                        .foregroundStyle(.secondary)
                }
            }
            HStack(spacing: 4) {
                Image(systemName: "calendar").font(.caption).foregroundStyle(.secondary)
                Text(trip.departDate, format: .dateTime.month().day())
                Text("–")
                Text(trip.returnDate, format: .dateTime.month().day())
                Text("·")
                Text("\(trip.durationDays) 天")
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
        .padding(16)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
        .softShadow()
    }

    private func statusBadge(_ trip: Trip) -> some View {
        let now = Date()
        let (text, color): (String, Color) =
            trip.departDate <= now && trip.returnDate >= now ? ("进行中", AppColors.success) :
            trip.departDate > now ? ("即将出发", AppColors.primary) : ("已结束", .secondary)
        return Text(text)
            .font(.caption.weight(.semibold))
            .foregroundStyle(color)
            .padding(.horizontal, 8).padding(.vertical, 3)
            .background(color.opacity(0.12))
            .clipShape(Capsule())
    }

    // MARK: - Stats Row

    private func statsRow(trip: Trip) -> some View {
        HStack(spacing: 10) {
            statPill("清单", value: "\(trip.packingCompletedCount)/\(trip.packingTotalCount)", icon: "checklist", color: AppColors.success)
            statPill("交通", value: "\(trip.ticketCount) 条", icon: "tram.fill", color: AppColors.primary)
            statPill("提醒", value: "\(trip.pendingReminderCount) 个", icon: "bell.fill", color: AppColors.warning)
        }
    }

    private func statPill(_ label: String, value: String, icon: String, color: Color) -> some View {
        VStack(spacing: 5) {
            Image(systemName: icon).font(.system(size: 16)).foregroundStyle(color)
            Text(value).font(.subheadline.weight(.semibold))
            Text(label).font(.caption2).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
        .softShadow()
    }

    // MARK: - Next Reminder

    private func nextReminderCard(_ item: ReminderItem) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "bell.fill")
                .font(.system(size: 14))
                .foregroundStyle(.orange)
                .frame(width: 30, height: 30)
                .background(Color.orange.opacity(0.12))
                .clipShape(Circle())
            VStack(alignment: .leading, spacing: 1) {
                Text("下一提醒").font(.caption2).foregroundStyle(.secondary)
                Text(item.title).font(.subheadline)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 1) {
                Text(item.remindAt, format: .dateTime.month().day()).font(.caption2).foregroundStyle(.secondary)
                Text(item.remindAt, format: .dateTime.hour().minute()).font(.caption.weight(.medium))
            }
        }
        .padding(12)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.sm))
        .softShadow()
    }

    // MARK: - Trip List

    private var tripList: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("所有旅行".uppercased())
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .kerning(0.5)
                .padding(.leading, 2)

            VStack(spacing: 6) {
                ForEach(trips) { trip in
                    tripRow(trip: trip)
                }
            }

            Button {
                showNewTrip = true
            } label: {
                Label("新建旅行", systemImage: "plus")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(AppColors.primary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 11)
                    .background(AppColors.primary.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
            }
        }
    }

    private func tripRow(trip: Trip) -> some View {
        let isActive = trip.id == activeTrip?.id
        return Button {
            appState.activeTripID = trip.id
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(trip.title).font(.subheadline.weight(.medium))
                    Text("\(trip.departDate, format: .dateTime.month().day()) · \(trip.durationDays)天")
                        .font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                if isActive {
                    Image(systemName: "checkmark.circle.fill").foregroundStyle(AppColors.primary)
                }
            }
            .padding(11)
            .background(isActive ? AppColors.primary.opacity(0.06) : Color.white)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.sm))
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.sm)
                    .stroke(isActive ? AppColors.primary.opacity(0.3) : Color.clear, lineWidth: 1)
            )
            .softShadow()
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button(role: .destructive) { tripToDelete = trip } label: { Label("删除旅行", systemImage: "trash") }
        }
    }

    // MARK: - Empty

    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "airplane.departure")
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(AppColors.primary.opacity(0.5))
                .padding(.top, 30)
            Text("还没有旅行计划").font(.headline)
            Text("新建一个旅行，开始整理清单、交通和提醒")
                .font(.subheadline).foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button { showNewTrip = true } label: {
                Label("新建旅行", systemImage: "plus")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24).padding(.vertical, 11)
                    .background(AppColors.primary)
                    .clipShape(Capsule())
            }
        }
        .padding(.vertical, 20)
    }

    // MARK: - Delete

    private func performDelete(_ trip: Trip) {
        trip.reminders.forEach { NotificationService.shared.cancel(id: $0.notificationId) }
        if appState.activeTripID == trip.id {
            let remaining = trips.filter { $0.id != trip.id }
            appState.activeTripID = remaining.first?.id
        }
        ctx.delete(trip)
        tripToDelete = nil
    }

    // MARK: - Seed Template

    private func seedTemplateIfNeeded() {
        let key = "stellafish.template.seeded.v2"
        guard !UserDefaults.standard.bool(forKey: key) else { return }
        let items = PackingTemplateItem.defaultItems
        for (i, item) in items.enumerated() {
            ctx.insert(PackingTemplateItem(
                title: item.title, category: item.category,
                colorTag: item.colorTag, isRequired: true, sortOrder: i
            ))
        }
        try? ctx.save()
        UserDefaults.standard.set(true, forKey: key)
    }
}
