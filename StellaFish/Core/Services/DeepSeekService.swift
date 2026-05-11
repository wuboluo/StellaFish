import Foundation
import Security

struct BalanceInfo {
    let totalBalance: String
    let currency: String
    let isAvailable: Bool
}

enum DeepSeekError: LocalizedError {
    case noAPIKey
    case networkError(Error)
    case invalidResponse
    case apiError(String)

    var errorDescription: String? {
        switch self {
        case .noAPIKey: return "API Key 未配置"
        case .networkError(let e): return "网络错误：\(e.localizedDescription)"
        case .invalidResponse: return "服务器响应格式异常"
        case .apiError(let msg): return "API 错误：\(msg)"
        }
    }
}

final class DeepSeekService {
    static let shared = DeepSeekService()
    private init() {}

    private let defaultAPIKey = ""
    private let keychainAccount = "stellafish.deepseek.apikey"
    private let endpoint = URL(string: "https://api.deepseek.com/chat/completions")!
    private let balanceEndpoint = URL(string: "https://api.deepseek.com/user/balance")!
    private let tokenUsageKey = "stellafish.deepseek.totalTokens"

    // MARK: - Key Management

    func saveAPIKey(_ key: String) {
        let data = Data(key.utf8)
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: keychainAccount,
            kSecValueData: data
        ]
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }

    func loadAPIKey() -> String? {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: keychainAccount,
            kSecReturnData: true,
            kSecMatchLimit: kSecMatchLimitOne
        ]
        var result: AnyObject?
        if SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
           let data = result as? Data,
           let key = String(data: data, encoding: .utf8),
           !key.isEmpty {
            return key
        }
        return defaultAPIKey
    }

    func deleteAPIKey() {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: keychainAccount
        ]
        SecItemDelete(query as CFDictionary)
    }

    // MARK: - Token Usage

    var totalTokensUsed: Int {
        UserDefaults.standard.integer(forKey: tokenUsageKey)
    }

    private func recordTokens(_ count: Int) {
        UserDefaults.standard.set(totalTokensUsed + count, forKey: tokenUsageKey)
    }

    // MARK: - Balance

    func checkBalance() async throws -> BalanceInfo {
        guard let apiKey = loadAPIKey() else { throw DeepSeekError.noAPIKey }
        var request = URLRequest(url: balanceEndpoint)
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 15

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw DeepSeekError.networkError(error)
        }

        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw DeepSeekError.invalidResponse
        }

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let isAvailable = json["is_available"] as? Bool,
              let balanceInfos = json["balance_infos"] as? [[String: Any]],
              let first = balanceInfos.first,
              let totalBalance = first["total_balance"] as? String,
              let currency = first["currency"] as? String else {
            throw DeepSeekError.invalidResponse
        }

        return BalanceInfo(totalBalance: totalBalance, currency: currency, isAvailable: isAvailable)
    }

    // MARK: - Chat

    func sendMessage(systemPrompt: String, userPrompt: String) async throws -> String {
        guard let apiKey = loadAPIKey(), !apiKey.isEmpty else {
            throw DeepSeekError.noAPIKey
        }

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30

        let body: [String: Any] = [
            "model": "deepseek-chat",
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": userPrompt]
            ],
            "temperature": 0.7,
            "max_tokens": 2048
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw DeepSeekError.networkError(error)
        }

        guard let http = response as? HTTPURLResponse else {
            throw DeepSeekError.invalidResponse
        }

        guard http.statusCode == 200 else {
            let message = (try? JSONSerialization.jsonObject(with: data) as? [String: Any])
                .flatMap { $0["error"] as? [String: Any] }
                .flatMap { $0["message"] as? String }
                ?? "HTTP \(http.statusCode)"
            throw DeepSeekError.apiError(message)
        }

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let message = choices.first?["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw DeepSeekError.invalidResponse
        }

        if let usage = json["usage"] as? [String: Any],
           let totalTokens = usage["total_tokens"] as? Int {
            recordTokens(totalTokens)
        }

        return content
    }
}
