import Foundation

extension Double {
    var currencyString: String {
        String(format: "¥%.2f", self)
    }

    var currencyShortString: String {
        if self >= 10000 {
            return String(format: "¥%.1f万", self / 10000)
        }
        return String(format: "¥%.2f", self)
    }
}
