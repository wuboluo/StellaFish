import SwiftUI

enum AppColors {
    static let primary = Color(red: 0.357, green: 0.424, blue: 0.973)       // #5B6CF8
    static let primaryEnd = Color(red: 0.608, green: 0.349, blue: 0.961)    // #9B59F5
    static let accent = Color(red: 1.0, green: 0.439, blue: 0.263)          // #FF7043
    static let background = Color(red: 0.961, green: 0.961, blue: 0.969)    // #F5F5F7
    static let cardBackground = Color.white
    static let textPrimary = Color(red: 0.1, green: 0.1, blue: 0.1)
    static let textSecondary = Color(red: 0.5, green: 0.5, blue: 0.5)

    static var primaryGradient: LinearGradient {
        LinearGradient(
            colors: [primary, primaryEnd],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}
