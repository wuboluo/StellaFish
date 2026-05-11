import Foundation
import Observation

@Observable
final class SettingsViewModel {
    var isTesting = false
    var testResult: String?
    var isLoadingBalance = false
    var balanceText: String?
    var balanceError: String?

    private let service = DeepSeekService.shared

    var totalTokensUsed: Int { service.totalTokensUsed }

    func loadBalance() async {
        isLoadingBalance = true
        balanceError = nil
        do {
            let info = try await service.checkBalance()
            balanceText = "\(info.totalBalance) \(info.currency)"
        } catch {
            balanceError = error.localizedDescription
        }
        isLoadingBalance = false
    }

    func testConnection() async {
        isTesting = true
        testResult = nil
        do {
            let reply = try await service.sendMessage(
                systemPrompt: "You are a helpful assistant.",
                userPrompt: "Reply with exactly: OK"
            )
            testResult = "连接成功：\(reply.prefix(50))"
        } catch {
            testResult = "连接失败：\(error.localizedDescription)"
        }
        isTesting = false
    }
}
