import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            DashboardView()
                .tabItem {
                    Label("首页", systemImage: "house.fill")
                }

            TripListView()
                .tabItem {
                    Label("计划", systemImage: "map.fill")
                }

            ChecklistView()
                .tabItem {
                    Label("清单", systemImage: "checklist")
                }

            ExpenseListView()
                .tabItem {
                    Label("记账", systemImage: "yensign.circle.fill")
                }

            AIView()
                .tabItem {
                    Label("AI", systemImage: "sparkles")
                }

            SettingsView()
                .tabItem {
                    Label("设置", systemImage: "gearshape.fill")
                }
        }
        .tint(AppColors.primary)
    }
}
