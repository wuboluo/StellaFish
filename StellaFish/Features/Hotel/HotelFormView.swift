import SwiftUI

struct HotelFormView: View {
    @Environment(\.dismiss) private var dismiss
    var hotel: HotelCandidate?
    var onSave: (HotelCandidate) -> Void

    @State private var name = ""
    @State private var brand = ""
    @State private var address = ""
    @State private var checkInDate = Date()
    @State private var checkOutDate = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
    @State private var pricePerNight = ""
    @State private var distanceNote = ""
    @State private var trafficNote = ""
    @State private var ratingNote = ""
    @State private var bookingStatus: BookingStatus = .notBooked
    @State private var note = ""

    private var isEditing: Bool { hotel != nil }
    private var canSave: Bool { !name.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        NavigationStack {
            Form {
                Section("酒店信息") {
                    TextField("酒店名称", text: $name)
                    TextField("品牌（如：全季、如家）", text: $brand)
                    TextField("地址", text: $address)
                }
                Section("入住日期") {
                    DatePicker("入住日期", selection: $checkInDate, displayedComponents: .date)
                    DatePicker("退房日期", selection: $checkOutDate, in: checkInDate..., displayedComponents: .date)
                    TextField("¥ 每晚价格", text: $pricePerNight)
                        .keyboardType(.decimalPad)
                }
                Section("位置与评价") {
                    TextField("与景点/目的地距离（如：步行10分钟）", text: $distanceNote)
                    TextField("交通便利性（如：地铁2号线旁）", text: $trafficNote)
                    TextField("评分说明（如：8.9分，环境好）", text: $ratingNote)
                }
                Section("预订状态") {
                    Picker("状态", selection: $bookingStatus) {
                        ForEach(BookingStatus.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.segmented)
                }
                Section("备注") {
                    TextField("可选", text: $note, axis: .vertical)
                        .lineLimit(2...4)
                }
            }
            .navigationTitle(isEditing ? "编辑酒店" : "添加酒店候选")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") { save() }
                        .disabled(!canSave)
                }
            }
        }
        .onAppear { populateIfEditing() }
    }

    private func populateIfEditing() {
        guard let h = hotel else { return }
        name = h.name
        brand = h.brand
        address = h.address
        checkInDate = h.checkInDate
        checkOutDate = h.checkOutDate
        pricePerNight = h.pricePerNight > 0 ? String(h.pricePerNight) : ""
        distanceNote = h.distanceNote
        trafficNote = h.trafficNote
        ratingNote = h.ratingNote
        bookingStatus = h.bookingStatus
        note = h.note
    }

    private func save() {
        if let existing = hotel {
            existing.name = name.trimmingCharacters(in: .whitespaces)
            existing.brand = brand
            existing.address = address
            existing.checkInDate = checkInDate
            existing.checkOutDate = checkOutDate
            existing.pricePerNight = Double(pricePerNight) ?? 0
            existing.distanceNote = distanceNote
            existing.trafficNote = trafficNote
            existing.ratingNote = ratingNote
            existing.bookingStatus = bookingStatus
            existing.note = note
            existing.updatedAt = Date()
            onSave(existing)
        } else {
            let h = HotelCandidate(
                name: name.trimmingCharacters(in: .whitespaces),
                brand: brand,
                address: address,
                checkInDate: checkInDate,
                checkOutDate: checkOutDate,
                pricePerNight: Double(pricePerNight) ?? 0,
                distanceNote: distanceNote,
                trafficNote: trafficNote,
                ratingNote: ratingNote,
                bookingStatus: bookingStatus,
                note: note
            )
            onSave(h)
        }
        dismiss()
    }
}
