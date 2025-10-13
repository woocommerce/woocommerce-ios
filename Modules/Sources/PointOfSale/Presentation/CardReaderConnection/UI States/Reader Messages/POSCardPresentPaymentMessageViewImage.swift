import SwiftUI

struct POSCardPresentPaymentMessageViewImage: View {
    private let imageName: String

    init(imageName: String) {
        self.imageName = imageName
    }

    var body: some View {
        Image(decorative: imageName, bundle: .module)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(
                minWidth: PointOfSaleCardPresentPaymentLayout.compactHeaderSize.width,
                maxWidth: PointOfSaleCardPresentPaymentLayout.headerSize.width,
                minHeight: PointOfSaleCardPresentPaymentLayout.compactHeaderSize.height,
                maxHeight: PointOfSaleCardPresentPaymentLayout.headerSize.height
            )
            .accessibilityHidden(true)
    }
}
