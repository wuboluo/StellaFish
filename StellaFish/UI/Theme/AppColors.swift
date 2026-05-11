import SwiftUI

// MARK: - Spacing

enum AppSpacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
}

// MARK: - Radius

enum AppRadius {
    static let sm: CGFloat = 10
    static let md: CGFloat = 14
    static let lg: CGFloat = 20
    static let pill: CGFloat = 100
}

// MARK: - View Modifiers

extension View {
    func cardStyle(radius: CGFloat = AppRadius.md) -> some View {
        self
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: radius))
            .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }

    func softShadow(_ opacity: Double = 0.05, radius: CGFloat = 4) -> some View {
        shadow(color: .black.opacity(opacity), radius: radius, y: 2)
    }
}

// MARK: - Button Styles

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.easeInOut(duration: 0.12), value: configuration.isPressed)
    }
}

// MARK: - Colors

enum AppColors {
    static let primary = Color(red: 0.357, green: 0.424, blue: 0.973)       // #5B6CF8
    static let primaryEnd = Color(red: 0.608, green: 0.349, blue: 0.961)    // #9B59F5
    static let accent = Color(red: 1.0, green: 0.439, blue: 0.263)          // #FF7043
    static let background = Color(red: 0.961, green: 0.961, blue: 0.969)    // #F5F5F7
    static let surface = Color.white
    static let cardBackground = Color.white
    static let textPrimary = Color(red: 0.1, green: 0.1, blue: 0.1)
    static let textSecondary = Color(red: 0.5, green: 0.5, blue: 0.5)
    static let success = Color(red: 0.204, green: 0.78, blue: 0.349)        // #34C759
    static let warning = Color(red: 1.0, green: 0.624, blue: 0.039)         // #FF9F0A
    static let error = Color(red: 1.0, green: 0.231, blue: 0.188)           // #FF3B30

    static var primaryGradient: LinearGradient {
        LinearGradient(
            colors: [primary, primaryEnd],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - Shared Components

struct TripNameLabel: View {
    let name: String?
    var body: some View {
        if let name {
            Text(name)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
                .lineLimit(1)
        } else {
            Text("未选择旅行")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}
