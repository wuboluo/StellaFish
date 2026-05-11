import SwiftUI
import SwiftData
import PhotosUI

// MARK: - Transport Records Tab (交通)

struct TransportRecordView: View {
    @Environment(\.modelContext) private var ctx
    @Environment(AppState.self) private var appState
    @Query(sort: \Trip.departDate) private var trips: [Trip]
    @Query(sort: \TrainTicketRecord.createdAt, order: .reverse) private var allTrains: [TrainTicketRecord]
    @Query(sort: \FlightTicketRecord.createdAt, order: .reverse) private var allFlights: [FlightTicketRecord]
    @Query(sort: \MetroRecord.createdAt, order: .reverse) private var allMetros: [MetroRecord]

    @State private var showAddSheet = false
    @State private var addType: TransportType2? = nil
    @State private var editingTrain: TrainTicketRecord? = nil
    @State private var editingFlight: FlightTicketRecord? = nil
    @State private var editingMetro: MetroRecord? = nil
    @State private var listID = UUID()

    enum TransportType2 { case train, flight, metro }

    private var activeTrip: Trip? {
        guard let id = appState.activeTripID else { return nil }
        return trips.first { $0.id == id }
    }
    private var trains: [TrainTicketRecord] {
        guard let t = activeTrip else { return [] }
        return allTrains.filter { $0.trip?.id == t.id }
    }
    private var flights: [FlightTicketRecord] {
        guard let t = activeTrip else { return [] }
        return allFlights.filter { $0.trip?.id == t.id }
    }
    private var metros: [MetroRecord] {
        guard let t = activeTrip else { return [] }
        return allMetros.filter { $0.trip?.id == t.id }
    }

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()
            if activeTrip == nil {
                noTripState
            } else if trains.isEmpty && flights.isEmpty && metros.isEmpty {
                emptyState
            } else {
                recordList
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { listID = UUID() }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button { addType = .train } label: { Label("高铁/动车", systemImage: "tram") }
                    Button { addType = .flight } label: { Label("飞机", systemImage: "airplane") }
                    Button { addType = .metro } label: { Label("地铁路线", systemImage: "figure.walk") }
                } label: {
                    Image(systemName: "plus")
                }
                .disabled(activeTrip == nil)
            }
        }
        .sheet(item: $addType) { type in
            switch type {
            case .train:  TrainTicketFormView(trip: activeTrip)
            case .flight: FlightTicketFormView(trip: activeTrip)
            case .metro:  MetroFormView(trip: activeTrip)
            }
        }
        .sheet(item: $editingTrain) { t in TrainTicketFormView(editing: t) }
        .sheet(item: $editingFlight) { f in FlightTicketFormView(editing: f) }
        .sheet(item: $editingMetro) { m in MetroFormView(editing: m) }
    }

    // MARK: - List

    private var recordList: some View {
        List {
            if !trains.isEmpty {
                Section("高铁 / 动车") {
                    ForEach(trains) { t in
                        TrainCard(ticket: t)
                            .onTapGesture { editingTrain = t }
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) { ctx.delete(t) } label: { Label("删除", systemImage: "trash") }
                            }
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                            .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                    }
                }
            }
            if !flights.isEmpty {
                Section("飞机") {
                    ForEach(flights) { f in
                        FlightCard(ticket: f)
                            .onTapGesture { editingFlight = f }
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) { ctx.delete(f) } label: { Label("删除", systemImage: "trash") }
                            }
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                            .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                    }
                }
            }
            if !metros.isEmpty {
                Section("地铁路线") {
                    ForEach(metros) { m in
                        MetroCard(metro: m)
                            .onTapGesture { editingMetro = m }
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) { ctx.delete(m) } label: { Label("删除", systemImage: "trash") }
                            }
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                            .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                    }
                }
            }
        }
        .listStyle(.plain)
        .id(listID)
    }

    private var noTripState: some View {
        ContentUnavailableView("未选择旅行", systemImage: "tram", description: Text("请先在「旅行」页选择一个旅行"))
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "tram.fill").font(.system(size: 44)).foregroundStyle(AppColors.primary.opacity(0.4))
            Text("暂无交通记录").font(.headline)
            Text("添加高铁、飞机或地铁路线").font(.subheadline).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

extension TransportRecordView.TransportType2: Identifiable {
    var id: Int { hashValue }
}

// MARK: - Train Card

struct TrainCard: View {
    let ticket: TrainTicketRecord
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: "tram.fill").font(.caption).foregroundStyle(AppColors.primary)
                Text(ticket.trainNo.isEmpty ? "高铁/动车" : ticket.trainNo)
                    .font(.subheadline.weight(.semibold))
                Spacer()
                statusBadge(ticket.ticketStatus)
            }
            HStack(spacing: 6) {
                Text(ticket.departStation.isEmpty ? "出发站" : ticket.departStation).font(.subheadline)
                Image(systemName: "arrow.right").font(.caption2).foregroundStyle(.secondary)
                Text(ticket.arriveStation.isEmpty ? "到达站" : ticket.arriveStation).font(.subheadline)
            }
            HStack(spacing: 10) {
                if let d = ticket.departDate {
                    Label(d.formatted(date: .abbreviated, time: .omitted), systemImage: "calendar")
                        .font(.caption).foregroundStyle(.secondary)
                }
                if !ticket.departTime.isEmpty {
                    Text("\(ticket.departTime) → \(ticket.arriveTime)")
                        .font(.caption).foregroundStyle(.secondary)
                }
                if !ticket.departTime.isEmpty, !ticket.arriveTime.isEmpty,
                   let dur = travelDuration(ticket.departTime, ticket.arriveTime) {
                    Text(dur).font(.caption).foregroundStyle(.secondary)
                }
                if !ticket.seatType.isEmpty {
                    Text(ticket.seatType).font(.caption).foregroundStyle(.secondary)
                }
                if ticket.ticketPrice > 0 {
                    Text(String(format: "¥%.0f", ticket.ticketPrice))
                        .font(.caption.weight(.medium))
                        .foregroundStyle(AppColors.primary)
                }
            }
        }
        .padding(12)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
        .softShadow()
    }
}

// MARK: - Flight Card

struct FlightCard: View {
    let ticket: FlightTicketRecord
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: "airplane").font(.caption).foregroundStyle(AppColors.primary)
                Text([ticket.airline, ticket.flightNo].filter { !$0.isEmpty }.joined(separator: " "))
                    .font(.subheadline.weight(.semibold))
                Spacer()
                statusBadge(ticket.ticketStatus)
            }
            HStack(spacing: 6) {
                VStack(alignment: .leading, spacing: 1) {
                    Text(ticket.departAirport.isEmpty ? "出发" : ticket.departAirport).font(.subheadline)
                    if !ticket.departTerminal.isEmpty {
                        Text(ticket.departTerminal).font(.caption2).foregroundStyle(.secondary)
                    }
                }
                Image(systemName: "arrow.right").font(.caption2).foregroundStyle(.secondary)
                VStack(alignment: .leading, spacing: 1) {
                    Text(ticket.arriveAirport.isEmpty ? "到达" : ticket.arriveAirport).font(.subheadline)
                    if !ticket.arriveTerminal.isEmpty {
                        Text(ticket.arriveTerminal).font(.caption2).foregroundStyle(.secondary)
                    }
                }
            }
            HStack(spacing: 10) {
                if let d = ticket.departDate {
                    Label(d.formatted(date: .abbreviated, time: .omitted), systemImage: "calendar")
                        .font(.caption).foregroundStyle(.secondary)
                }
                if !ticket.departTime.isEmpty {
                    Text("\(ticket.departTime) → \(ticket.arriveTime)")
                        .font(.caption).foregroundStyle(.secondary)
                }
                if !ticket.departTime.isEmpty, !ticket.arriveTime.isEmpty,
                   let dur = travelDuration(ticket.departTime, ticket.arriveTime) {
                    Text(dur).font(.caption).foregroundStyle(.secondary)
                }
                if ticket.ticketPrice > 0 {
                    Text(String(format: "¥%.0f", ticket.ticketPrice))
                        .font(.caption.weight(.medium))
                        .foregroundStyle(AppColors.primary)
                }
            }
            if !ticket.baggageInfo.isEmpty {
                baggageBadge(ticket.baggageInfo)
            }
        }
        .padding(12)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
        .softShadow()
    }

    private func baggageBadge(_ info: String) -> some View {
        let isRestricted = info.contains("无免费") || info.contains("仅手提") || info.contains("无托运")
        let isNeutral = info == "未识别"
        let color: Color = isNeutral ? .secondary : (isRestricted ? AppColors.error : AppColors.success)
        return Label(info, systemImage: "bag")
            .font(.caption)
            .foregroundStyle(color)
    }
}

// MARK: - Metro Card

struct MetroCard: View {
    let metro: MetroRecord
    @State private var copied = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(metro.title.isEmpty ? "地铁路线" : metro.title)
                .font(.subheadline.weight(.semibold))
            if !metro.fromStation.isEmpty || !metro.toStation.isEmpty {
                HStack(spacing: 6) {
                    Text(metro.fromStation).font(.caption)
                    Image(systemName: "arrow.right").font(.caption2).foregroundStyle(.secondary)
                    Text(metro.toStation).font(.caption)
                }
                .foregroundStyle(.secondary)
            }
            if !metro.lineInfo.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "tram").font(.caption2)
                    Text(metro.lineInfo).font(.caption)
                }
                .foregroundStyle(AppColors.primary)
            }
            HStack(spacing: 6) {
                if !metro.exitInfo.isEmpty { Text(metro.exitInfo).font(.caption).foregroundStyle(.secondary) }
                if !metro.estimatedDuration.isEmpty {
                    Text("约 \(metro.estimatedDuration)").font(.caption).foregroundStyle(.secondary)
                }
            }
            HStack(spacing: 8) {
                Button {
                    let text = [metro.lineInfo, metro.direction, metro.transferInfo, metro.exitInfo, metro.note]
                        .filter { !$0.isEmpty }.joined(separator: "\n")
                    UIPasteboard.general.string = text
                    copied = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { copied = false }
                } label: {
                    Text(copied ? "已复制" : "复制路线")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(AppColors.primary)
                        .padding(.horizontal, 10).padding(.vertical, 4)
                        .background(AppColors.primary.opacity(0.1))
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)

                Button {
                    UIPasteboard.general.string = metro.toStation
                } label: {
                    Text("复制终点站")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 10).padding(.vertical, 4)
                        .background(Color.secondary.opacity(0.1))
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(12)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
        .softShadow()
    }
}

// MARK: - Status Badge

func statusBadge(_ status: String) -> some View {
    let color: Color
    switch status {
    case "已购买": color = AppColors.success
    case "候补": color = AppColors.warning
    case "无票": color = AppColors.error
    case "未购买": color = .secondary
    default: color = AppColors.primary
    }
    return Text(status.isEmpty ? "待确认" : status)
        .font(.caption2.weight(.semibold))
        .foregroundStyle(color)
        .padding(.horizontal, 7).padding(.vertical, 3)
        .background(color.opacity(0.12))
        .clipShape(Capsule())
}

// MARK: - Train Form

struct TrainTicketFormView: View {
    @Environment(\.modelContext) private var ctx
    @Environment(\.dismiss) private var dismiss
    var editing: TrainTicketRecord? = nil
    var trip: Trip? = nil

    @State private var trainNo = ""
    @State private var departStation = ""
    @State private var arriveStation = ""
    @State private var departDate: Date = defaultDate2026
    @State private var departTime = ""
    @State private var arriveTime = ""
    @State private var seatType = "二等座"
    @State private var ticketPrice = ""
    @State private var ticketStatus = "未购买"
    @State private var note = ""

    @State private var selectedPhoto: PhotosPickerItem? = nil
    @State private var isOCRing = false
    @State private var ocrFailed = false
    @State private var showOCRText = false
    @State private var ocrText = ""

    private let seatTypes = ["二等座", "一等座", "商务座", "无座", "软卧", "硬卧", "硬座"]
    private let statuses = ["已购买", "未购买", "候补", "无票", "待确认"]

    static var defaultDate2026: Date {
        var comps = DateComponents()
        comps.year = 2026
        comps.month = 1
        comps.day = 1
        return Calendar.current.date(from: comps) ?? Date()
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("行程信息") {
                    LabeledContent("车次") {
                        TextField("如 G1234", text: $trainNo)
                            .multilineTextAlignment(.trailing)
                            .textInputAutocapitalization(.characters)
                    }
                    LabeledContent("出发站") {
                        TextField("如 北京南", text: $departStation).multilineTextAlignment(.trailing)
                    }
                    LabeledContent("到达站") {
                        TextField("如 成都东", text: $arriveStation).multilineTextAlignment(.trailing)
                    }
                }
                Section("时间") {
                    DatePicker("出发日期", selection: $departDate, displayedComponents: .date)
                    LabeledContent("出发时间") {
                        TextField("如 08:30", text: $departTime).multilineTextAlignment(.trailing)
                    }
                    LabeledContent("到达时间") {
                        TextField("如 14:20", text: $arriveTime).multilineTextAlignment(.trailing)
                    }
                }
                Section("座席与状态") {
                    Picker("座席类型", selection: $seatType) {
                        ForEach(seatTypes, id: \.self) { Text($0) }
                    }.pickerStyle(.menu)
                    Picker("状态", selection: $ticketStatus) {
                        ForEach(statuses, id: \.self) { Text($0) }
                    }.pickerStyle(.menu)
                    LabeledContent("票价") {
                        TextField("可选", text: $ticketPrice).multilineTextAlignment(.trailing)
                            .keyboardType(.decimalPad)
                    }
                }
                Section("备注") {
                    TextField("备注（可选）", text: $note, axis: .vertical).lineLimit(3)
                }
                Section("截图 OCR 识别") {
                    PhotosPicker(selection: $selectedPhoto, matching: .images) {
                        Label(isOCRing ? "识别中…" : "选择截图自动识别", systemImage: "camera.viewfinder")
                    }
                    .disabled(isOCRing)
                    if ocrFailed {
                        Text("AI 识别失败，请手动填写").font(.caption).foregroundStyle(AppColors.error)
                    }
                    if !ocrText.isEmpty {
                        DisclosureGroup("OCR 原文") {
                            Text(ocrText).font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle(editing == nil ? "添加高铁/动车" : "编辑高铁/动车")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("取消") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") { save() }
                }
            }
            .onAppear { loadExisting() }
            .onChange(of: selectedPhoto) { _, item in
                guard let item else { return }
                Task { await runOCR(item) }
            }
        }
    }

    private func loadExisting() {
        guard let e = editing else { return }
        trainNo = e.trainNo; departStation = e.departStation; arriveStation = e.arriveStation
        if let d = e.departDate { departDate = d }
        departTime = e.departTime; arriveTime = e.arriveTime
        seatType = e.seatType.isEmpty ? "二等座" : e.seatType
        ticketPrice = e.ticketPrice == 0 ? "" : String(e.ticketPrice)
        ticketStatus = e.ticketStatus.isEmpty ? "未购买" : e.ticketStatus
        note = e.note; ocrText = e.ocrText
    }

    private func save() {
        let record = editing ?? { let r = TrainTicketRecord(); ctx.insert(r); return r }()
        record.trainNo = trainNo.uppercased(); record.departStation = departStation; record.arriveStation = arriveStation
        record.departDate = departDate
        record.departTime = departTime; record.arriveTime = arriveTime
        record.seatType = seatType
        record.ticketPrice = Double(ticketPrice) ?? 0
        record.ticketStatus = ticketStatus; record.note = note; record.ocrText = ocrText
        record.updatedAt = Date()
        if editing == nil { record.trip = trip }
        dismiss()
    }

    private func runOCR(_ item: PhotosPickerItem) async {
        isOCRing = true; ocrFailed = false
        guard let data = try? await item.loadTransferable(type: Data.self),
              let image = UIImage(data: data) else { isOCRing = false; return }
        let text = await OCRService.shared.recognizeText(from: image)
        ocrText = text
        if text.isEmpty { isOCRing = false; ocrFailed = true; return }
        do {
            let f = try await TicketParserService.shared.parseTrainTicket(ocrText: text)
            if !f.trainNo.isEmpty { trainNo = f.trainNo.uppercased() }
            if !f.departStation.isEmpty { departStation = f.departStation }
            if !f.arriveStation.isEmpty { arriveStation = f.arriveStation }
            if !f.departTime.isEmpty { departTime = f.departTime }
            if !f.arriveTime.isEmpty { arriveTime = f.arriveTime }
            if !f.seatType.isEmpty { seatType = f.seatType }
            if !f.ticketPrice.isEmpty { ticketPrice = f.ticketPrice }
            if !f.ticketStatus.isEmpty { ticketStatus = f.ticketStatus }
            if !f.departDate.isEmpty {
                if let d = parseDate2026(f.departDate) { departDate = d }
            }
        } catch {
            ocrFailed = true
        }
        isOCRing = false
    }
}

// MARK: - Flight Form

struct FlightTicketFormView: View {
    @Environment(\.modelContext) private var ctx
    @Environment(\.dismiss) private var dismiss
    var editing: FlightTicketRecord? = nil
    var trip: Trip? = nil

    @State private var airline = ""
    @State private var flightNo = ""
    @State private var departAirport = ""
    @State private var arriveAirport = ""
    @State private var departTerminal = ""
    @State private var arriveTerminal = ""
    @State private var departDate: Date = TrainTicketFormView.defaultDate2026
    @State private var departTime = ""
    @State private var arriveTime = ""
    @State private var seatClass = "经济舱"
    @State private var ticketPrice = ""
    @State private var ticketStatus = "未购买"
    @State private var baggageInfo = ""
    @State private var note = ""

    @State private var selectedPhoto: PhotosPickerItem? = nil
    @State private var isOCRing = false
    @State private var ocrFailed = false
    @State private var ocrText = ""

    private let seatClasses = ["经济舱", "商务舱", "头等舱", "超级经济舱"]
    private let statuses = ["已购买", "未购买", "待确认"]
    private let baggageOptions = ["未识别", "无免费托运", "仅手提行李", "7kg 免费托运",
                                  "10kg 免费托运", "20kg 免费托运", "23kg 免费托运", "含托运行李"]

    var body: some View {
        NavigationStack {
            Form {
                Section("航班信息") {
                    LabeledContent("航司") {
                        TextField("如：国航 CA", text: $airline)
                            .multilineTextAlignment(.trailing)
                    }
                    LabeledContent("航班号") {
                        TextField("如：CA1234", text: $flightNo)
                            .multilineTextAlignment(.trailing)
                            .textInputAutocapitalization(.characters)
                    }
                }
                Section("机场") {
                    LabeledContent("出发机场") {
                        TextField("如：首都国际机场", text: $departAirport)
                            .multilineTextAlignment(.trailing)
                    }
                    LabeledContent("出发航站楼") {
                        TextField("如 T3（可选）", text: $departTerminal)
                            .multilineTextAlignment(.trailing)
                    }
                    LabeledContent("到达机场") {
                        TextField("如：天府国际机场", text: $arriveAirport)
                            .multilineTextAlignment(.trailing)
                    }
                    LabeledContent("到达航站楼") {
                        TextField("可选", text: $arriveTerminal)
                            .multilineTextAlignment(.trailing)
                    }
                }
                Section("时间") {
                    DatePicker("出发日期", selection: $departDate, displayedComponents: .date)
                    LabeledContent("出发时间") {
                        TextField("如 06:40", text: $departTime).multilineTextAlignment(.trailing)
                    }
                    LabeledContent("到达时间") {
                        TextField("如 09:20", text: $arriveTime).multilineTextAlignment(.trailing)
                    }
                }
                Section("舱位与行李") {
                    Picker("舱位", selection: $seatClass) {
                        ForEach(seatClasses, id: \.self) { Text($0) }
                    }.pickerStyle(.menu)
                    Picker("状态", selection: $ticketStatus) {
                        ForEach(statuses, id: \.self) { Text($0) }
                    }.pickerStyle(.menu)
                    LabeledContent("票价") {
                        TextField("可选", text: $ticketPrice).multilineTextAlignment(.trailing)
                            .keyboardType(.decimalPad)
                    }
                    Picker("行李信息", selection: $baggageInfo) {
                        ForEach(baggageOptions, id: \.self) { Text($0) }
                    }.pickerStyle(.menu)
                }
                Section("备注") {
                    TextField("备注（可选）", text: $note, axis: .vertical).lineLimit(3)
                }
                Section("截图 OCR 识别") {
                    PhotosPicker(selection: $selectedPhoto, matching: .images) {
                        Label(isOCRing ? "识别中…" : "选择截图自动识别", systemImage: "camera.viewfinder")
                    }
                    .disabled(isOCRing)
                    if ocrFailed {
                        Text("AI 识别失败，请手动填写").font(.caption).foregroundStyle(AppColors.error)
                    }
                    if !ocrText.isEmpty {
                        DisclosureGroup("OCR 原文") {
                            Text(ocrText).font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle(editing == nil ? "添加飞机" : "编辑飞机")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("取消") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("保存") { save() } }
            }
            .onAppear { loadExisting() }
            .onChange(of: selectedPhoto) { _, item in
                guard let item else { return }
                Task { await runOCR(item) }
            }
        }
    }

    private func loadExisting() {
        guard let e = editing else { return }
        airline = e.airline; flightNo = e.flightNo
        departAirport = e.departAirport; arriveAirport = e.arriveAirport
        departTerminal = e.departTerminal; arriveTerminal = e.arriveTerminal
        if let d = e.departDate { departDate = d }
        departTime = e.departTime; arriveTime = e.arriveTime
        seatClass = e.seatClass.isEmpty ? "经济舱" : e.seatClass
        ticketPrice = e.ticketPrice == 0 ? "" : String(e.ticketPrice)
        ticketStatus = e.ticketStatus.isEmpty ? "未购买" : e.ticketStatus
        baggageInfo = e.baggageInfo; note = e.note; ocrText = e.ocrText
    }

    private func save() {
        let record = editing ?? { let r = FlightTicketRecord(); ctx.insert(r); return r }()
        record.airline = airline; record.flightNo = flightNo.uppercased()
        record.departAirport = departAirport; record.arriveAirport = arriveAirport
        record.departTerminal = departTerminal; record.arriveTerminal = arriveTerminal
        record.departDate = departDate
        record.departTime = departTime; record.arriveTime = arriveTime
        record.seatClass = seatClass
        record.ticketPrice = Double(ticketPrice) ?? 0
        record.ticketStatus = ticketStatus; record.baggageInfo = baggageInfo
        record.note = note; record.ocrText = ocrText
        record.updatedAt = Date()
        if editing == nil { record.trip = trip }
        dismiss()
    }

    private func runOCR(_ item: PhotosPickerItem) async {
        isOCRing = true; ocrFailed = false
        guard let data = try? await item.loadTransferable(type: Data.self),
              let image = UIImage(data: data) else { isOCRing = false; return }
        let text = await OCRService.shared.recognizeText(from: image)
        ocrText = text
        if text.isEmpty { isOCRing = false; ocrFailed = true; return }
        do {
            let f = try await TicketParserService.shared.parseFlightTicket(ocrText: text)
            if !f.airline.isEmpty { airline = f.airline }
            if !f.flightNo.isEmpty { flightNo = f.flightNo.uppercased() }
            if !f.departAirport.isEmpty { departAirport = f.departAirport }
            if !f.arriveAirport.isEmpty { arriveAirport = f.arriveAirport }
            if !f.departTerminal.isEmpty { departTerminal = f.departTerminal }
            if !f.arriveTerminal.isEmpty { arriveTerminal = f.arriveTerminal }
            if !f.departTime.isEmpty { departTime = f.departTime }
            if !f.arriveTime.isEmpty { arriveTime = f.arriveTime }
            if !f.seatClass.isEmpty { seatClass = f.seatClass }
            if !f.ticketPrice.isEmpty { ticketPrice = f.ticketPrice }
            if !f.ticketStatus.isEmpty { ticketStatus = f.ticketStatus }
            if !f.baggageInfo.isEmpty { baggageInfo = f.baggageInfo }
            if !f.departDate.isEmpty {
                if let d = parseDate2026(f.departDate) { departDate = d }
            }
        } catch {
            ocrFailed = true
        }
        isOCRing = false
    }
}

// MARK: - Metro Form

struct MetroFormView: View {
    @Environment(\.modelContext) private var ctx
    @Environment(\.dismiss) private var dismiss
    var editing: MetroRecord? = nil
    var trip: Trip? = nil

    @State private var title = ""
    @State private var city = ""
    @State private var fromStation = ""
    @State private var toStation = ""
    @State private var lineInfo = ""
    @State private var direction = ""
    @State private var transferInfo = ""
    @State private var exitInfo = ""
    @State private var estimatedDuration = ""
    @State private var note = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("路线标题") {
                    TextField("例如：酒店 → 成都东站", text: $title)
                }
                Section("站点信息") {
                    TextField("起始站", text: $fromStation)
                    TextField("终点站", text: $toStation)
                    TextField("线路信息（如 2号线 → 7号线）", text: $lineInfo)
                }
                Section("可选信息") {
                    TextField("城市（可选）", text: $city)
                    TextField("方向（如 往龙泉驿方向）", text: $direction)
                    TextField("换乘信息（可选）", text: $transferInfo)
                    TextField("出口（如 A口出）", text: $exitInfo)
                    TextField("预计耗时（如 42分钟）", text: $estimatedDuration)
                }
                Section("完整路线步骤（可选）") {
                    TextField("详细步骤，可多行", text: $note, axis: .vertical).lineLimit(4...8)
                }
            }
            .navigationTitle(editing == nil ? "添加地铁路线" : "编辑地铁路线")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("取消") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") { save() }
                        .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty && fromStation.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear { loadExisting() }
        }
    }

    private func loadExisting() {
        guard let e = editing else { return }
        title = e.title; city = e.city; fromStation = e.fromStation; toStation = e.toStation
        lineInfo = e.lineInfo; direction = e.direction; transferInfo = e.transferInfo
        exitInfo = e.exitInfo; estimatedDuration = e.estimatedDuration; note = e.note
    }

    private func save() {
        let record = editing ?? { let r = MetroRecord(); ctx.insert(r); return r }()
        record.title = title.isEmpty ? "\(fromStation) → \(toStation)" : title
        record.city = city; record.fromStation = fromStation; record.toStation = toStation
        record.lineInfo = lineInfo; record.direction = direction; record.transferInfo = transferInfo
        record.exitInfo = exitInfo; record.estimatedDuration = estimatedDuration; record.note = note
        record.updatedAt = Date()
        if editing == nil { record.trip = trip }
        dismiss()
    }
}

// MARK: - Time Helper

private func travelDuration(_ depart: String, _ arrive: String) -> String? {
    let p1 = depart.split(separator: ":").compactMap { Int($0) }
    let p2 = arrive.split(separator: ":").compactMap { Int($0) }
    guard p1.count == 2, p2.count == 2 else { return nil }
    var diff = (p2[0] * 60 + p2[1]) - (p1[0] * 60 + p1[1])
    if diff <= 0 { diff += 24 * 60 }
    let h = diff / 60, m = diff % 60
    if h == 0 { return "\(m)min" }
    if m == 0 { return "\(h)h" }
    return "\(h)h\(m)m"
}

// MARK: - Date Helper

private func parseDate2026(_ str: String) -> Date? {
    let fmts = ["yyyy-MM-dd", "yyyy/MM/dd", "MM-dd", "MM/dd", "M月d日", "MM月dd日",
                "yyyy年MM月dd日", "MM-dd HH:mm", "yyyy-MM-dd HH:mm"]
    let cal = Calendar.current
    let df = DateFormatter()
    df.locale = Locale(identifier: "zh_CN")
    for fmt in fmts {
        df.dateFormat = fmt
        if let d = df.date(from: str) {
            let year = cal.component(.year, from: d)
            if year <= 2000 {
                var comps = cal.dateComponents([.month, .day, .hour, .minute], from: d)
                comps.year = 2026
                return cal.date(from: comps)
            }
            return d
        }
    }
    return nil
}
