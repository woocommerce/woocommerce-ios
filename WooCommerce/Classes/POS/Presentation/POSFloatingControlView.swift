import SwiftUI

struct POSFloatingControlView: View {
    @Environment(\.posBackgroundAppearance) var backgroundAppearance
    @Environment(\.posFeatureFlags) private var featureFlags
    @Environment(\.posAnalytics) private var analytics
    @Environment(PointOfSaleAggregateModel.self) private var posModel
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Binding private var showExitPOSModal: Bool
    @Binding private var showSupport: Bool
    @Binding private var showDocumentation: Bool
    @Binding private var showSettings: Bool
    @State private var showProductRestrictionsModal: Bool = false
    @State private var showBarcodeScanningModal: Bool = false
    @State private var showOrders: Bool = false

    init(showExitPOSModal: Binding<Bool>,
         showSupport: Binding<Bool>,
         showDocumentation: Binding<Bool>,
         showSettings: Binding<Bool>) {
        self._showExitPOSModal = showExitPOSModal
        self._showSupport = showSupport
        self._showDocumentation = showDocumentation
        self._showSettings = showSettings
    }

    private var isPOSSettingsEnabled: Bool {
        featureFlags.isFeatureFlagEnabled(.pointOfSaleSettingsi1)
    }

    var body: some View {
        HStack {
            Menu {
                if isPOSSettingsEnabled {
                    compactOptions()
                } else {
                    completeOptions()
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
            PointOfSaleBarcodeScannerSetup(isPresented: $showBarcodeScanningModal, analytics: analytics)
        }
        .posFullScreenCover(isPresented: $showOrders) {
            POSOrdersView(isPresented: $showOrders)
        }
        .frame(height: Constants.size)
        .background(Color.clear)
        .animation(.default, value: backgroundAppearance)
        .posShadow(.large, cornerRadius: Constants.cornerRadius)
    }
}

private extension POSFloatingControlView {
    @ViewBuilder private func compactOptions() -> some View {
        Button {
            analytics.track(.pointOfSaleExitMenuItemTapped)
            showExitPOSModal = true
        } label: {
            Label(
                title: { Text(Localization.exitPointOfSale) },
                icon: { Image(systemName: "rectangle.portrait.and.arrow.forward") }
            )
        }
        if featureFlags.isFeatureFlagEnabled(.pointOfSaleSettingsi1) {
            Button {
                analytics.track(.pointOfSaleSettingsMenuItemTapped)
                showSettings = true
            } label: {
                Label(
                    title: { Text(Localization.settings) },
                    icon: { Image(systemName: "gearshape") }
                )
            }
        }

        if featureFlags.isFeatureFlagEnabled(.pointOfSaleHistoricalOrdersi1) {
            Button {
                showOrders = true
            } label: {
                Label(
                    title: { Text(Localization.orders) },
                    icon: { Image(systemName: "text.document") }
                )
            }
        }
    }

    @ViewBuilder private func completeOptions() -> some View {
        Button {
            analytics.track(.pointOfSaleExitMenuItemTapped)
            showExitPOSModal = true
        } label: {
            Label(
                title: { Text(Localization.exitPointOfSale) },
                icon: { Image(systemName: "rectangle.portrait.and.arrow.forward") }
            )
        }
        Button {
            analytics.track(.pointOfSaleGetSupportTapped)
            showSupport = true
        } label: {
            Label(
                title: { Text(Localization.getSupport) },
                icon: { Image(systemName: "questionmark.circle") }
            )
        }
        Button {
            showDocumentation = true
            analytics.track(.pointOfSaleViewDocsTapped)
        } label: {
            Label(
                title: { Text(Localization.viewDocumentation) },
                icon: { Image(systemName: "info.circle") }
            )
        }
        Button {
            showProductRestrictionsModal = true
            analytics.track(.pointOfSaleSimpleProductsExplanationDialogShown)
        } label: {
            Label(
                title: { Text(Localization.productRestrictionsInfo) },
                icon: { Image(systemName: "magnifyingglass") })
        }
        Button {
            showBarcodeScanningModal = true
            analytics.track(.pointOfSaleBarcodeScanningMenuItemTapped)
        } label: {
            Label(
                title: {
                    Text(Localization.barcodeScanningSetup)
                },
                icon: { Image(systemName: "barcode.viewfinder") })
        }
        if featureFlags.isFeatureFlagEnabled(.pointOfSaleSettingsi1) {
            Button {
                showSettings = true
            } label: {
                Label(
                    title: { Text(Localization.settings) },
                    icon: { Image(systemName: "gearshape") }
                )
            }
        }

        if featureFlags.isFeatureFlagEnabled(.pointOfSaleHistoricalOrdersi1) {
            Button {
                showOrders = true
            } label: {
                Label(
                    title: { Text(Localization.orders) },
                    icon: { Image(systemName: "text.document") }
                )
            }
        }
    }
}

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

extension POSFloatingControlView {
    static var secondaryFontColor: Color {
        .posOnDisabledContainer
    }
}

private extension POSFloatingControlView {
    enum Constants {
        static let size: CGFloat = 80
        static let cornerRadius: CGFloat = POSCornerRadiusStyle.medium.value
    }

    enum Localization {
        static let orders = NSLocalizedString(
            "pointOfSale.floatingButtons.orders.button.title",
            value: "Orders",
            comment: "The title of the menu button to access Point of Sale historical orders, shown in a fullscreen view."
        )

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

        static let barcodeScanningSetup = NSLocalizedString(
            "pointOfSale.floatingButtons.barcodeScanningSetup.button.title",
            value: "Initial barcode scanner setup",
            comment: "The title of the menu button to start a barcode scanner setup flow."
        )

        static let settings = NSLocalizedString(
            "pointOfSale.floatingButtons.settings.button.title",
            value: "Settings",
            comment: "The title of the menu button to access Point of Sale settings."
        )
    }
}

#if DEBUG

#Preview("Reader Disconnected") {
    POSFloatingControlView(showExitPOSModal: .constant(false),
                           showSupport: .constant(false),
                           showDocumentation: .constant(false),
                           showSettings: .constant(false))
        .environment(\.posBackgroundAppearance, .primary)
        .environment(POSPreviewHelpers.makePreviewAggregateModel())
}

#Preview("Reader Connected") {
    let paymentService = CardPresentPaymentPreviewService()
    paymentService.readerConnectionStatus = .connected(.init(name: "", batteryLevel: 0.6))
    let posModel = POSPreviewHelpers.makePreviewAggregateModel(
        cardPresentPaymentService: paymentService
    )
    return POSFloatingControlView(showExitPOSModal: .constant(false),
                                  showSupport: .constant(false),
                                  showDocumentation: .constant(false),
                                  showSettings: .constant(false))
        .environment(\.posBackgroundAppearance, .primary)
        .environment(posModel)
}

#Preview("Secondary/disabled Background") {
    POSFloatingControlView(showExitPOSModal: .constant(false),
                           showSupport: .constant(false),
                           showDocumentation: .constant(false),
                           showSettings: .constant(false))
        .environment(\.posBackgroundAppearance, .secondary)
        .environment(POSPreviewHelpers.makePreviewAggregateModel())
}

#endif
