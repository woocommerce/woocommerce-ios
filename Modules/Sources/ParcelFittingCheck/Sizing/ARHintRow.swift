import SwiftUI

struct ARHintRow: View {
    let iconName: String
    let label: String

    var body: some View {
        HStack(spacing: Constants.spacing) {
            Image(systemName: iconName)
                .font(.system(size: Constants.iconFontSize))
                .foregroundStyle(.white)
                .frame(width: Constants.iconTileSize, height: Constants.iconTileSize)
                .background(Color.white.opacity(Constants.iconTileBackgroundOpacity), in: RoundedRectangle(cornerRadius: Constants.iconTileCornerRadius))

            Text(label)
                .font(.footnote)
                .foregroundStyle(.white.opacity(Constants.labelOpacity))
        }
    }
}

private extension ARHintRow {
    enum Constants {
        static let spacing: CGFloat = 10
        static let iconFontSize: CGFloat = 16
        static let iconTileSize: CGFloat = 28
        static let iconTileCornerRadius: CGFloat = 8
        static let iconTileBackgroundOpacity: Double = 0.08
        static let labelOpacity: Double = 0.62
    }
}
