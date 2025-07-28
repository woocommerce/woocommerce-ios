import SwiftUI

@available(iOS 17.0, *)
struct POSFloatingControlView: View {
    @Environment(\.posBackgroundAppearance) var backgroundAppearance
    @Environment(PointOfSaleAggregateModel.self) private var posModel
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Binding private var showExitPOSModal: Bool
    @Binding private var showSupport: Bool
    @Binding private var showDocumentation: Bool
    @State private var showProductRestrictionsModal: Bool = false
    @State private var showBarcodeScanningModal: Bool = false

    init(showExitPOSModal: Binding<Bool>,
         showSupport: Binding<Bool>,
         showDocumentation: Binding<Bool>) {
        self._showExitPOSModal = showExitPOSModal
        self._showSupport = showSupport
        self._showDocumentation = showDocumentation
    }

    var body: some View {
        HStack {
            Menu {
                Button {
                    ServiceLocator.analytics.track(.pointOfSaleExitMenuItemTapped)
                    showExitPOSModal = true
                } label: {
                    Label(
                        title: { Text(Localization.exitPointOfSale) },
                        icon: { Image(systemName: "rectangle.portrait.and.arrow.forward") }
                    )
                }
                Button {
                    ServiceLocator.analytics.track(.pointOfSaleGetSupportTapped)
                    showSupport = true
                } label: {
                    Label(
                        title: { Text(Localization.getSupport) },
                        icon: { Image(systemName: "questionmark.circle") }
                    )
                }
                Button {
                    showDocumentation = true
                    ServiceLocator.analytics.track(.pointOfSaleViewDocsTapped)
                } label: {
                    Label(
                        title: { Text(Localization.viewDocumentation) },
                        icon: { Image(systemName: "info.circle") }
                    )
                }
                Button {
                    showProductRestrictionsModal = true
                    ServiceLocator.analytics.track(.pointOfSaleSimpleProductsExplanationDialogShown)
                } label: {
                    Label(
                        title: { Text(Localization.productRestrictionsInfo) },
                        icon: { Image(systemName: "magnifyingglass") })
                }
                if ServiceLocator.featureFlagService.isFeatureFlagEnabled(.pointOfSaleBarcodeScanningi1) {
                    Button {
                        showBarcodeScanningModal = true
                        ServiceLocator.analytics.track(.pointOfSaleBarcodeScanningMenuItemTapped)
                    } label: {
                        Label(
                            title: { Text(Localization.barcodeScanning) },
                            icon: { Image(systemName: "barcode.viewfinder") })
                    }
                }
            } label: {
                VStack {
                    Spacer()
                    Image(systemName: "ellipsis")
                        .font(.posBodyLargeBold)
                        .dynamicTypeSize(...DynamicTypeSize.accessibility2)
                        .foregroundStyle(fontColor)
                    Spacer()
                }
                .frame(width: Constants.size)
            }
            .background(backgroundColor)
            .cornerRadius(Constants.cornerRadius)
            .disabled(posModel.paymentState.card == .processingPayment)

            CardReaderConnectionStatusView()
                .foregroundStyle(fontColor)
                .background(backgroundColor)
                .cornerRadius(Constants.cornerRadius)
                .disabled(posModel.paymentState.shownFullScreen)
                .disabled(horizontalSizeClass != .regular)
        }
        .posModal(isPresented: $showProductRestrictionsModal) {
            SimpleProductsOnlyInformation(isPresented: $showProductRestrictionsModal)
        }
        .posModal(isPresented: $showBarcodeScanningModal) {
            if ServiceLocator.featureFlagService.isFeatureFlagEnabled(.pointOfSaleBarcodeScanningi2) {
                PointOfSaleBarcodeScannerSetup(isPresented: $showBarcodeScanningModal)
            } else {
                PointOfSaleBarcodeScannerInformationModal(isPresented: $showBarcodeScanningModal)
            }
        }
        .frame(height: Constants.size)
        .background(Color.clear)
        .animation(.default, value: backgroundAppearance)
        .posShadow(.large, cornerRadius: Constants.cornerRadius)
    }
}

@available(iOS 17.0, *)
private extension POSFloatingControlView {
    var backgroundColor: Color {
        switch backgroundAppearance {
        case .primary:
            .posSurfaceContainerLow
        case .secondary:
            .posDisabledContainer
        }
    }

    var fontColor: Color {
        switch backgroundAppearance {
        case .primary:
            .posOnSurface
        case .secondary:
            Self.secondaryFontColor
        }
    }
}

@available(iOS 17.0, *)
extension POSFloatingControlView {
    static var secondaryFontColor: Color {
        .posOnDisabledContainer
    }
}

@available(iOS 17.0, *)
private extension POSFloatingControlView {
    enum Constants {
        static let size: CGFloat = 80
        static let cornerRadius: CGFloat = POSCornerRadiusStyle.medium.value
    }

    enum Localization {
        static let exitPointOfSale = NSLocalizedString(
            "pointOfSale.floatingButtons.exit.button.title",
            value: "Exit POS",
            comment: "The title of the menu button to exit Point of Sale, shown in a popover menu." +
            "The action is confirmed in a modal."
        )

        static let getSupport = NSLocalizedString(
            "pointOfSale.floatingButtons.getSupport.button.title",
            value: "Get Support",
            comment: "The title of the menu button to get support for Point of Sale, shown in a popover menu."
        )

        static let viewDocumentation = NSLocalizedString(
            "pointOfSale.floatingButtons.viewDocumentation.button.title",
            value: "Documentation",
            comment: "The title of the menu button to read Point of Sale documentation, shown in a popover menu."
        )

        static let productRestrictionsInfo = NSLocalizedString(
            "pointOfSale.floatingButtons.productRestrictionsInfo.button.title",
            value: "Where are my products?",
            comment: "The title of the menu button to view product restrictions info, shown in a popover menu. " +
            "We only show simple and variable products in POS, this shows a modal to help explain that limitation."
        )

        static let barcodeScanning = NSLocalizedString(
            "pointOfSale.floatingButtons.barcodeScanning.button.title",
            value: "Barcode scanning",
            comment: "The title of the menu button to view barcode scanner documentation, shown in a popover menu."
        )
    }
}

#if DEBUG

@available(iOS 17.0, *)
#Preview("Reader Disconnected") {
    POSFloatingControlView(showExitPOSModal: .constant(false), showSupport: .constant(false), showDocumentation: .constant(false))
        .environment(\.posBackgroundAppearance, .primary)
        .environment(POSPreviewHelpers.makePreviewAggregateModel())
}

@available(iOS 17.0, *)
#Preview("Reader Connected") {
    let paymentService = CardPresentPaymentPreviewService()
    paymentService.readerConnectionStatus = .connected(.init(name: "", batteryLevel: 0.6))
    let posModel = POSPreviewHelpers.makePreviewAggregateModel(
        cardPresentPaymentService: paymentService
    )
    return POSFloatingControlView(showExitPOSModal: .constant(false), showSupport: .constant(false), showDocumentation: .constant(false))
        .environment(\.posBackgroundAppearance, .primary)
        .environment(posModel)
}

@available(iOS 17.0, *)
#Preview("Secondary/disabled Background") {
    POSFloatingControlView(showExitPOSModal: .constant(false), showSupport: .constant(false), showDocumentation: .constant(false))
        .environment(\.posBackgroundAppearance, .secondary)
        .environment(POSPreviewHelpers.makePreviewAggregateModel())
}

#endif
