import SwiftUI

struct ExpenseSummaryView: View {
    let summary: [(ExpenseCategory, Double)]
    let total: Double

    var body: some View {
        List {
            Section {
                HStack {
                    Text("总计")
                        .font(.headline)
                    Spacer()
                    Text(total.currencyString)
                        .font(.title3.weight(.bold))
                        .foregroundStyle(AppColors.accent)
                }
            }

            Section("分类明细") {
                ForEach(summary, id: \.0) { category, amount in
                    HStack {
                        Label(category.rawValue, systemImage: category.icon)
                            .foregroundStyle(.primary)
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(amount.currencyString)
                                .font(.subheadline.weight(.semibold))
                            Text(total > 0 ? "\(Int(amount / total * 100))%" : "—")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle("花费汇总")
        .navigationBarTitleDisplayMode(.inline)
    }
}
