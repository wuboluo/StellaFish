import Foundation
import SwiftData

@Model
final class HotelCandidate {
    var id: UUID
    var trip: Trip?
    var name: String
    var brand: String
    var address: String
    var latitude: Double?
    var longitude: Double?
    var checkInDate: Date
    var checkOutDate: Date
    var pricePerNight: Double
    var distanceNote: String
    var trafficNote: String
    var ratingNote: String
    var bookingStatusRaw: String
    var note: String
    var createdAt: Date
    var updatedAt: Date

    init(
        trip: Trip? = nil,
        name: String,
        brand: String = "",
        address: String = "",
        latitude: Double? = nil,
        longitude: Double? = nil,
        checkInDate: Date = Date(),
        checkOutDate: Date = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date(),
        pricePerNight: Double = 0,
        distanceNote: String = "",
        trafficNote: String = "",
        ratingNote: String = "",
        bookingStatus: BookingStatus = .notBooked,
        note: String = ""
    ) {
        self.id = UUID()
        self.trip = trip
        self.name = name
        self.brand = brand
        self.address = address
        self.latitude = latitude
        self.longitude = longitude
        self.checkInDate = checkInDate
        self.checkOutDate = checkOutDate
        self.pricePerNight = pricePerNight
        self.distanceNote = distanceNote
        self.trafficNote = trafficNote
        self.ratingNote = ratingNote
        self.bookingStatusRaw = bookingStatus.rawValue
        self.note = note
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    var bookingStatus: BookingStatus {
        get { BookingStatus(rawValue: bookingStatusRaw) ?? .notBooked }
        set { bookingStatusRaw = newValue.rawValue }
    }

    var nights: Int {
        max(0, Calendar.current.dateComponents([.day], from: checkInDate, to: checkOutDate).day ?? 0)
    }

    var totalPrice: Double {
        pricePerNight * Double(nights)
    }
}
