import SwiftUI

struct BadgeView: View {
    enum BadgeType {
        case new
        case tip

        var title: String {
            switch self {
            case .new:
                return Localization.newTitle
            case .tip:
                return Localization.tipTitle
            }
        }
    }

    /// UI customizations for the badge.
    struct Customizations {
        let textColor: Color
        let backgroundColor: Color

        init(textColor: Color = Color(.textBrand),
             backgroundColor: Color = Color(.wooCommercePurple(.shade0))) {
            self.textColor = textColor
            self.backgroundColor = backgroundColor
        }
    }

    private let text: String
    private let customizations: Customizations

    init(type: BadgeType) {
        text = type.title.uppercased()
        customizations = .init()
    }

    init(text: String, customizations: Customizations = .init()) {
        self.text = text
        self.customizations = customizations
    }

    var body: some View {
        Text(text)
            .bold()
            .foregroundColor(customizations.textColor)
            .captionStyle()
            .padding(.leading, Layout.horizontalPadding)
            .padding(.trailing, Layout.horizontalPadding)
            .padding(.top, Layout.verticalPadding)
            .padding(.bottom, Layout.verticalPadding)
            .background(RoundedRectangle(cornerRadius: Layout.cornerRadius)
                .fill(customizations.backgroundColor)
            )
    }
}

private extension BadgeView.BadgeType {
    enum Localization {
        static let newTitle = NSLocalizedString("New", comment: "Title of the badge shown when advertising a new feature")
        static let tipTitle = NSLocalizedString("Tip", comment: "Title of the badge shown when promoting an existing feature")
    }
}

private extension BadgeView {
    enum Layout {
        static let horizontalPadding: CGFloat = 6
        static let verticalPadding: CGFloat = 4
        static let cornerRadius: CGFloat = 8
    }
}

struct BadgeView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            BadgeView(type: .new)
            BadgeView(type: .tip)
            BadgeView(text: "Custom text")
            BadgeView(text: "Customized colors", customizations: .init(textColor: .green, backgroundColor: .orange))
        }
    }
}
