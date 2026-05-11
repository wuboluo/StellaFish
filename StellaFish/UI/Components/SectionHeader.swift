import SwiftUI

struct SectionHeader: View {
    let title: String
    var actionLabel: String = "查看全部"
    var action: (() -> Void)? = nil

    var body: some View {
        HStack {
            Text(title)
                .font(.headline)
                .foregroundStyle(.primary)
            Spacer()
            if let action {
                Button(actionLabel, action: action)
                    .font(.subheadline)
                    .foregroundStyle(AppColors.primary)
            }
        }
    }
}
