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

    let type: BadgeType

    var body: some View {
        Text(type.title.uppercased())
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

extension BadgeView {
    enum Localization {
        static let newTitle = NSLocalizedString("New", comment: "Title of the badge shown when advertising a new feature")
        static let tipTitle = NSLocalizedString("Tip", comment: "Title of the badge shown when promoting an existing feature")
    }

    enum Layout {
        static let horizontalPadding: CGFloat = 6
        static let verticalPadding: CGFloat = 4
        static let cornerRadius: CGFloat = 8
    }
}
