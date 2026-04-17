import SwiftUI
import struct WooFoundation.WooAnalyticsEvent
import enum Hardware.DeviceStatus

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
    @State private var showBookings: Bool = false
    @Environment(\.posBookingsEligible) private var isBookingsEligible

    init(showExitPOSModal: Binding<Bool>,
         showSupport: Binding<Bool>,
         showDocumentation: Binding<Bool>,
         showSettings: Binding<Bool>) {
        self._showExitPOSModal = showExitPOSModal
        self._showSupport = showSupport
        self._showDocumentation = showDocumentation
        self._showSettings = showSettings
    }

    var body: some View {
        @Bindable var posModel = posModel
        HStack {
            Menu {
                menuOptions()
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
            .accessibilityIdentifier("pos-menu-button")
            .background(backgroundColor)
            .cornerRadius(Constants.cornerRadius)
            .disabled(posModel.paymentState.card == .processingPayment)

            CardReaderConnectionStatusView()
                .foregroundStyle(fontColor)
                .background(backgroundColor)
                .cornerRadius(Constants.cornerRadius)
                .disabled(posModel.paymentState.shownFullScreen)
                .disabled(horizontalSizeClass != .regular)

            if featureFlags.isFeatureFlagEnabled(.starReceiptPrinterSupport),
               posModel.orderStage == .building {
                switch posModel.printerConnectionState {
                case .connected:
                    Menu {
                        Button {
                            posModel.disconnectPrinter()
                        } label: {
                            Text("Disconnect Printer")
                        }
                    } label: {
                        printerConnectionButton
                    }
                default:
                    printerConnectionButton
                }
                switch posModel.printerDiscoveryState {
                case .searching, .found([]):
                    VStack {
                        Spacer()
                        Text("Turn your printer on")
                        Spacer()
                    }
                    .padding(.horizontal, POSPadding.medium)
                    .foregroundStyle(fontColor)
                    .background(backgroundColor)
                    .cornerRadius(Constants.cornerRadius)
                    .id("printerGuide")
                    .transition(.asymmetric(insertion: .push(from: .leading), removal: .push(from: .trailing)))
                case .found(let devices):
                    if devices.count == 1,
                       let printer = devices.first {
                        Button {
                            posModel.connect(printer: printer)
                        } label: {
                            VStack {
                                Spacer()
                                Text("Connect to \(printer.name)")
                                Spacer()
                            }
                            .padding(.horizontal, POSPadding.medium)
                        }
                        .foregroundStyle(fontColor)
                        .background(backgroundColor)
                        .cornerRadius(Constants.cornerRadius)
                        .id("printerGuide")
                        .transition(.asymmetric(insertion: .push(from: .leading), removal: .push(from: .trailing)))
                    }
                default:
                    EmptyView()
                }
            }
        }
        .animation(.default, value: posModel.printerDiscoveryState)
        .posModal(isPresented: $showProductRestrictionsModal) {
            SimpleProductsOnlyInformation(isPresented: $showProductRestrictionsModal)
        }
        .posModal(isPresented: $showBarcodeScanningModal) {
            POSBarcodeScannerSetup(isPresented: $showBarcodeScanningModal, analytics: analytics)
        }
        .posFullScreenCover(isPresented: $showOrders) {
            POSOrdersView(isPresented: $showOrders)
        }
        .posFullScreenCover(isPresented: $showBookings) {
            POSBookingsContainerView(isPresented: $showBookings)
                .environment(\.floatingControlAreaSize, .zero)
        }
        .onChange(of: showBookings) { _, isShowing in
            if isShowing {
                posModel.paymentModel.deactivate()
            } else if posModel.orderStage == .finalizing {
                Task { @MainActor in
                    await posModel.paymentModel.activate()
                }
            }
        }
        .frame(height: Constants.size)
        .background(Color.clear)
        .animation(.default, value: backgroundAppearance)
        .posShadow(.large, cornerRadius: Constants.cornerRadius)
        .posModal(item: $posModel.showPrintersFoundModal, onDismiss: {
            posModel.stopPrinterDiscovery()
        }) { discoveryState in
            switch discoveryState {
            case .searching:
                VStack(alignment: .center, spacing: POSSpacing.xLarge) {
                    ProgressView()
                        .progressViewStyle(POSProgressViewStyle())
                        .frame(width: 160,
                               height: 160)
                    VStack(alignment: .center, spacing: POSSpacing.small) {
                        Text("Searching for printers")
                            .foregroundStyle(Color.posOnSurface)
                            .font(.posBodyLargeRegular())
                    }
                }
                .multilineTextAlignment(.center)
                .posModalSizing()
            case .found(let printers):
                if printers.containsMoreThanOne {
                    VStack(alignment: .center, spacing: POSSpacing.xLarge) {
                        Image(systemName: "printer")
                            .resizable()
                            .frame(width: 160,
                                   height: 160)
                        VStack(alignment: .center, spacing: POSSpacing.small) {
                            Text("Found \(printers.count) printer(s)")

                            ForEach(printers) { printer in
                                Button {
                                    posModel.connect(printer: printer)
                                } label: {
                                    Text("Connect to \(printer.name)")
                                }
                            }
                        }
                    }
                    .posModalSizing()
                }
            case .error:
                Text("Error finding printers")
            case .connecting:
                Text("Connecting to printer...")
            }
        }
    }
}

private extension POSFloatingControlView {
    @ViewBuilder private func menuOptions() -> some View {
        Button {
            analytics.track(.pointOfSaleExitMenuItemTapped)
            showExitPOSModal = true
        } label: {
            Label(
                title: { Text(Localization.exitPointOfSale) },
                icon: { Image(systemName: "rectangle.portrait.and.arrow.forward") }
            )
        }
        .accessibilityIdentifier("pos-exit-menu-item")
        if horizontalSizeClass == .regular {
            Button {
                analytics.track(.pointOfSaleSettingsMenuItemTapped)
                showSettings = true
            } label: {
                Label(
                    title: { Text(Localization.settings) },
                    icon: { Image(systemName: "gearshape") }
                )
            }

            if featureFlags.isFeatureFlagEnabled(.pointOfSaleHistoricalOrdersi1) {
                Button {
                    analytics.track(event: WooAnalyticsEvent.PointOfSale.ordersMenuItemTapped())
                    showOrders = true
                } label: {
                    Label(
                        title: { Text(Localization.orders) },
                        icon: { Image(systemName: "text.document") }
                    )
                }
            }

            if featureFlags.isFeatureFlagEnabled(.pointOfSaleBookings) && isBookingsEligible {
                Button {
                    analytics.track(event: WooAnalyticsEvent.PointOfSale.bookingsMenuItemTapped())
                    showBookings = true
                } label: {
                    Label(
                        title: { Text(Localization.bookings) },
                        icon: { Image(systemName: "calendar") }
                    )
                }
            }
        }
    }
}

// MARK: - Printer UI
private extension POSFloatingControlView {
    @ViewBuilder var printerConnectionButton: some View {
        Button {
            posModel.startPrinterDiscovery()
        } label: {
            VStack {
                Spacer()
                Image(systemName: "printer")
                    .font(.posBodyLargeBold)
                    .foregroundStyle(fontColor)
                    .dynamicTypeSize(...DynamicTypeSize.accessibility2)
                    .overlay(alignment: .bottomLeading) {
                        switch posModel.printerConnectionState {
                        case .connected:
                            circleIcon(with: .posSuccess)
                        case .disconnected:
                            circleIcon(with: .posAlert)
                        case .connecting, .disconnecting:
                            ProgressView()
                                .progressViewStyle(POSProgressViewStyle(
                                    size: 12,
                                    lineWidth: 4
                                ))
                        default:
                            EmptyView()
                        }
                    }
                Spacer()
            }
            .frame(width: Constants.size)
        }
        .background(backgroundColor)
        .cornerRadius(Constants.cornerRadius)
        .disabled(posModel.paymentState.shownFullScreen)
    }

    @ViewBuilder
    func circleIcon(with color: Color) -> some View {
        Image(systemName: "circle.fill")
            .resizable()
            .frame(width: 14, height: 14)
            .foregroundColor(color)
            .accessibilityHidden(true)
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

        static let bookings = NSLocalizedString(
            "pointOfSale.floatingButtons.bookings.button.title",
            value: "Bookings",
            comment: "The title of the menu button to access Point of Sale bookings, shown in a fullscreen view."
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
