import SwiftUI
import SwiftData

struct HotelListView: View {
    @Environment(\.modelContext) private var modelContext
    let trip: Trip
    @State private var viewModel: HotelViewModel?
    @State private var showAdd = false
    @State private var editingHotel: HotelCandidate?

    var body: some View {
        Group {
            if let vm = viewModel {
                if vm.candidates.isEmpty {
                    emptyState()
                } else {
                    hotelList(vm: vm)
                }
            } else {
                ProgressView()
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button { showAdd = true } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showAdd) {
            HotelFormView(hotel: nil) { hotel in
                viewModel?.save(hotel)
            }
        }
        .sheet(item: $editingHotel) { hotel in
            HotelFormView(hotel: hotel) { _ in
                viewModel?.update()
            }
        }
        .onAppear {
            if viewModel == nil {
                let vm = HotelViewModel(trip: trip, context: modelContext)
                vm.load()
                viewModel = vm
            }
        }
    }

    private func emptyState() -> some View {
        ContentUnavailableView(
            "暂无酒店候选",
            systemImage: "bed.double.fill",
            description: Text("点击 + 添加酒店候选，对比价格和位置")
        )
        .background(AppColors.background)
    }

    private func hotelList(vm: HotelViewModel) -> some View {
        List {
            ForEach(vm.grouped, id: \.0) { status, hotels in
                Section {
                    ForEach(hotels) { hotel in
                        HotelRowView(hotel: hotel, vm: vm)
                            .contentShape(Rectangle())
                            .onTapGesture { editingHotel = hotel }
                    }
                    .onDelete { indexSet in
                        indexSet.forEach { vm.delete(hotels[$0]) }
                    }
                } header: {
                    Text(status.rawValue)
                }
            }
        }
        .background(AppColors.background)
    }
}

private struct HotelRowView: View {
    let hotel: HotelCandidate
    var vm: HotelViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(hotel.name)
                        .font(.headline)
                    if !hotel.brand.isEmpty {
                        Text(hotel.brand)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("¥\(Int(hotel.pricePerNight))/晚")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppColors.accent)
                    Text("共\(hotel.nights)晚 = \(hotel.totalPrice.currencyString)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            if !hotel.distanceNote.isEmpty || !hotel.trafficNote.isEmpty {
                HStack(spacing: 8) {
                    if !hotel.distanceNote.isEmpty {
                        Label(hotel.distanceNote, systemImage: "mappin.circle")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    if !hotel.trafficNote.isEmpty {
                        Label(hotel.trafficNote, systemImage: "tram")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            // Booking status picker
            Picker("状态", selection: Binding(
                get: { hotel.bookingStatus },
                set: { hotel.bookingStatus = $0; vm.update() }
            )) {
                ForEach(BookingStatus.allCases, id: \.self) { Text($0.rawValue).tag($0) }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
        }
        .padding(.vertical, 4)
    }
}
