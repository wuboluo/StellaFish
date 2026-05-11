import SwiftUI

struct TicketSnapshotFormView: View {
    @Environment(\.dismiss) private var dismiss

    var snapshot: TicketSnapshot?
    var trip: Trip?
    var onSave: (TicketSnapshot) -> Void

    // Basic
    @State private var platform = "12306"
    @State private var transportType: TransportType = .highSpeedTrain
    @State private var code = ""
    @State private var price = ""
    @State private var seatStatus: SeatStatus = .notChecked
    @State private var departTime = Date()
    @State private var arriveTime = Date().addingTimeInterval(3600 * 3)
    @State private var fromStation = ""
    @State private var toStation = ""

    // Cost factors
    @State private var transferCost = ""
    @State private var transferMinutes = ""
    @State private var extraMinutes = ""
    @State private var baggageCost = ""
    @State private var riskCost = ""
    @State private var hassleCost = ""
    @State private var note = ""

    private let platforms = ["12306", "携程", "飞猪", "去哪儿", "航司官网", "其他"]
    private var isEditing: Bool { snapshot != nil }

    private var computedTotal: Double? {
        guard let trip,
              let p = Double(price), p > 0 else { return nil }
        let s = TicketSnapshot(
            transportType: transportType,
            price: p,
            seatStatus: seatStatus,
            departTime: departTime,
            arriveTime: arriveTime,
            transferCost: Double(transferCost) ?? 0,
            transferMinutes: Int(transferMinutes) ?? 0,
            extraMinutes: Int(extraMinutes),
            baggageCost: Double(baggageCost) ?? 0,
            riskCost: Double(riskCost),
            hassleCost: Double(hassleCost)
        )
        let total = s.totalCost(people: trip.peopleCount)
        return total.isFinite ? total : nil
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("基本信息") {
                    Picker("平台", selection: $platform) {
                        ForEach(platforms, id: \.self) { Text($0) }
                    }
                    Picker("交通类型", selection: $transportType) {
                        ForEach(TransportType.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                    }
                    TextField("车次/航班号", text: $code)
                    TextField("¥ 票价/人", text: $price)
                        .keyboardType(.decimalPad)
                    Picker("余票状态", selection: $seatStatus) {
                        ForEach(SeatStatus.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                    }
                }

                Section("时刻") {
                    stationRow(label: "出发站/机场", city: trip?.fromCity ?? "", text: $fromStation)
                    stationRow(label: "到达站/机场", city: trip?.toCity ?? "", text: $toStation)
                    DatePicker("出发时间", selection: $departTime)
                    DatePicker("到达时间", selection: $arriveTime, in: departTime...)
                }

                Section("费用因子") {
                    labeledField("接驳费用 (¥)", placeholder: "0", text: $transferCost)
                    labeledField("接驳耗时 (分钟)", placeholder: "\(transportType.defaultExtraMinutes)", text: $transferMinutes)
                    labeledField("额外耗时 (分钟)", placeholder: "\(transportType.defaultExtraMinutes)", text: $extraMinutes)
                    labeledField("行李费用 (¥)", placeholder: "0", text: $baggageCost)
                    labeledField("误点风险 (¥)", placeholder: "\(Int(transportType.defaultRiskCost))", text: $riskCost)
                    labeledField("折腾成本 (¥)", placeholder: "\(Int(transportType.defaultHassleCost))", text: $hassleCost)
                }

                if let total = computedTotal, let trip {
                    Section {
                        HStack {
                            Text("综合总费用 (\(trip.peopleCount)人)")
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(total.currencyString)
                                .font(.headline)
                                .foregroundStyle(AppColors.accent)
                        }
                    } header: {
                        Text("实时计算")
                    }
                }

                Section("备注") {
                    TextField("可选", text: $note, axis: .vertical)
                        .lineLimit(2...4)
                }
            }
            .navigationTitle(isEditing ? "编辑快照" : "添加快照")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") { save() }
                }
            }
        }
        .onAppear { populateIfEditing() }
        .onChange(of: transportType) { _, newType in
            if extraMinutes.isEmpty { extraMinutes = "\(newType.defaultExtraMinutes)" }
            if riskCost.isEmpty { riskCost = "\(Int(newType.defaultRiskCost))" }
            if hassleCost.isEmpty { hassleCost = "\(Int(newType.defaultHassleCost))" }
        }
    }

    @ViewBuilder
    private func stationRow(label: String, city: String, text: Binding<String>) -> some View {
        let stations = StationData.stations(for: city, transportType: transportType)
        if stations.isEmpty || !transportType.supportsStationPicker {
            TextField(label, text: text)
        } else {
            Picker(label, selection: text) {
                Text("请选择").tag("")
                ForEach(stations, id: \.self) { Text($0).tag($0) }
            }
        }
    }

    private func labeledField(_ label: String, placeholder: String, text: Binding<String>) -> some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            TextField(placeholder, text: text)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 80)
        }
    }

    private func populateIfEditing() {
        guard let s = snapshot else { return }
        platform = s.platform
        transportType = s.transportType
        code = s.code
        price = String(s.price)
        seatStatus = s.seatStatus
        departTime = s.departTime
        arriveTime = s.arriveTime
        fromStation = s.fromStation
        toStation = s.toStation
        transferCost = s.transferCost > 0 ? String(s.transferCost) : ""
        transferMinutes = s.transferMinutes > 0 ? String(s.transferMinutes) : ""
        extraMinutes = String(s.extraMinutes)
        baggageCost = s.baggageCost > 0 ? String(s.baggageCost) : ""
        riskCost = String(s.riskCost)
        hassleCost = String(s.hassleCost)
        note = s.note
    }

    private func save() {
        if let existing = snapshot {
            existing.platform = platform
            existing.transportType = transportType
            existing.code = code
            existing.price = Double(price) ?? existing.price
            existing.seatStatus = seatStatus
            existing.departTime = departTime
            existing.arriveTime = arriveTime
            existing.fromStation = fromStation
            existing.toStation = toStation
            existing.transferCost = Double(transferCost) ?? 0
            existing.transferMinutes = Int(transferMinutes) ?? 0
            existing.extraMinutes = Int(extraMinutes) ?? transportType.defaultExtraMinutes
            existing.baggageCost = Double(baggageCost) ?? 0
            existing.riskCost = Double(riskCost) ?? transportType.defaultRiskCost
            existing.hassleCost = Double(hassleCost) ?? transportType.defaultHassleCost
            existing.note = note
            onSave(existing)
        } else {
            let s = TicketSnapshot(
                platform: platform,
                transportType: transportType,
                code: code,
                price: Double(price) ?? 0,
                seatStatus: seatStatus,
                departTime: departTime,
                arriveTime: arriveTime,
                fromStation: fromStation,
                toStation: toStation,
                transferCost: Double(transferCost) ?? 0,
                transferMinutes: Int(transferMinutes) ?? 0,
                extraMinutes: Int(extraMinutes),
                baggageCost: Double(baggageCost) ?? 0,
                riskCost: Double(riskCost),
                hassleCost: Double(hassleCost),
                note: note
            )
            onSave(s)
        }
        dismiss()
    }
}
