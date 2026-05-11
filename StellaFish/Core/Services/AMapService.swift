import Foundation
import CoreLocation
import UIKit

struct AMapPOI: Identifiable, Decodable {
    let id: String
    let name: String
    let address: String
    let location: String   // "lng,lat"
    let typecode: String

    var coordinate: CLLocationCoordinate2D? {
        let parts = location.split(separator: ",")
        guard parts.count == 2,
              let lng = Double(parts[0]),
              let lat = Double(parts[1]) else { return nil }
        return CLLocationCoordinate2D(latitude: lat, longitude: lng)
    }

    var latitude: Double? { coordinate?.latitude }
    var longitude: Double? { coordinate?.longitude }
}

private struct AMapSearchResponse: Decodable {
    let status: String
    let pois: [AMapPOI]?

    enum CodingKeys: String, CodingKey { case status, pois }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        status = try c.decode(String.self, forKey: .status)
        pois = try? c.decode([AMapPOI].self, forKey: .pois)
    }
}

final class AMapService {
    static let shared = AMapService()
    private static let apiKey = ""
    private static let baseURL = "https://restapi.amap.com/v3/place/text"

    func searchPOI(keyword: String, city: String = "") async throws -> [AMapPOI] {
        var comps = URLComponents(string: Self.baseURL)!
        comps.queryItems = [
            .init(name: "key",        value: Self.apiKey),
            .init(name: "keywords",   value: keyword),
            .init(name: "city",       value: city.isEmpty ? "全国" : city),
            .init(name: "offset",     value: "15"),
            .init(name: "output",     value: "JSON"),
            .init(name: "extensions", value: "base"),
        ]
        let (data, _) = try await URLSession.shared.data(from: comps.url!)
        let resp = try JSONDecoder().decode(AMapSearchResponse.self, from: data)
        return resp.pois ?? []
    }

    func openInMap(coordinate: CLLocationCoordinate2D, name: String) {
        let enc = name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? name
        let gaode = URL(string: "iosamap://viewMap?sourceApplication=StellaFish&lat=\(coordinate.latitude)&lon=\(coordinate.longitude)&dev=0&name=\(enc)")
        if let url = gaode, UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        } else {
            let apple = URL(string: "maps://?q=\(enc)&ll=\(coordinate.latitude),\(coordinate.longitude)")!
            UIApplication.shared.open(apple)
        }
    }

    func openNavigation(to coordinate: CLLocationCoordinate2D, name: String) {
        let enc = name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? name
        let gaode = URL(string: "iosamap://navi?sourceApplication=StellaFish&lat=\(coordinate.latitude)&lon=\(coordinate.longitude)&dev=0&style=2&name=\(enc)")
        if let url = gaode, UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        } else {
            let apple = URL(string: "maps://?daddr=\(coordinate.latitude),\(coordinate.longitude)")!
            UIApplication.shared.open(apple)
        }
    }
}
