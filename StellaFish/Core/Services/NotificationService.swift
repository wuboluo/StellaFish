import Foundation
import UserNotifications

final class NotificationService: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationService()
    private override init() { super.init() }

    func requestAuthorization() async {
        try? await UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound, .badge])
    }

    // Show banners/sound/list even when app is in foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .list])
    }

    func schedule(_ item: ReminderItem) async {
        guard !item.isDone, item.remindAt > Date() else { return }
        let content = UNMutableNotificationContent()
        content.title = "旅行提醒"
        content.body = item.title
        if !item.note.isEmpty { content.subtitle = item.note }
        content.sound = .default
        if item.priority == "important" { content.interruptionLevel = .timeSensitive }

        let comps = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: item.remindAt)
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
        let request = UNNotificationRequest(identifier: item.notificationId, content: content, trigger: trigger)
        try? await UNUserNotificationCenter.current().add(request)
    }

    func cancel(id: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id])
    }

    func scheduleTicketReminder(task: TransportTask) {
        let content = UNMutableNotificationContent()
        content.title = "票价提醒"
        content.body = "\(task.title)：该去查询票价了"
        content.sound = .default

        let intervalSeconds = TimeInterval(task.reminderIntervalMinutes * 60)
        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: max(intervalSeconds, 60),
            repeats: true
        )
        let request = UNNotificationRequest(
            identifier: task.id.uuidString,
            content: content,
            trigger: trigger
        )
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
    }

    func cancelReminder(taskId: UUID) {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [taskId.uuidString])
    }

    func scheduleTest() async {
        let content = UNMutableNotificationContent()
        content.title = "StellaFish 通知测试"
        content.body = "通知功能正常 ✓"
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        let request = UNNotificationRequest(identifier: "stellafish.test.\(UUID().uuidString)", content: content, trigger: trigger)
        try? await UNUserNotificationCenter.current().add(request)
    }
}
