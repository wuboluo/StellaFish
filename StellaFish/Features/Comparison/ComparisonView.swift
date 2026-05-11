import SwiftUI
import SwiftData

struct ComparisonView: View {
    @Query(sort: \Trip.departDate) private var trips: [Trip]
    @State private var selectedTripID: UUID? = nil
    @State private var selectedTask: TransportTask? = nil
    @State private var editingHotel: HotelCandidate? = nil
    @State private var showAddTransport = false
    @State private var showAddHotel = false
    @Environment(\.modelContext) private var modelContext

    private var selectedTrip: Trip? {
        if let id = selectedTripID { return trips.first { $0.id == id } }
        let now = Date()
        return trips.first { $0.departDate <= now && $0.returnDate >= now }
            ?? trips.first { $0.departDate > now }
            ?? trips.first
    }

    var body: some View {
        Group {
            if trips.isEmpty {
                emptyNoTrips
            } else if let trip = selectedTrip {
                comparisonContent(trip: trip)
            } else {
                ProgressView()
            }
        }
        .navigationTitle("对比")
        .navigationBarTitleDisplayMode(.large)
        .background(AppColors.background)
        .toolbar {
            if !trips.isEmpty {
                ToolbarItem(placement: .principal) { tripPicker }
            }
        }
    }

    // MARK: - Trip Picker

    private var tripPicker: some View {
        Menu {
            ForEach(trips) { trip in
                Button {
                    selectedTripID = trip.id
                } label: {
                    HStack {
                        Text(trip.title)
                        if trip.id == selectedTrip?.id { Image(systemName: "checkmark") }
                    }
                }
            }
        } label: {
            HStack(spacing: 4) {
                Text(selectedTrip?.title ?? "选择行程")
                    .font(.subheadline.weight(.semibold))
                Image(systemName: "chevron.down").font(.caption2)
            }
            .foregroundStyle(AppColors.primary)
        }
    }

    // MARK: - Main Content

    private func comparisonContent(trip: Trip) -> some View {
        ScrollView {
            VStack(spacing: 24) {
                transportSection(trip: trip)
                hotelSection(trip: trip)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .padding(.bottom, 20)
        }
    }

    // MARK: - Transport Section

    private func transportSection(trip: Trip) -> some View {
        let tasks = trip.transportTasks.sorted { $0.date < $1.date }
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("交通方案", systemImage: "tram.fill")
                    .font(.headline)
                Spacer()
                NavigationLink {
                    TransportTaskListView(trip: trip)
                        .navigationTitle("查票管理")
                } label: {
                    Text("管理").font(.caption).foregroundStyle(AppColors.primary)
                }
            }

            if tasks.isEmpty {
                emptyCard(
                    icon: "tram.fill",
                    title: "暂无交通方案",
                    subtitle: "点击「管理」添加查票任务，对比多个出行方案",
                    color: AppColors.primary
                )
            } else {
                ForEach(tasks) { task in
                    transportTaskGroup(task: task, trip: trip)
                }
            }
        }
    }

    private func transportTaskGroup(task: TransportTask, trip: Trip) -> some View {
        let snapshots = task.snapshots.sorted {
            $0.totalCost(people: trip.peopleCount, timeValuePerHour: trip.timeValuePerHour)
            < $1.totalCost(people: trip.peopleCount, timeValuePerHour: trip.timeValuePerHour)
        }
        let bestID = snapshots.first?.id

        return VStack(alignment: .leading, spacing: 8) {
            // Task header
            HStack {
                Image(systemName: task.primaryTransportType.icon)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(AppColors.primary)
                Text(task.title)
                    .font(.subheadline.weight(.semibold))
                Text("·")
                    .foregroundStyle(.secondary)
                Text(task.date, format: .dateTime.month().day())
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                NavigationLink {
                    TransportTaskDetailView(task: task, vm: TransportViewModel(trip: trip, context: modelContext))
                        .navigationTitle(task.title)
                } label: {
                    Text("详情").font(.caption2).foregroundStyle(AppColors.primary)
                }
            }
            .padding(.horizontal, 2)

            if snapshots.isEmpty {
                Text("暂无方案，前往「详情」添加")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.sm))
            } else {
                ForEach(snapshots) { snapshot in
                    SnapshotComparisonCard(
                        snapshot: snapshot,
                        trip: trip,
                        isBest: snapshot.id == bestID
                    )
                }
            }
        }
    }

    // MARK: - Hotel Section

    private func hotelSection(trip: Trip) -> some View {
        let hotels = trip.hotelCandidates.sorted {
            $0.totalPrice < $1.totalPrice
        }
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("酒店候选", systemImage: "bed.double.fill")
                    .font(.headline)
                Spacer()
                NavigationLink {
                    HotelListView(trip: trip)
                        .navigationTitle("酒店管理")
                } label: {
                    Text("管理").font(.caption).foregroundStyle(AppColors.primary)
                }
            }

            if hotels.isEmpty {
                emptyCard(
                    icon: "bed.double.fill",
                    title: "暂无酒店候选",
                    subtitle: "点击「管理」添加候选酒店，对比位置、价格和交通",
                    color: .orange
                )
            } else {
                ForEach(hotels) { hotel in
                    HotelComparisonCard(hotel: hotel, trip: trip)
                }
            }
        }
    }

    // MARK: - Empty States

    private var emptyNoTrips: some View {
        ContentUnavailableView(
            "还没有行程",
            systemImage: "arrow.left.arrow.right",
            description: Text("在「计划」中新建一个旅行计划，再来对比交通和酒店方案")
        )
        .background(AppColors.background)
    }

    private func emptyCard(icon: String, title: String, subtitle: String, color: Color) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundStyle(color)
                .frame(width: 44, height: 44)
                .background(color.opacity(0.1))
                .clipShape(Circle())
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.subheadline.weight(.medium))
                Text(subtitle).font(.caption).foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
        .softShadow()
    }
}

// MARK: - Snapshot Comparison Card

private struct SnapshotComparisonCard: View {
    let snapshot: TicketSnapshot
    let trip: Trip
    let isBest: Bool
    @State private var expanded = false

    private var totalCost: Double {
        snapshot.totalCost(people: trip.peopleCount, timeValuePerHour: trip.timeValuePerHour)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Main row
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 3) {
                        HStack(spacing: 6) {
                            Text(snapshot.code.isEmpty ? "方案" : snapshot.code)
                                .font(.subheadline.weight(.bold))
                            Text(snapshot.platform.isEmpty ? "" : "· \(snapshot.platform)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        HStack(spacing: 4) {
                            Text(snapshot.fromStation.isEmpty ? "出发站" : snapshot.fromStation)
                                .font(.caption)
                            Image(systemName: "arrow.right").font(.caption2)
                            Text(snapshot.toStation.isEmpty ? "到达站" : snapshot.toStation)
                                .font(.caption)
                        }
                        .foregroundStyle(.secondary)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 4) {
                        if isBest {
                            Label("最优", systemImage: "star.fill")
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 7)
                                .padding(.vertical, 3)
                                .background(Color.green)
                                .clipShape(Capsule())
                        }
                        seatBadge
                    }
                }

                HStack(spacing: 0) {
                    timeBlock(
                        time: snapshot.departTime,
                        label: "出发"
                    )
                    Spacer()
                    VStack(spacing: 2) {
                        Divider()
                        Text(durationString(snapshot.mainDurationMinutes))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: 80)
                    Spacer()
                    timeBlock(
                        time: snapshot.arriveTime,
                        label: "到达"
                    )
                }

                HStack {
                    priceTag(label: "票价/人", value: snapshot.price.currencyString, color: AppColors.primary)
                    if snapshot.transferCost > 0 {
                        priceTag(label: "接驳", value: snapshot.transferCost.currencyString, color: .secondary)
                    }
                    Spacer()
                    priceTag(label: "综合费用", value: totalCost.currencyShortString, color: AppColors.accent)
                }
            }
            .padding(14)

            // Expandable detail
            if expanded {
                Divider().padding(.horizontal, 14)
                VStack(alignment: .leading, spacing: 6) {
                    detailRow("门到门", value: "\(snapshot.doorToDoorMinutes)分钟")
                    if snapshot.baggageCost > 0 {
                        detailRow("行李费", value: snapshot.baggageCost.currencyString)
                    }
                    if snapshot.riskCost > 0 {
                        detailRow("风险成本", value: snapshot.riskCost.currencyString)
                    }
                    if snapshot.hassleCost > 0 {
                        detailRow("折腾成本", value: snapshot.hassleCost.currencyString)
                    }
                    if !snapshot.note.isEmpty {
                        detailRow("备注", value: snapshot.note)
                    }
                }
                .padding(14)
            }

            // Expand toggle
            Button {
                withAnimation(.easeInOut(duration: 0.2)) { expanded.toggle() }
            } label: {
                HStack {
                    Text(expanded ? "收起" : "查看详情")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Image(systemName: expanded ? "chevron.up" : "chevron.down")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(Color(.systemGray6).opacity(0.6))
            }
            .clipShape(
                .rect(bottomLeadingRadius: AppRadius.md, bottomTrailingRadius: AppRadius.md)
            )
        }
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.md)
                .stroke(isBest ? Color.green.opacity(0.4) : Color.clear, lineWidth: 1.5)
        )
        .softShadow()
    }

    private var seatBadge: some View {
        let (text, color) = seatInfo(snapshot.seatStatus)
        return Text(text)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(color)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(color.opacity(0.12))
            .clipShape(Capsule())
    }

    private func seatInfo(_ status: SeatStatus) -> (String, Color) {  // swiftlint:disable:this cyclomatic_complexity
        switch status {
        case .available:  return ("余票充足", .green)
        case .scarce:     return ("票量紧张", .orange)
        case .waitlist:   return ("候补", .red)
        case .noTicket:   return ("无票", Color(.systemGray))
        case .notChecked: return ("未查询", .secondary)
        }
    }

    private func timeBlock(time: Date, label: String) -> some View {
        VStack(alignment: .center, spacing: 2) {
            Text(time, format: .dateTime.hour().minute())
                .font(.headline.monospacedDigit())
            Text(label).font(.caption2).foregroundStyle(.secondary)
        }
    }

    private func priceTag(label: String, value: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(value).font(.subheadline.weight(.semibold)).foregroundStyle(color)
            Text(label).font(.caption2).foregroundStyle(.secondary)
        }
    }

    private func detailRow(_ label: String, value: String) -> some View {
        HStack {
            Text(label).font(.caption).foregroundStyle(.secondary)
            Spacer()
            Text(value).font(.caption.weight(.medium))
        }
    }

    private func durationString(_ minutes: Int) -> String {
        let h = minutes / 60
        let m = minutes % 60
        if h == 0 { return "\(m)分" }
        if m == 0 { return "\(h)小时" }
        return "\(h)h\(m)m"
    }
}

// MARK: - Hotel Comparison Card

private struct HotelComparisonCard: View {
    let hotel: HotelCandidate
    let trip: Trip

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(hotel.name)
                        .font(.subheadline.weight(.bold))
                        .lineLimit(1)
                    if !hotel.brand.isEmpty {
                        Text(hotel.brand)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    if !hotel.address.isEmpty {
                        Label(hotel.address, systemImage: "mappin")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
                Spacer()
                bookingBadge
            }

            Divider()

            HStack(spacing: 20) {
                priceBlock("每晚", hotel.pricePerNight.currencyShortString)
                priceBlock("总价", hotel.totalPrice.currencyShortString)
                priceBlock("\(hotel.nights)晚", "共住")
            }

            if !hotel.distanceNote.isEmpty || !hotel.trafficNote.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    if !hotel.distanceNote.isEmpty {
                        Label(hotel.distanceNote, systemImage: "mappin.and.ellipse")
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

            if !hotel.ratingNote.isEmpty {
                Text(hotel.ratingNote)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.systemGray6).opacity(0.8))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            if hotel.latitude != nil, let lat = hotel.latitude, let lng = hotel.longitude {
                Button {
                    AMapService.shared.openInMap(
                        coordinate: .init(latitude: lat, longitude: lng),
                        name: hotel.name
                    )
                } label: {
                    Label("在地图中查看", systemImage: "map")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(AppColors.primary)
                }
            }
        }
        .padding(14)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.md)
                .stroke(hotel.bookingStatus == .booked ? Color.green.opacity(0.4) : Color.clear, lineWidth: 1.5)
        )
        .softShadow()
    }

    private var bookingBadge: some View {
        let (text, color): (String, Color) = {
            switch hotel.bookingStatus {
            case .booked:    return ("已预订", .green)
            case .abandoned: return ("已放弃", .secondary)
            case .notBooked: return ("未预订", AppColors.primary)
            }
        }()
        return Text(text)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.12))
            .clipShape(Capsule())
    }

    private func priceBlock(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value).font(.subheadline.weight(.bold)).foregroundStyle(.primary)
            Text(label).font(.caption2).foregroundStyle(.secondary)
        }
    }
}

// MARK: - TransportType Icon

extension TransportType {
    var icon: String {
        switch self {
        case .plane:          return "airplane"
        case .highSpeedTrain: return "tram.fill"
        case .bus:            return "bus"
        case .selfDrive:      return "car.fill"
        case .other:          return "figure.walk"
        }
    }
}
