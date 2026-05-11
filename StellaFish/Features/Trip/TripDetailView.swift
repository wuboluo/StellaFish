import SwiftUI

struct TripDetailView: View {
    let trip: Trip
    @State private var selectedTab = 0

    var body: some View {
        VStack(spacing: 0) {
            // Sub-tab picker
            Picker("", selection: $selectedTab) {
                Text("交通").tag(0)
                Text("酒店").tag(1)
                Text("清单").tag(2)
                Text("花费").tag(3)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(.white)

            Divider()

            // Sub-tab content
            Group {
                switch selectedTab {
                case 0:
                    TransportTaskListView(trip: trip)
                case 1:
                    HotelListView(trip: trip)
                case 2:
                    ChecklistView(trip: trip)
                case 3:
                    ExpenseListView(trip: trip)
                default:
                    EmptyView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(AppColors.background)
        }
        .navigationTitle(trip.title)
        .navigationBarTitleDisplayMode(.large)
    }


}
