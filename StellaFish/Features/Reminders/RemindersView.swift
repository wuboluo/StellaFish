import SwiftUI
import SwiftData
import UserNotifications

struct RemindersView: View {
    @Environment(\.modelContext) private var ctx
    @Environment(AppState.self) private var appState
    @Query(sort: \Trip.departDate) private var trips: [Trip]
    @Query(sort: \ReminderItem.remindAt) private var allReminders: [ReminderItem]

    @State private var showAdd = false
    @State private var editingReminder: ReminderItem? = nil
    @State private var notifStatus: UNAuthorizationStatus = .notDetermined
    @State private var listID = UUID()

    private var activeTrip: Trip? {
        guard let id = appState.activeTripID else { return nil }
        return trips.first { $0.id == id }
    }

    private var reminders: [ReminderItem] {
        guard let trip = activeTrip else { return [] }
        return allReminders.filter { $0.trip?.id == trip.id }
    }

    private var today: [ReminderItem] {
        reminders.filter { Calendar.current.isDateInToday($0.remindAt) && !$0.isDone }
    }
    private var tomorrow: [ReminderItem] {
        reminders.filter { Calendar.current.isDateInTomorrow($0.remindAt) && !$0.isDone }
    }
    private var later: [ReminderItem] {
        reminders.filter {
            !$0.isDone && $0.remindAt > Date()
            && !Calendar.current.isDateInToday($0.remindAt)
            && !Calendar.current.isDateInTomorrow($0.remindAt)
        }
    }
    private var overdue: [ReminderItem] {
        reminders.filter { !$0.isDone && $0.remindAt < Date() && !Calendar.current.isDateInToday($0.remindAt) }
    }
    private var done: [ReminderItem] {
        reminders.filter { $0.isDone }
    }

    var body: some View {
        Group {
            if activeTrip == nil {
                noTripState
            } else {
                VStack(spacing: 0) {
                    notifBanner
                    if reminders.isEmpty { emptyState } else { reminderList }
                }
            }
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button { showAdd = true } label: { Image(systemName: "plus") }
                    .disabled(activeTrip == nil)
            }
        }
        .sheet(isPresented: $showAdd) {
            ReminderFormView(trip: activeTrip)
        }
        .sheet(item: $editingReminder) { item in
            ReminderFormView(editing: item)
        }
        .task { await refreshNotifStatus() }
        .onAppear { listID = UUID() }
    }

    // MARK: - Notification Banner

    @ViewBuilder
    private var notifBanner: some View {
        if notifStatus == .denied {
            HStack(spacing: 8) {
                Image(systemName: "bell.slash.fill").foregroundStyle(AppColors.error)
                Text("通知权限未开启，提醒将无法弹出")
                    .font(.caption)
                Spacer()
                Button("去设置") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppColors.primary)
            }
            .padding(.horizontal, 16).padding(.vertical, 10)
            .background(AppColors.error.opacity(0.08))
        } else if notifStatus == .notDetermined {
            HStack(spacing: 8) {
                Image(systemName: "bell").foregroundStyle(AppColors.warning)
                Text("开启通知权限以收到提醒推送").font(.caption)
                Spacer()
                Button("开启") {
                    Task {
                        await NotificationService.shared.requestAuthorization()
                        await refreshNotifStatus()
                    }
                }
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppColors.primary)
            }
            .padding(.horizontal, 16).padding(.vertical, 10)
            .background(AppColors.warning.opacity(0.08))
        }
    }

    // MARK: - List

    private var reminderList: some View {
        List {
            if !overdue.isEmpty {
                Section("已过期") {
                    ForEach(overdue) { item in reminderRow(item) }
                }
            }
            if !today.isEmpty {
                Section("今天") {
                    ForEach(today) { item in reminderRow(item) }
                }
            }
            if !tomorrow.isEmpty {
                Section("明天") {
                    ForEach(tomorrow) { item in reminderRow(item) }
                }
            }
            if !later.isEmpty {
                Section("稍后") {
                    ForEach(later) { item in reminderRow(item) }
                }
            }
            if !done.isEmpty {
                Section("已完成") {
                    ForEach(done) { item in reminderRow(item) }
                }
            }
        }
        .listStyle(.insetGrouped)
        .id(listID)
    }

    private func reminderRow(_ item: ReminderItem) -> some View {
        HStack(spacing: 12) {
            Button {
                item.isDone.toggle()
                if item.isDone {
                    NotificationService.shared.cancel(id: item.notificationId)
                } else {
                    Task { await NotificationService.shared.schedule(item) }
                }
            } label: {
                Image(systemName: item.isDone ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(item.isDone ? AppColors.success : Color(.systemGray3))
            }
            .buttonStyle(.plain)

            Button { editingReminder = item } label: {
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 5) {
                        if item.priority == "important" {
                            Image(systemName: "exclamationmark.circle.fill")
                                .font(.caption)
                                .foregroundStyle(AppColors.error)
                        }
                        Text(item.title)
                            .font(.subheadline)
                            .fontWeight(item.priority == "important" ? .semibold : .regular)
                            .foregroundStyle(item.isDone ? .secondary : .primary)
                            .strikethrough(item.isDone)
                    }
                    Text(item.remindAt.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                        .foregroundStyle(timeColor(item))
                }
                Spacer()
                Image(systemName: "chevron.right").font(.caption).foregroundStyle(.secondary.opacity(0.4))
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 2)
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                NotificationService.shared.cancel(id: item.notificationId)
                ctx.delete(item)
            } label: { Label("删除", systemImage: "trash") }
        }
    }

    private func timeColor(_ item: ReminderItem) -> Color {
        if item.isDone { return .secondary.opacity(0.5) }
        if item.remindAt < Date() { return AppColors.error }
        if Calendar.current.isDateInToday(item.remindAt) { return AppColors.warning }
        return .secondary
    }

    // MARK: - States

    private var noTripState: some View {
        ContentUnavailableView("未选择旅行", systemImage: "bell", description: Text("请先在「旅行」页选择一个旅行"))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "bell.slash")
                .font(.system(size: 44))
                .foregroundStyle(AppColors.primary.opacity(0.35))
            Text("还没有提醒")
                .font(.headline)
            Text("点击右上角 + 添加提醒")
                .font(.subheadline).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    private func refreshNotifStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        notifStatus = settings.authorizationStatus
    }
}

// MARK: - Reminder Form

struct ReminderFormView: View {
    @Environment(\.modelContext) private var ctx
    @Environment(\.dismiss) private var dismiss
    var editing: ReminderItem? = nil
    var trip: Trip? = nil

    @State private var title = ""
    @State private var remindAt = Date().addingTimeInterval(3600)
    @State private var note = ""
    @State private var priority = "normal"
    @State private var pastTimeError = false

    @Query(sort: \Trip.departDate) private var trips: [Trip]
    @State private var selectedTrip: Trip? = nil

    var body: some View {
        NavigationStack {
            Form {
                Section("提醒内容") {
                    TextField("提醒事项", text: $title)
                    Picker("优先级", selection: $priority) {
                        Text("普通").tag("normal")
                        Text("重要").tag("important")
                    }
                }
                Section("时间") {
                    DatePicker("提醒时间", selection: $remindAt, in: Date()..., displayedComponents: [.date, .hourAndMinute])
                        .datePickerStyle(.graphical)
                    if pastTimeError {
                        Text("请选择未来的时间").font(.caption).foregroundStyle(AppColors.error)
                    }
                }
                Section("关联旅行（可选）") {
                    Picker("选择旅行", selection: $selectedTrip) {
                        Text("不关联").tag(Trip?.none)
                        ForEach(trips) { t in Text(t.title).tag(Trip?.some(t)) }
                    }
                }
                Section("备注") {
                    TextField("备注（可选）", text: $note, axis: .vertical).lineLimit(3...6)
                }
            }
            .navigationTitle(editing == nil ? "添加提醒" : "编辑提醒")
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
            title = e.title; remindAt = e.remindAt; note = e.note
            priority = e.priority; selectedTrip = e.trip
        } else {
            selectedTrip = trip
        }
    }

    private func save() {
        guard remindAt > Date() else { pastTimeError = true; return }
        let trimmed = title.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        if let e = editing {
            NotificationService.shared.cancel(id: e.notificationId)
            e.title = trimmed; e.remindAt = remindAt; e.note = note
            e.priority = priority; e.trip = selectedTrip; e.updatedAt = Date()
            if !e.isDone { Task { await NotificationService.shared.schedule(e) } }
        } else {
            let item = ReminderItem(title: trimmed, remindAt: remindAt, note: note, priority: priority)
            item.trip = selectedTrip
            ctx.insert(item)
            Task { await NotificationService.shared.schedule(item) }
        }
        dismiss()
    }
}
