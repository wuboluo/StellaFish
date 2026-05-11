import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Trip.departDate) private var trips: [Trip]
    @Query(sort: \ExpenseRecord.createdAt, order: .reverse) private var allExpenses: [ExpenseRecord]
    @State private var selectedTripID: UUID? = nil
    @State private var showVoice = false

    // MARK: - Computed

    private var selectedTrip: Trip? {
        if let id = selectedTripID {
            return trips.first { $0.id == id }
        }
        let now = Date()
        return trips.first { $0.departDate <= now && $0.returnDate >= now }
            ?? trips.first { $0.departDate > now }
            ?? trips.first
    }

    private var todayTotal: Double {
        allExpenses
            .filter { Calendar.current.isDateInToday($0.createdAt) }
            .reduce(0) { $0 + $1.amount }
    }

    private var recentExpenses: [ExpenseRecord] {
        Array(allExpenses.prefix(4))
    }

    private var nextReminder: TransportTask? {
        selectedTrip?.transportTasks
            .compactMap { t -> (TransportTask, Date)? in
                guard let d = t.nextReminderAt, d > Date() else { return nil }
                return (t, d)
            }
            .min { $0.1 < $1.1 }
            .map { $0.0 }
    }

    // MARK: - Body

    var body: some View {
        Group {
            if trips.isEmpty {
                emptyView
            } else {
                contentView
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .background(AppColors.background)
        .toolbar {
            if !trips.isEmpty {
                ToolbarItem(placement: .principal) { tripPicker }
            }
        }
        .sheet(isPresented: $showVoice) {
            VoiceExpenseView { records in
                records.forEach { modelContext.insert($0) }
                try? modelContext.save()
            }
        }
    }

    // MARK: - Trip Picker

    private var tripPicker: some View {
        Menu {
            ForEach(trips) { trip in
                Button {
                    selectedTripID = trip.id
                } label: {
                    HStack {
                        Text(trip.title)
                        if trip.id == selectedTrip?.id {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: 4) {
                Text(selectedTrip?.title ?? "选择行程")
                    .font(.subheadline.weight(.semibold))
                Image(systemName: "chevron.down")
                    .font(.caption2)
            }
            .foregroundStyle(AppColors.primary)
        }
    }

    // MARK: - Content

    private var contentView: some View {
        ScrollView {
            VStack(spacing: 20) {
                if let trip = selectedTrip {
                    tripCard(trip: trip)
                }
                quickActionsSection
                todaySection
                if !recentExpenses.isEmpty {
                    recentSection
                }
                moreSection
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 40)
        }
    }

    // MARK: - Trip Card

    private func tripCard(trip: Trip) -> some View {
        HStack(spacing: 0) {
            RoundedRectangle(cornerRadius: 2)
                .fill(AppColors.primaryGradient)
                .frame(width: 4)

            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top) {
                    tripStatusBadge(trip)
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(trip.departDate, format: .dateTime.month().day())
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.secondary)
                        Text("出发 · \(trip.durationDays)天")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(trip.title)
                        .font(.headline)
                    HStack(spacing: 6) {
                        Text(trip.fromCity)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Image(systemName: "arrow.right")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text(trip.toCity)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("\(trip.peopleCount)人")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(14)
        }
        .cardStyle()
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
    }

    private func tripStatusBadge(_ trip: Trip) -> some View {
        let now = Date()
        let isActive = trip.departDate <= now && trip.returnDate >= now
        let isUpcoming = trip.departDate > now
        let icon = isActive ? "location.fill" : (isUpcoming ? "airplane.departure" : "flag.checkered")
        let label = isActive ? "进行中" : (isUpcoming ? "即将出发" : "已结束")
        let color: Color = isActive ? .green : (isUpcoming ? AppColors.primary : .secondary)

        return Label(label, systemImage: icon)
            .font(.caption.weight(.semibold))
            .foregroundStyle(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.12))
            .clipShape(Capsule())
    }

    // MARK: - Quick Actions

    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("快捷操作")
            LazyVGrid(columns: [.init(.flexible()), .init(.flexible())], spacing: 12) {
                Button { showVoice = true } label: {
                    quickActionContent(
                        title: "语音记账",
                        subtitle: "说话即记账",
                        icon: "mic.fill",
                        color: AppColors.accent
                    )
                }
                .buttonStyle(ScaleButtonStyle())

                if let trip = selectedTrip {
                    NavigationLink {
                        TransportTaskListView(trip: trip)
                            .navigationTitle("交通查票")
                    } label: {
                        quickActionContent(
                            title: "添加查票",
                            subtitle: "监控车票信息",
                            icon: "tram.fill",
                            color: AppColors.primary
                        )
                    }
                    .buttonStyle(ScaleButtonStyle())

                    NavigationLink {
                        ChecklistView(trip: trip)
                            .navigationTitle("清单")
                    } label: {
                        quickActionContent(
                            title: "添加清单",
                            subtitle: "行前准备清单",
                            icon: "checklist",
                            color: .green
                        )
                    }
                    .buttonStyle(ScaleButtonStyle())
                } else {
                    quickActionContent(
                        title: "添加查票",
                        subtitle: "请先新建行程",
                        icon: "tram.fill",
                        color: AppColors.primary
                    )
                    .opacity(0.4)

                    quickActionContent(
                        title: "添加清单",
                        subtitle: "请先新建行程",
                        icon: "checklist",
                        color: .green
                    )
                    .opacity(0.4)
                }

                NavigationLink {
                    AIView()
                } label: {
                    quickActionContent(
                        title: "问 AI",
                        subtitle: "智能旅行助手",
                        icon: "sparkles",
                        color: .purple
                    )
                }
                .buttonStyle(ScaleButtonStyle())
            }
        }
    }

    private func quickActionContent(title: String, subtitle: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(color)
                .frame(width: 38, height: 38)
                .background(color.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            Spacer(minLength: 4)
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .cardStyle()
    }

    // MARK: - Today Overview

    private var todaySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("今日概览")

            HStack(spacing: 12) {
                statPill(
                    icon: "yensign.circle.fill",
                    color: AppColors.accent,
                    label: "今日花费",
                    value: todayTotal.currencyString
                )
                statPill(
                    icon: "checklist",
                    color: .green,
                    label: "待办清单",
                    value: "\(selectedTrip?.pendingChecklistCount ?? 0) 项"
                )
            }

            if let task = nextReminder {
                nextReminderRow(task: task)
            }
        }
    }

    private func statPill(icon: String, color: Color, label: String, value: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(color)
            VStack(alignment: .leading, spacing: 1) {
                Text(value)
                    .font(.subheadline.weight(.semibold))
                Text(label)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(12)
        .cardStyle(radius: AppRadius.sm)
        .frame(maxWidth: .infinity)
    }

    private func nextReminderRow(task: TransportTask) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "bell.fill")
                .font(.system(size: 15))
                .foregroundStyle(.orange)
                .frame(width: 32, height: 32)
                .background(Color.orange.opacity(0.12))
                .clipShape(Circle())
            VStack(alignment: .leading, spacing: 2) {
                Text("下次提醒")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(task.title)
                    .font(.subheadline)
            }
            Spacer()
            if let d = task.nextReminderAt {
                Text(d, style: .relative)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.trailing)
            }
        }
        .padding(12)
        .cardStyle(radius: AppRadius.sm)
    }

    // MARK: - Recent Records

    private var recentSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                sectionLabel("最近记录")
                Spacer()
                NavigationLink {
                    ExpenseListView()
                } label: {
                    Text("查看全部")
                        .font(.caption)
                        .foregroundStyle(AppColors.primary)
                }
            }

            VStack(spacing: 0) {
                ForEach(Array(recentExpenses.enumerated()), id: \.element.id) { index, record in
                    recentRow(record: record)
                    if index < recentExpenses.count - 1 {
                        Divider()
                            .padding(.leading, 54)
                    }
                }
            }
            .cardStyle()
        }
    }

    private func recentRow(record: ExpenseRecord) -> some View {
        HStack(spacing: 12) {
            Image(systemName: record.category.icon)
                .font(.system(size: 15))
                .foregroundStyle(AppColors.primary)
                .frame(width: 34, height: 34)
                .background(AppColors.primary.opacity(0.1))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(record.title)
                    .font(.subheadline)
                    .lineLimit(1)
                Text(record.createdAt, style: .time)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(record.amount.currencyString)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppColors.accent)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    // MARK: - More Section

    private var moreSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("更多")
            VStack(spacing: 8) {
                NavigationLink { TripListView() } label: {
                    navRow("行程计划", icon: "map.fill", color: AppColors.primary)
                }
                NavigationLink { ExpenseListView() } label: {
                    navRow("记账明细", icon: "yensign.circle.fill", color: AppColors.accent)
                }
                NavigationLink { SettingsView() } label: {
                    navRow("设置", icon: "gearshape.fill", color: Color(.systemGray))
                }
            }
        }
    }

    private func navRow(_ title: String, icon: String, color: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 17))
                .foregroundStyle(color)
                .frame(width: 28)
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.primary)
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(14)
        .cardStyle()
    }

    // MARK: - Section Label

    private func sectionLabel(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)
            .kerning(0.5)
            .padding(.leading, 2)
    }

    // MARK: - Empty State

    private var emptyView: some View {
        ScrollView {
            VStack(spacing: 0) {
                VStack(spacing: 16) {
                    Image(systemName: "airplane.departure")
                        .font(.system(size: 60, weight: .light))
                        .foregroundStyle(AppColors.primaryGradient)
                        .padding(.top, 60)
                        .padding(.bottom, 8)

                    Text("开始你的旅程")
                        .font(.title2.weight(.bold))

                    Text("新建一个行程，StellaFish 帮你\n规划交通、住宿、清单和花费")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)

                    NavigationLink {
                        TripListView()
                    } label: {
                        Label("新建行程", systemImage: "plus")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 28)
                            .padding(.vertical, 13)
                            .background(AppColors.primaryGradient)
                            .clipShape(Capsule())
                    }
                    .padding(.top, 4)
                }
                .padding(.horizontal, 32)

                Divider()
                    .padding(.horizontal, 24)
                    .padding(.vertical, 28)

                moreSection
                    .padding(.horizontal, 16)
            }
            .padding(.bottom, 40)
        }
        .background(AppColors.background)
    }
}
