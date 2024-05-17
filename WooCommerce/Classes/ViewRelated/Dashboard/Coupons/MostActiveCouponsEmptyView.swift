import SwiftUI

/// Shown when the site doesn't have any active coupons for a time range.
/// Contains a placeholder image and text.
struct MostActiveCouponsEmptyView: View {
    var body: some View {
        VStack(alignment: .center, spacing: Layout.defaultSpacing) {
            Image(uiImage: .emptyCouponsImage)
            Text(Localization.text)
                .subheadlineStyle()
        }
        .padding(.all, Layout.defaultSpacing)
    }
}

private extension MostActiveCouponsEmptyView {
    enum Localization {
        static let text = NSLocalizedString(
            "mostActiveCouponsEmptyView.text",
            value: "No coupon usage during this period",
            comment: "Default text for Most active coupons dashboard card when no data exists for a given period."
        )
    }

    enum Layout {
        static let defaultSpacing: CGFloat = 16
    }
}

struct MostActiveCouponsEmptyView_Previews: PreviewProvider {
    static var previews: some View {
        MostActiveCouponsEmptyView()
    }
}
