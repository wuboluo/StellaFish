import SwiftUI
import SwiftData

struct TripListView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: TripViewModel?
    @State private var showNewTrip = false
    @State private var selectedTrip: Trip? = nil
    @State private var editingTrip: Trip? = nil

    var body: some View {
        Group {
            if let vm = viewModel {
                if vm.trips.isEmpty {
                    emptyState()
                } else {
                    tripList(vm: vm)
                }
            } else {
                ProgressView()
            }
        }
        .navigationTitle("计划")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showNewTrip = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showNewTrip) {
            TripEditView(trip: nil) { _ in
                viewModel?.load()
            }
        }
        .sheet(item: $editingTrip) { trip in
            TripEditView(trip: trip) { _ in viewModel?.load() }
        }
        .navigationDestination(item: $selectedTrip) { trip in
            TripDetailView(trip: trip)
        }
        .onAppear {
            if viewModel == nil {
                let vm = TripViewModel(tripRepo: LocalTripRepository(context: modelContext))
                vm.load()
                viewModel = vm
            }
        }
    }

    private func emptyState() -> some View {
        ContentUnavailableView(
            "还没有行程",
            systemImage: "map",
            description: Text("点击右上角 + 新建你的第一个旅行计划")
        )
        .background(AppColors.background)
    }

    private func tripList(vm: TripViewModel) -> some View {
        List {
            ForEach(vm.trips) { trip in
                Button {
                    selectedTrip = trip
                } label: {
                    TripRowView(trip: trip)
                }
                .buttonStyle(.plain)
                .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button(role: .destructive) {
                        vm.delete(trip)
                    } label: {
                        Label("删除", systemImage: "trash")
                    }
                    Button {
                        editingTrip = trip
                    } label: {
                        Label("编辑", systemImage: "pencil")
                    }
                    .tint(.blue)
                }
            }
        }
        .listStyle(.plain)
        .background(AppColors.background)
        .refreshable { vm.load() }
    }
}

private struct TripRowView: View {
    let trip: Trip

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(trip.title)
                    .font(.headline)
                Spacer()
                statusBadge
            }
            Text("\(trip.fromCity) → \(trip.toCity)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            HStack(spacing: 12) {
                Label(trip.departDate.shortDateLabel, systemImage: "calendar")
                Label("\(trip.durationDays)天", systemImage: "clock")
                Label("\(trip.peopleCount)人", systemImage: "person.2")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }

    private var statusBadge: some View {
        let now = Date()
        let text: String
        let color: Color
        if trip.departDate > now {
            text = "未出发"
            color = AppColors.primary
        } else if trip.returnDate >= now {
            text = "进行中"
            color = .green
        } else {
            text = "已结束"
            color = .secondary
        }
        return Text(text)
            .font(.caption.weight(.semibold))
            .foregroundStyle(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color.opacity(0.12))
            .clipShape(Capsule())
    }
}
