import SwiftUI

struct CostComparisonView: View {
    @Environment(\.dismiss) private var dismiss
    let snapshots: [TicketSnapshot]
    let trip: Trip?

    private var sorted: [TicketSnapshot] {
        let people = trip?.peopleCount ?? 1
        return snapshots.sorted { a, b in
            let ca = a.totalCost(people: people)
            let cb = b.totalCost(people: people)
            if ca.isInfinite && cb.isInfinite { return false }
            if ca.isInfinite { return false }
            if cb.isInfinite { return true }
            return ca < cb
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    if let trip {
                        costNote(trip: trip)
                    }
                    ForEach(Array(sorted.enumerated()), id: \.element.id) { rank, snapshot in
                        ComparisonCard(
                            rank: rank + 1,
                            snapshot: snapshot,
                            trip: trip,
                            isTop: rank == 0
                        )
                    }
                }
                .padding(16)
            }
            .background(AppColors.background)
            .navigationTitle("方案比较")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") { dismiss() }
                }
            }
        }
    }

    private func costNote(trip: Trip) -> some View {
        Text("综合费用 = 票价 × \(trip.peopleCount)人 + 接驳/行李/误点/折腾")
            .font(.caption)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
            .padding(.horizontal)
    }
}

private struct ComparisonCard: View {
    let rank: Int
    let snapshot: TicketSnapshot
    let trip: Trip?
    let isTop: Bool

    private var totalCost: Double {
        snapshot.totalCost(people: trip?.peopleCount ?? 1)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                // Rank badge
                Text(isTop ? "👑" : "#\(rank)")
                    .font(isTop ? .title2 : .headline)
                VStack(alignment: .leading, spacing: 2) {
                    Text(snapshot.code.isEmpty ? snapshot.transportType.rawValue : "\(snapshot.transportType.rawValue) \(snapshot.code)")
                        .font(.headline)
                    Text(snapshot.platform)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    if totalCost.isInfinite {
                        Text("无票")
                            .font(.headline)
                            .foregroundStyle(.red)
                    } else {
                        Text(totalCost.currencyString)
                            .font(.title3.weight(.bold))
                            .foregroundStyle(isTop ? AppColors.primary : .primary)
                        Text("综合费用")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Divider()

            LazyVGrid(columns: [.init(.flexible()), .init(.flexible()), .init(.flexible())], spacing: 8) {
                costItem("票价/人", value: snapshot.price.currencyString)
                costItem("耗时", value: "\(snapshot.doorToDoorMinutes)分钟")
                costItem("余票", value: snapshot.seatStatus.rawValue)
                if snapshot.transferCost > 0 {
                    costItem("接驳", value: snapshot.transferCost.currencyString)
                }
                if snapshot.baggageCost > 0 {
                    costItem("行李", value: snapshot.baggageCost.currencyString)
                }
            }
        }
        .padding(16)
        .background(isTop ? AppColors.primary.opacity(0.06) : Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(isTop ? AppColors.primary.opacity(0.3) : Color.clear, lineWidth: 1.5)
        )
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }

    private func costItem(_ label: String, value: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.caption.weight(.semibold))
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}
