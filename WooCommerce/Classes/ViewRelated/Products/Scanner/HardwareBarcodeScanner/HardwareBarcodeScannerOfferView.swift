import SwiftUI
import StoreDesignSystem
import protocol WooFoundation.Analytics

struct HardwareBarcodeScannerOfferView: View {
    let source: WooAnalyticsEvent.BarcodeScanning.Source
    let analytics: Analytics
    let onInfoVisibilityChange: (Bool) -> Void

    @State private var isShowingInfo = false

    init(source: WooAnalyticsEvent.BarcodeScanning.Source,
         analytics: Analytics = ServiceLocator.analytics,
         onInfoVisibilityChange: @escaping (Bool) -> Void) {
        self.source = source
        self.analytics = analytics
        self.onInfoVisibilityChange = onInfoVisibilityChange
    }

    var body: some View {
        VStack(spacing: StoreSpacing.s0) {
            Spacer(minLength: StoreSpacing.s5)
            HStack(spacing: StoreSpacing.s3) {
                divider
                Text(Localization.or.localizedUppercase)
                    .storeTextStyle(.labelMedium)
                    .foregroundStyle(Color.storePaletteWhite)
                divider
            }
            .accessibilityHidden(true)
            Spacer(minLength: StoreSpacing.s5)
            StoreButton(Localization.useExternalScanner, size: .medium, isFullWidth: true) {
                analytics.track(event: .BarcodeScanning.hardwareBarcodeScannerInfoTapped(from: source))
                isShowingInfo = true
            }
            .accessibilityIdentifier("hardware-barcode-scanner-info-button")
        }
        .padding(.horizontal, StorePadding.p5)
        .padding(.bottom, StorePadding.p5)
        .onChange(of: isShowingInfo) { _, isShowing in
            onInfoVisibilityChange(isShowing)
        }
        .storeSheet(isPresented: $isShowingInfo) {
            HardwareBarcodeScannerInfoView(viewModel: HardwareBarcodeScannerInfoViewModel(source: source, onDismiss: {
                isShowingInfo = false
            }))
        }
    }

    private var divider: some View {
        Rectangle()
            .fill(Color.storeOutlineVariant)
            .frame(height: StoreStrokeWidth.regular)
    }
}

private extension HardwareBarcodeScannerOfferView {
    enum Localization {
        static let or = NSLocalizedString(
            "hardwareBarcodeScannerOffer.or",
            value: "or",
            comment: "Separates scanning with the camera from using an external barcode scanner. Shown in uppercase."
        )
        static let useExternalScanner = NSLocalizedString(
            "hardwareBarcodeScannerOffer.useExternalScanner",
            value: "Use an external scanner",
            comment: "Button on the camera barcode scanner that explains how to use a Bluetooth or USB barcode scanner."
        )
    }
}

#Preview {
    HardwareBarcodeScannerOfferView(source: .orderList, onInfoVisibilityChange: { _ in })
        .frame(height: 200)
        .background(Color.storeOverlayOpacity50)
}
