import SwiftUI

@Observable
final class AppState {
    var activeTripID: UUID? {
        didSet { persist() }
    }

    init() {
        if let str = UserDefaults.standard.string(forKey: "stellafish.activeTrip"),
           let id = UUID(uuidString: str) {
            activeTripID = id
        }
    }

    private func persist() {
        if let id = activeTripID {
            UserDefaults.standard.set(id.uuidString, forKey: "stellafish.activeTrip")
        } else {
            UserDefaults.standard.removeObject(forKey: "stellafish.activeTrip")
        }
    }
}
