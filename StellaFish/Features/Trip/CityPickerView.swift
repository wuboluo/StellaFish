import SwiftUI

struct CityPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedCityName: String

    @State private var query = ""
    @State private var allCities: [City] = []

    private var filtered: [City] {
        if query.isEmpty { return allCities }
        return allCities.filter { $0.matches(query) }
    }

    private var grouped: [(String, [City])] {
        if !query.isEmpty {
            return [("搜索结果", filtered)]
        }
        let dict = Dictionary(grouping: allCities) { String($0.firstLetter) }
        return dict.keys.sorted().map { key in (key, dict[key]!.sorted { $0.name < $1.name }) }
    }

    var body: some View {
        NavigationStack {
            List {
                if !query.isEmpty && filtered.isEmpty {
                    ContentUnavailableView.search(text: query)
                } else {
                    ForEach(grouped, id: \.0) { section, cities in
                        Section(section) {
                            ForEach(cities) { city in
                                Button {
                                    selectedCityName = city.name
                                    dismiss()
                                } label: {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(city.name)
                                                .foregroundStyle(.primary)
                                            Text(city.province)
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                        Spacer()
                                        if city.name == selectedCityName {
                                            Image(systemName: "checkmark")
                                                .foregroundStyle(AppColors.primary)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .searchable(text: $query, prompt: "城市名、拼音或首字母")
            .navigationTitle("选择城市")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
            }
        }
        .onAppear { loadCities() }
    }

    private func loadCities() {
        guard let url = Bundle.main.url(forResource: "cities", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let cities = try? JSONDecoder().decode([City].self, from: data) else { return }
        allCities = cities.sorted { $0.firstLetter < $1.firstLetter }
    }
}
