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

    private let text: String

    init(type: BadgeType) {
        text = type.title.uppercased()
    }

    init(text: String) {
        self.text = text
    }

    var body: some View {
        Text(text)
            .foregroundColor(Color(.textBrand))
            .padding(.leading, Layout.horizontalPadding)
            .padding(.trailing, Layout.horizontalPadding)
            .padding(.top, Layout.verticalPadding)
            .padding(.bottom, Layout.verticalPadding)
            .background(RoundedRectangle(cornerRadius: Layout.cornerRadius)
                .fill(Color(.withColorStudio(.wooCommercePurple, shade: .shade0))))
            .font(.system(size: 12, weight: .bold))
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
        }
    }
}
