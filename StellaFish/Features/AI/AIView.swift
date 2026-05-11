import SwiftUI
import SwiftData

struct AIView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Trip.createdAt, order: .reverse) private var trips: [Trip]
    @State private var viewModel = AIViewModel()
    @State private var showResult = false

    private var featuredTrip: Trip? {
        let now = Date()
        return trips.first { $0.departDate <= now && $0.returnDate >= now }
            ?? trips.first { $0.departDate > now }
            ?? trips.first
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if let trip = featuredTrip {
                    tripBanner(trip: trip)
                    actionButtons(trip: trip)
                } else {
                    noTripBanner()
                }

                if viewModel.isLoading {
                    ProgressView("AI 思考中…")
                        .padding(40)
                }

                if !viewModel.result.isEmpty {
                    resultCard
                }

                if let error = viewModel.errorMessage {
                    Text(error)
                        .foregroundStyle(.red)
                        .font(.subheadline)
                        .padding()
                }
            }
            .padding(16)
        }
        .background(AppColors.background)
        .navigationTitle("AI 助手")
        .navigationBarTitleDisplayMode(.large)
    }

    private func tripBanner(trip: Trip) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("当前行程")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(trip.title)
                    .font(.headline)
                Text("\(trip.fromCity) → \(trip.toCity)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "sparkles")
                .font(.system(size: 28))
                .foregroundStyle(AppColors.primaryGradient)
        }
        .padding(16)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.06), radius: 4, y: 2)
    }

    private func noTripBanner() -> some View {
        ContentUnavailableView(
            "暂无行程",
            systemImage: "sparkles",
            description: Text("请先在「行程计划」新建一个行程")
        )
    }

    private func actionButtons(trip: Trip) -> some View {
        LazyVGrid(columns: [.init(.flexible()), .init(.flexible())], spacing: 12) {
            AIActionButton(
                title: "生成行前清单",
                subtitle: "AI 生成清单模板",
                icon: "checklist",
                color: .green,
                isLoading: viewModel.isLoading
            ) {
                Task { await viewModel.generateChecklist(trip: trip) }
            }

            AIActionButton(
                title: "分析交通方案",
                subtitle: "对比票价给出推荐",
                icon: "tram.fill",
                color: AppColors.primary,
                isLoading: viewModel.isLoading
            ) {
                Task { await viewModel.analyzeTransport(trip: trip) }
            }

            AIActionButton(
                title: "目的地攻略",
                subtitle: "生成旅行攻略",
                icon: "map.fill",
                color: .orange,
                isLoading: viewModel.isLoading
            ) {
                Task { await viewModel.generateGuide(trip: trip) }
            }

            AIActionButton(
                title: "总结花费",
                subtitle: "智能分析消费",
                icon: "yensign.circle.fill",
                color: AppColors.accent,
                isLoading: viewModel.isLoading
            ) {
                Task { await viewModel.summarizeExpenses(trip: trip) }
            }
        }
    }

    private var resultCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("AI 回复", systemImage: "sparkles")
                    .font(.headline)
                Spacer()
                Button {
                    viewModel.result = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
            }
            ScrollView {
                markdownText(viewModel.result)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxHeight: 400)
        }
        .padding(16)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.06), radius: 4, y: 2)
    }

    @ViewBuilder
    private func markdownText(_ raw: String) -> some View {
        if let attributed = try? AttributedString(
            markdown: raw,
            options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)
        ) {
            Text(attributed).font(.body)
        } else {
            Text(raw).font(.body)
        }
    }
}

private struct AIActionButton: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let isLoading: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundStyle(color)
                Spacer()
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.leading)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.06), radius: 4, y: 2)
        }
        .buttonStyle(ScaleButtonStyle())
        .disabled(isLoading)
        .opacity(isLoading ? 0.6 : 1)
    }
}

