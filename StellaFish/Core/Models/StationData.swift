import Foundation

struct CityStations: Codable {
    let name: String
    let airports: [String]
    let trainStations: [String]
}

enum StationData {
    private struct Root: Codable {
        let cities: [CityStations]
    }

    static let all: [CityStations] = {
        guard let url = Bundle.main.url(forResource: "stations", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let root = try? JSONDecoder().decode(Root.self, from: data) else { return [] }
        return root.cities
    }()

    static func stations(for city: String, transportType: TransportType) -> [String] {
        guard let cityData = all.first(where: { $0.name == city }) else { return [] }
        switch transportType {
        case .plane: return cityData.airports
        case .highSpeedTrain: return cityData.trainStations
        default: return []
        }
    }
}
