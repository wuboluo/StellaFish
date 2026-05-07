import Foundation

struct City: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let province: String
    let pinyin: String
    let firstLetter: String
    let latitude: Double
    let longitude: Double

    func matches(_ query: String) -> Bool {
        let q = query.lowercased()
        return name.contains(q)
            || pinyin.lowercased().contains(q)
            || firstLetter.lowercased().hasPrefix(q)
    }
}

extension City {
    static let popular: [String] = [
        "beijing", "shanghai", "guangzhou", "shenzhen", "chengdu",
        "hangzhou", "wuhan", "xian", "chongqing", "nanjing",
        "suzhou", "tianjin", "qingdao", "xiamen", "kunming"
    ]
}
