import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            NavigationStack {
                TripOverviewView()
            }
            .tabItem { Label("旅行", systemImage: "airplane.departure") }

            NavigationStack {
                PackingView()
            }
            .tabItem { Label("清单", systemImage: "checklist") }

            NavigationStack {
                TransportRecordView()
            }
            .tabItem { Label("交通", systemImage: "tram.fill") }

            NavigationStack {
                PlacesView()
            }
            .tabItem { Label("地点", systemImage: "mappin.and.ellipse") }

            NavigationStack {
                RemindersView()
            }
            .tabItem { Label("提醒", systemImage: "bell") }
        }
        .tint(AppColors.primary)
    }
}
