import SwiftUI

struct POSReceiptEligibilityBanner: View {
    @Binding var isVisible: Bool
    
    var body: some View {
        HStack(spacing: Constants.elementSpacing) {
            Image(uiImage: .appIconDefault)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: Constants.imagesize, height: Constants.imagesize)
                .clipShape(Circle())
                .padding(Constants.imagePadding)
            Text(Localization.updateWooCommerceVersionText)
                .foregroundColor(Color.posPrimaryText)
        }
        .padding()
        .background(Color.posPrimaryBackground)
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
        static let elementSpacing: CGFloat = 8
        static let cornerRadius: CGFloat = 20
        static let imagesize: CGFloat = 40
        static let imagePadding: CGFloat = 4
        static let bannerPadding: CGFloat = 16
    }
    
    enum Localization {
        static let updateWooCommerceVersionText = NSLocalizedString(
            "pos.totalsView.receipts.banner.updateWooCommerceVersionText",
            value: "Please update WooCommerce to version 9.5.0",
            comment: "Text for the banner requiring specific WooCommerce version.")
    }
}
