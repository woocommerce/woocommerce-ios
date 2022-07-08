import SwiftUI

struct NewBadgeView: View {
    var body: some View {
        Text(Localization.newTitle.uppercased())
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

extension NewBadgeView {
    enum Localization {
        static let newTitle = NSLocalizedString("New", comment: "Title of the new badge shown when advertising a new feature")
    }

    enum Layout {
        static let horizontalPadding: CGFloat = 6
        static let verticalPadding: CGFloat = 4
        static let cornerRadius: CGFloat = 8
    }
}
