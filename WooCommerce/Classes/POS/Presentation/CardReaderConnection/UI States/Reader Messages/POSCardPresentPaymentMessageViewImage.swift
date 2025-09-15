import SwiftUI

struct POSCardPresentPaymentMessageViewImage: View {
    private let imageName: String

    init(imageName: String) {
        self.imageName = imageName
    }

    var body: some View {
        Image(decorative: imageName)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(
                minWidth: PointOfSaleCardPresentPaymentLayout.headerSize.width * 0.3,
                maxWidth: PointOfSaleCardPresentPaymentLayout.headerSize.width,
                minHeight: PointOfSaleCardPresentPaymentLayout.headerSize.height * 0.3,
                maxHeight: PointOfSaleCardPresentPaymentLayout.headerSize.height
            )
            .accessibilityHidden(true)
    }
}
