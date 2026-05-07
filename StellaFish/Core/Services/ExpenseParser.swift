import Foundation

struct ParsedExpense {
    var title: String
    var amount: Double
    var category: ExpenseCategory
}

final class ExpenseParser {
    private static let separators = CharacterSet(charactersIn: "，,。；;")
    private static let connectors = ["和", "然后", "还有"]

    func parse(_ text: String) -> [ParsedExpense] {
        let segments = split(text)
        let results = segments.compactMap { parseSegment($0.trimmingCharacters(in: .whitespaces)) }
        return results.isEmpty ? [ParsedExpense(title: text, amount: 0, category: .other)] : results
    }

    private func split(_ text: String) -> [String] {
        var result = text.components(separatedBy: Self.separators)
        for connector in Self.connectors {
            result = result.flatMap { $0.components(separatedBy: connector) }
        }
        return result.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
    }

    private func parseSegment(_ segment: String) -> ParsedExpense? {
        guard !segment.isEmpty else { return nil }

        // Pattern: "...花了{amount}[元|块][{decimal}]"
        // Pattern: "...{amount}[元|块][{decimal}]"
        // Pattern: "{title}{amount}" (bare number at end)

        if let (title, amount) = extractWithKeyword(segment) {
            return ParsedExpense(title: title, amount: amount, category: inferCategory(title))
        }

        if let (title, amount) = extractBareNumber(segment) {
            return ParsedExpense(title: title, amount: amount, category: inferCategory(title))
        }

        return nil
    }

    // Matches: "...花了 32元" / "...花了 5块5" / "...花了 5.5元"
    private func extractWithKeyword(_ text: String) -> (String, Double)? {
        let pattern = #"(.+?)(?:花了约?|共花了)\s*(\d+\.?\d*)(?:[元块])(\d+)?"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) else {
            return nil
        }

        let titleRange = Range(match.range(at: 1), in: text)
        let intRange = Range(match.range(at: 2), in: text)
        let decRange = Range(match.range(at: 3), in: text)

        guard let titleRange, let intRange else { return nil }

        let title = String(text[titleRange]).trimmingCharacters(in: .whitespaces)
        var amountStr = String(text[intRange])
        if let decRange {
            amountStr += "." + String(text[decRange])
        }

        guard let amount = Double(amountStr) else { return nil }
        return (title, amount)
    }

    // Matches: "咖啡18" / "门票120" / "地铁7块" / "地铁7元"
    private func extractBareNumber(_ text: String) -> (String, Double)? {
        let pattern = #"^(.+?)\s*(\d+\.?\d*)(?:[元块](\d+)?)?$"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
              match.numberOfRanges >= 3 else {
            return nil
        }

        let titleRange = Range(match.range(at: 1), in: text)
        let intRange = Range(match.range(at: 2), in: text)
        let decRange = match.numberOfRanges > 3 ? Range(match.range(at: 3), in: text) : nil

        guard let titleRange, let intRange else { return nil }

        let title = String(text[titleRange]).trimmingCharacters(in: .whitespaces)
        guard !title.isEmpty, title != text else { return nil }

        var amountStr = String(text[intRange])
        if let decRange {
            amountStr += "." + String(text[decRange])
        }

        guard let amount = Double(amountStr) else { return nil }
        return (title, amount)
    }

    private func inferCategory(_ title: String) -> ExpenseCategory {
        let foodKeywords = ["饭", "餐", "吃", "喝", "咖啡", "奶茶", "早餐", "午餐", "晚餐", "烧饼", "水果", "面", "粥", "菜"]
        let transportKeywords = ["打车", "地铁", "公交", "滴滴", "出租", "高铁", "火车", "机票", "飞机", "船", "摆渡"]
        let accommodationKeywords = ["酒店", "住", "民宿", "宾馆", "客栈"]
        let ticketKeywords = ["门票", "景区", "博物馆", "景点"]
        let shoppingKeywords = ["买", "购", "纪念品", "商场", "超市"]

        for keyword in foodKeywords where title.contains(keyword) { return .food }
        for keyword in transportKeywords where title.contains(keyword) { return .transport }
        for keyword in accommodationKeywords where title.contains(keyword) { return .accommodation }
        for keyword in ticketKeywords where title.contains(keyword) { return .ticket }
        for keyword in shoppingKeywords where title.contains(keyword) { return .shopping }

        return .other
    }
}
