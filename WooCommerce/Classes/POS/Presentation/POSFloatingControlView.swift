import SwiftUI

@available(iOS 17.0, *)
struct POSFloatingControlView: View {
    @Environment(\.posBackgroundAppearance) var backgroundAppearance
    @Environment(PointOfSaleAggregateModel.self) private var posModel
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Binding private var showExitPOSModal: Bool
    @Binding private var showSupport: Bool
    @Binding private var showDocumentation: Bool

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
            .disabled(posModel.paymentState == .card(.processingPayment))

            CardReaderConnectionStatusView()
                .foregroundStyle(fontColor)
                .background(backgroundColor)
                .cornerRadius(Constants.cornerRadius)
                .disabled(posModel.paymentState.shownFullScreen)
                .disabled(horizontalSizeClass != .regular)

            if ServiceLocator.featureFlagService.isFeatureFlagEnabled(.starReceiptPrinterSupport) {
                Button {
                    posModel.startPrinterDiscovery()
                } label: {
                    VStack {
                        Spacer()
                        Image(systemName: "printer")
                            .font(.posBodyLargeBold)
                            .dynamicTypeSize(...DynamicTypeSize.accessibility2)
                        Spacer()
                    }
                    .frame(width: Constants.size)
                }
                .background(backgroundColor)
                .cornerRadius(Constants.cornerRadius)
            }
        }
        .frame(height: Constants.size)
        .background(Color.clear)
        .animation(.default, value: backgroundAppearance)
        .posShadow(.large)
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
            comment: "The title of the floating button to exit Point of Sale, shown in a popover menu." +
            "The action is confirmed in a modal."
        )

        static let getSupport = NSLocalizedString(
            "pointOfSale.floatingButtons.getSupport.button.title",
            value: "Get Support",
            comment: "The title of the floating button to get support for Point of Sale, shown in a popover menu."
        )

        static let viewDocumentation = NSLocalizedString(
            "pointOfSale.floatingButtons.viewDocumentation.button.title",
            value: "Documentation",
            comment: "The title of the floating button to read Point of Sale documentation, shown in a popover menu."
        )
    }
}

#if DEBUG

@available(iOS 17.0, *)
#Preview("Reader Disconnected") {
    let posModel = PointOfSaleAggregateModel(
        itemsController: PointOfSalePreviewItemsController(),
        cardPresentPaymentService: CardPresentPaymentPreviewService(),
        orderController: PointOfSalePreviewOrderController(),
        collectOrderPaymentAnalyticsTracker: POSCollectOrderPaymentAnalytics())
    POSFloatingControlView(showExitPOSModal: .constant(false), showSupport: .constant(false), showDocumentation: .constant(false))
        .environment(\.posBackgroundAppearance, .primary)
        .environment(posModel)
}

@available(iOS 17.0, *)
#Preview("Reader Connected") {
    let paymentService = CardPresentPaymentPreviewService()
    let posModel = PointOfSaleAggregateModel(
        itemsController: PointOfSalePreviewItemsController(),
        cardPresentPaymentService: CardPresentPaymentPreviewService(),
        orderController: PointOfSalePreviewOrderController(),
        collectOrderPaymentAnalyticsTracker: POSCollectOrderPaymentAnalytics())
    paymentService.readerConnectionStatus = .connected(.init(name: "", batteryLevel: 0.6))
    return POSFloatingControlView(showExitPOSModal: .constant(false), showSupport: .constant(false), showDocumentation: .constant(false))
        .environment(\.posBackgroundAppearance, .primary)
        .environment(posModel)
}

@available(iOS 17.0, *)
#Preview("Secondary/disabled Background") {
    let posModel = PointOfSaleAggregateModel(
        itemsController: PointOfSalePreviewItemsController(),
        cardPresentPaymentService: CardPresentPaymentPreviewService(),
        orderController: PointOfSalePreviewOrderController(),
        collectOrderPaymentAnalyticsTracker: POSCollectOrderPaymentAnalytics())
    POSFloatingControlView(showExitPOSModal: .constant(false), showSupport: .constant(false), showDocumentation: .constant(false))
        .environment(\.posBackgroundAppearance, .secondary)
        .environment(posModel)
}

#endif
