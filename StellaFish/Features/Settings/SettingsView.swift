import SwiftUI
import SwiftData
import UserNotifications

// MARK: - Settings Sheet

struct SettingsSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var ctx
    @Environment(AppState.self) private var appState
    @State private var showTestAlert = false
    @State private var showPermissionAlert = false
    @State private var showDeleteAllAlert = false

    var body: some View {
        NavigationStack {
            List {
                Section("清单模板") {
                    NavigationLink {
                        PackingTemplateView()
                    } label: {
                        Label("默认物品模板", systemImage: "list.bullet.clipboard")
                    }
                }

                Section {
                    DeepSeekStatusRow()
                } header: {
                    Text("DeepSeek AI（票据自动识别）")
                } footer: {
                    Text("使用内置 Key，如需更换请联系开发者。")
                }

                Section("通知") {
                    NotificationStatusRow()
                    Button {
                        Task {
                            let settings = await UNUserNotificationCenter.current().notificationSettings()
                            if settings.authorizationStatus == .authorized {
                                await NotificationService.shared.scheduleTest()
                                showTestAlert = true
                            } else {
                                showPermissionAlert = true
                            }
                        }
                    } label: {
                        Label("发送测试通知（5秒后）", systemImage: "bell.badge")
                    }
                }

                Section("关于") {
                    HStack {
                        Text("StellaFish")
                        Spacer()
                        Text("v 1.0")
                            .foregroundStyle(.secondary)
                    }
                }

                Section {
                    Button(role: .destructive) {
                        showDeleteAllAlert = true
                    } label: {
                        Label("删除所有数据", systemImage: "trash")
                    }
                } footer: {
                    Text("删除所有旅行、清单、交通、地点和提醒，且不可恢复。")
                }
            }
            .navigationTitle("设置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") { dismiss() }
                }
            }
            .alert("测试通知已安排", isPresented: $showTestAlert) {
                Button("好") {}
            } message: {
                Text("5 秒后将收到测试通知。如未出现，请检查系统通知设置。")
            }
            .alert("通知权限未开启", isPresented: $showPermissionAlert) {
                Button("去系统设置") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                Button("取消", role: .cancel) {}
            } message: {
                Text("请在系统设置中允许「StellaFish」发送通知。")
            }
            .alert("删除所有数据", isPresented: $showDeleteAllAlert) {
                Button("确认删除", role: .destructive) { deleteAllData() }
                Button("取消", role: .cancel) {}
            } message: {
                Text("将删除所有旅行、清单、交通记录、地点和提醒，且无法恢复。")
            }
        }
    }

    private func deleteAllData() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        let trips = (try? ctx.fetch(FetchDescriptor<Trip>())) ?? []
        for trip in trips { ctx.delete(trip) }
        appState.activeTripID = nil
        dismiss()
    }
}

// MARK: - DeepSeek Status Row

private struct DeepSeekStatusRow: View {
    @State private var isTesting = false
    @State private var testResult: String? = nil
    @State private var viewModel = SettingsViewModel()

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Label("DeepSeek 状态", systemImage: "cpu")
                Spacer()
                Text("已配置")
                    .font(.subheadline)
                    .foregroundStyle(AppColors.success)
            }
            HStack(spacing: 8) {
                Button {
                    Task {
                        isTesting = true
                        testResult = nil
                        await viewModel.testConnection()
                        testResult = viewModel.testResult
                        isTesting = false
                    }
                } label: {
                    HStack(spacing: 4) {
                        if isTesting { ProgressView().scaleEffect(0.7) }
                        Text(isTesting ? "测试中…" : "测试连接")
                    }
                    .font(.caption.weight(.medium))
                    .foregroundStyle(AppColors.primary)
                    .padding(.horizontal, 10).padding(.vertical, 4)
                    .background(AppColors.primary.opacity(0.1))
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .disabled(isTesting)

                if let result = testResult {
                    Text(result)
                        .font(.caption)
                        .foregroundStyle(result.hasPrefix("连接成功") ? AppColors.success : AppColors.error)
                }
            }
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Notification Status Row

private struct NotificationStatusRow: View {
    @State private var status: UNAuthorizationStatus = .notDetermined

    var body: some View {
        HStack {
            Label("通知权限", systemImage: "bell")
            Spacer()
            Group {
                switch status {
                case .authorized:
                    Text("已开启").foregroundStyle(AppColors.success)
                case .denied:
                    Button("去系统设置") {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }
                    .foregroundStyle(AppColors.error)
                default:
                    Button("申请权限") {
                        Task {
                            await NotificationService.shared.requestAuthorization()
                            await refreshStatus()
                        }
                    }
                    .foregroundStyle(AppColors.primary)
                }
            }
            .font(.subheadline)
        }
        .task { await refreshStatus() }
    }

    private func refreshStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        status = settings.authorizationStatus
    }
}

// MARK: - Legacy aliases

struct MyView: View {
    var body: some View { SettingsSheetView() }
}

struct SettingsView: View {
    var body: some View { SettingsSheetView() }
}

struct UpdateAPIKeySheet: View {
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationStack {
            Text("功能已移除").navigationTitle("API Key")
                .toolbar { ToolbarItem(placement: .cancellationAction) { Button("关闭") { dismiss() } } }
        }
    }
}
