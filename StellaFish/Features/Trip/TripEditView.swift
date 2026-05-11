import SwiftUI
import SwiftData

struct TripEditView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    // nil = create new, non-nil = edit existing
    var trip: Trip?
    var onSave: (Trip) -> Void

    @State private var title = ""
    @State private var fromCity = "北京"
    @State private var toCity = ""
    @State private var departDate = Date()
    @State private var returnDate = Calendar.current.date(byAdding: .day, value: 3, to: Date()) ?? Date()
    @State private var peopleCount = 2
    @State private var note = ""

    @State private var showFromCityPicker = false
    @State private var showToCityPicker = false

    private var isEditing: Bool { trip != nil }
    private var canSave: Bool { !title.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        NavigationStack {
            Form {
                Section("基本信息") {
                    TextField("行程名称", text: $title)
                    HStack {
                        Text("出发城市")
                        Spacer()
                        Button(fromCity.isEmpty ? "选择" : fromCity) {
                            showFromCityPicker = true
                        }
                        .foregroundStyle(fromCity.isEmpty ? .secondary : AppColors.primary)
                    }
                    HStack {
                        Text("目的城市")
                        Spacer()
                        Button(toCity.isEmpty ? "选择" : toCity) {
                            showToCityPicker = true
                        }
                        .foregroundStyle(toCity.isEmpty ? .secondary : AppColors.primary)
                    }
                }

                Section("日期") {
                    DatePicker("出发日期", selection: $departDate, displayedComponents: .date)
                    DatePicker("返回日期", selection: $returnDate, in: departDate..., displayedComponents: .date)
                }

                Section("备注") {
                    TextField("可选备注", text: $note, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle(isEditing ? "编辑行程" : "新建行程")
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
            .sheet(isPresented: $showFromCityPicker) {
                CityPickerView(selectedCityName: $fromCity)
            }
            .sheet(isPresented: $showToCityPicker) {
                CityPickerView(selectedCityName: $toCity)
            }
        }
        .onAppear { populateIfEditing() }
    }

    private func populateIfEditing() {
        guard let trip else { return }
        title = trip.title
        fromCity = trip.fromCity
        toCity = trip.toCity
        departDate = trip.departDate
        returnDate = trip.returnDate
        peopleCount = trip.peopleCount
        note = trip.note
    }

    private func save() {
        if let existing = trip {
            existing.title = title.trimmingCharacters(in: .whitespaces)
            existing.fromCity = fromCity
            existing.toCity = toCity
            existing.departDate = departDate
            existing.returnDate = returnDate
            existing.peopleCount = peopleCount
            existing.note = note
            existing.updatedAt = Date()
            try? modelContext.save()
            onSave(existing)
        } else {
            let newTrip = Trip(
                title: title.trimmingCharacters(in: .whitespaces),
                fromCity: fromCity,
                toCity: toCity,
                departDate: departDate,
                returnDate: returnDate,
                peopleCount: peopleCount,
                note: note
            )
            modelContext.insert(newTrip)
            ChecklistItem.defaultItems(for: newTrip).forEach { modelContext.insert($0) }
            try? modelContext.save()
            onSave(newTrip)
        }
        dismiss()
    }
}
