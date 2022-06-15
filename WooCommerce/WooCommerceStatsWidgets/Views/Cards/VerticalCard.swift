import SwiftUI

/// A card with a title and a value stacked vertically
struct VerticalCard: View {
    let title: String
    let value: String
    let largeText: Bool

    private var titleFont: Font {
        largeText ? Appearance.largeTextFont : Appearance.textFont
    }

    private var accessibilityLabel: Text {
        // The colon makes VoiceOver pause between elements
        Text(title) + Text(": ") + Text(String(value))
    }

    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(Appearance.titleFont)
                .fontWeight(Appearance.titleFontWeight)
                .foregroundColor(Appearance.titleColor)
                .accessibility(hidden: true)
            StatsValueView(value: value,
                           font: titleFont,
                           fontWeight: .regular,
                           foregroundColor: Appearance.textColor,
                           lineLimit: nil)
                .accessibility(label: accessibilityLabel)

        }
    }
}

// MARK: - Appearance
extension VerticalCard {

    private enum Appearance {

        static let titleFont = Font.caption
        static let titleFontWeight = Font.Weight.semibold

        static let largeTextFont = Font.largeTitle
        static let textFont = Font.title
        static let textColor = Color.white
        static let titleColor = Color(red: 0.635, green: 0.549, blue: 0.768)
    }
}
