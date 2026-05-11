import SwiftUI

struct TripCard: View {
    let trip: Trip

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(trip.title)
                        .font(.title3.weight(.bold))
                        .foregroundStyle(.white)
                    Text("\(trip.fromCity) → \(trip.toCity)")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.85))
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(trip.durationDays)")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundStyle(.white)
                    Text("天")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.75))
                }
            }

            Divider()
                .overlay(.white.opacity(0.35))

            HStack(spacing: 0) {
                Label(trip.departDate.shortDateLabel, systemImage: "calendar")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.9))
                Spacer()
                Label("\(trip.peopleCount)人", systemImage: "person.2.fill")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.9))
                Spacer()
                Label(trip.tripPreference.label, systemImage: "slider.horizontal.3")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.9))
            }
        }
        .padding(20)
        .background(AppColors.primaryGradient)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: AppColors.primary.opacity(0.35), radius: 12, y: 6)
    }
}
