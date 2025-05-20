import SwiftUI

@available(iOS 17.0, *)
struct PointOfSaleItemListCouponsDisabledView: View {
    let onAction: (() -> Void)

    var body: some View {
        PointOfSaleItemListErrorView(error: PointOfSaleErrorState.errorCouponsDisabled, onAction: onAction) {
            Image(uiImage: .couponsImage)
                .resizable()
                .scaledToFit()
                .frame(width: 88, height: 88)
        }
    }
}

@available(iOS 17.0, *)
#Preview {
    PointOfSaleItemListCouponsDisabledView(onAction: {})
}
