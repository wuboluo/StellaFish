import Foundation
import SwiftData

@Model
final class ExpenseRecord {
    var id: UUID
    var trip: Trip?
    var title: String
    var amount: Double
    var categoryRaw: String
    var paymentMethodRaw: String?
    var note: String
    var latitude: Double?
    var longitude: Double?
    var locationName: String?
    var createdAt: Date
    var updatedAt: Date
    var sourceRaw: String
    var rawText: String?

    init(
        trip: Trip? = nil,
        title: String,
        amount: Double,
        category: ExpenseCategory = .other,
        paymentMethod: PaymentMethod? = nil,
        note: String = "",
        latitude: Double? = nil,
        longitude: Double? = nil,
        locationName: String? = nil,
        source: ExpenseSource = .manual,
        rawText: String? = nil
    ) {
        self.id = UUID()
        self.trip = trip
        self.title = title
        self.amount = amount
        self.categoryRaw = category.rawValue
        self.paymentMethodRaw = paymentMethod?.rawValue
        self.note = note
        self.latitude = latitude
        self.longitude = longitude
        self.locationName = locationName
        self.createdAt = Date()
        self.updatedAt = Date()
        self.sourceRaw = source.rawValue
        self.rawText = rawText
    }

    var category: ExpenseCategory {
        get { ExpenseCategory(rawValue: categoryRaw) ?? .other }
        set { categoryRaw = newValue.rawValue }
    }

    var paymentMethod: PaymentMethod? {
        get { paymentMethodRaw.flatMap { PaymentMethod(rawValue: $0) } }
        set { paymentMethodRaw = newValue?.rawValue }
    }

    var source: ExpenseSource {
        get { ExpenseSource(rawValue: sourceRaw) ?? .manual }
        set { sourceRaw = newValue.rawValue }
    }
}
