import SwiftUI

struct POSReceiptEligibilityBanner: View {
    @Binding var isVisible: Bool

    var body: some View {
        HStack(spacing: Constants.elementSpacing) {
            Image(uiImage: .posAppIconDefault)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: Constants.imagesize, height: Constants.imagesize)
                .clipShape(Circle())
                .padding(Constants.imagePadding)
            Text(Localization.updateWooCommerceVersionText)
                .foregroundColor(Color.posOnSurface)
        }
        .padding()
        .background(Color.posSurface)
        .cornerRadius(Constants.cornerRadius)
        .padding(.horizontal, Constants.bannerPadding)
        .onTapGesture {
            withAnimation {
                isVisible = false
            }
        }
    }
}

private extension POSReceiptEligibilityBanner {
    enum Constants {
        static let elementSpacing: CGFloat = POSSpacing.small
        static let cornerRadius: CGFloat = POSCornerRadiusStyle.large.value
        static let imagesize: CGFloat = 40
        static let imagePadding: CGFloat = POSPadding.xSmall
        static let bannerPadding: CGFloat = POSPadding.medium
    }

    enum Localization {
        static let updateWooCommerceVersionText = NSLocalizedString(
            "pos.totalsView.receipts.banner.updateWooCommerceVersionText",
            value: "Please update WooCommerce to version 9.5.0",
            comment: "Text for the banner requiring specific WooCommerce version.")
    }
}

#Preview {
    POSReceiptEligibilityBanner(isVisible: .constant(true))
        .padding()
}
