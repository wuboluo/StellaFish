import Foundation
import SwiftData
import Observation

@Observable
final class AIViewModel {
    var isLoading = false
    var result: String = ""
    var errorMessage: String?

    private let service = DeepSeekService.shared

    func generateChecklist(trip: Trip) async {
        await call(
            system: "你是旅行助手。根据行程信息生成一份出发前必备清单，以JSON数组返回，每个元素包含title和category字段（category取值：证件/数码/衣物/药品/订票/酒店/景点/其他）。直接返回JSON，不要加说明。",
            user: "行程：\(trip.title)，\(trip.fromCity)→\(trip.toCity)，\(trip.durationDays)天，\(trip.peopleCount)人，出发日期：\(trip.departDate.shortDateLabel)"
        )
    }

    func analyzeTransport(trip: Trip) async {
        let snapshots = trip.transportTasks.flatMap { $0.snapshots }
        guard !snapshots.isEmpty else {
            errorMessage = "请先添加交通任务和票价快照"
            return
        }
        let summary = snapshots.map { s in
            "\(s.transportType.rawValue) \(s.code.isEmpty ? "" : s.code) 票价¥\(s.price) 余票:\(s.seatStatus.rawValue) 综合费用:¥\(Int(s.totalCost(people: trip.peopleCount)))"
        }.joined(separator: "\n")

        await call(
            system: "你是旅行助手。根据多个交通方案的数据，从综合性价比角度给出推荐和分析理由，语言简洁。",
            user: "行程：\(trip.fromCity)→\(trip.toCity)，各方案数据：\n\(summary)"
        )
    }

    func generateGuide(trip: Trip) async {
        await call(
            system: "你是旅行助手。根据目的地、日期和人数，生成一份简洁实用的目的地旅行攻略，包含：必去景点、当地美食、交通贴士、注意事项。",
            user: "目的地：\(trip.toCity)，出发：\(trip.departDate.shortDateLabel)，返回：\(trip.returnDate.shortDateLabel)，\(trip.durationDays)天，\(trip.peopleCount)人"
        )
    }

    func summarizeExpenses(trip: Trip) async {
        guard !trip.expenses.isEmpty else {
            errorMessage = "这个行程还没有花费记录"
            return
        }
        let lines = trip.expenses.map { e in
            "\(e.title) ¥\(e.amount) [\(e.category.rawValue)]"
        }.joined(separator: "\n")

        await call(
            system: "你是旅行助手。根据花费清单生成一段自然语言的花费总结，包含总计、主要消费类别和简短点评。",
            user: "行程：\(trip.title)，花费记录：\n\(lines)"
        )
    }

    private func call(system: String, user: String) async {
        isLoading = true
        errorMessage = nil
        result = ""
        do {
            result = try await service.sendMessage(systemPrompt: system, userPrompt: user)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
