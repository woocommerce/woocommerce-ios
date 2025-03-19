import SwiftUI

@available(iOS 17.0, *)
struct PointOfSaleScanToPayView: View {
    @Environment(PointOfSaleAggregateModel.self) private var posModel
    @Environment(\.dynamicTypeSize) var dynamicTypeSize

    var body: some View {
        VStack(alignment: .center, spacing: POSSpacing.medium) {
            if let qrCodeImage = ScanToPayViewModel(paymentURL: posModel.paymentURL).generateQRCodeImage() {
                Text(ScanToPayView.Localization.title)
                    .font(.posHeadingBold)
                    .dynamicTypeSize(...DynamicTypeSize.large)
                Image(uiImage: qrCodeImage)
                    .interpolation(.none)
                    .resizable()
                .buttonStyle(PrimaryButtonStyle())
                .aspectRatio(1, contentMode: .fit)
                .frame(minWidth: 250, minHeight: 250)
                .layoutPriority(1)
                .padding(dynamicTypeSize.isAccessibilitySize ? 0 : POSPadding.large)
            }
        }
        .padding(.top, dynamicTypeSize.isAccessibilitySize ? 0 : POSPadding.large)
        .onDisappear() {
            posModel.stopScanToPay()
        }
    }
}
