import SwiftUI
import WooFoundation

/// Detail pane shown when "Start session" is selected in `POSCashManagementView`.
struct POSStartCashSessionView: View {
    @Environment(PointOfSaleAggregateModel.self) private var posModel: PointOfSaleAggregateModel?
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.posAnalytics) private var analytics
    @Environment(\.posCurrencyProvider) private var currencyProvider
    @FocusState private var isAmountFocused: Bool
    @State private var startingCashAmount: String = ""
    @State private var startError: String?
    @State private var drawerError: String?
    @State private var isOpeningDrawer = false

    let controller: POSCashSessionController
    let onStarted: () -> Void

    init(controller: POSCashSessionController, onStarted: @escaping () -> Void, initialError: String? = nil) {
        self.controller = controller
        self.onStarted = onStarted
        _startError = State(initialValue: initialError)
    }

    private var money: POSCashSessionMoney { .init(settings: currencyProvider.currencySettings) }
    private var isDrawerConnected: Bool {
        posModel?.cashDrawer != nil && posModel?.settingsController.printerConnectionController?.isConnected == true
    }

    var body: some View {
        VStack(spacing: POSSpacing.none) {
            POSPageHeaderView(title: horizontalSizeClass == .compact ? Localization.compactTitle : Localization.title,
                              backButtonConfiguration: nil)
                .accessibilityAddTraits(.isHeader)

            ScrollView {
                VStack(spacing: POSSpacing.medium) {
                    if controller.isSaving {
                        POSInformationCard {
                            VStack(spacing: POSSpacing.xLarge) {
                                ProgressView()
                                    .progressViewStyle(POSProgressViewStyle())
                                    .padding(POSPadding.large)
                                Text(Localization.startingSession)
                                    .font(.posBodyLargeBold)
                                    .foregroundStyle(Color.posOnSurface)
                            }
                            .frame(maxWidth: .infinity, minHeight: Constants.loadingCardHeight)
                        }
                    } else {
                        if let startError {
                            POSNoticeView(title: Localization.startFailed,
                                          icon: Image(systemName: "exclamationmark.triangle"),
                                          style: .alertLowest,
                                          onDismiss: { self.startError = nil }) {
                                Text(startError)
                            }
                        }
                        if let drawerError {
                            POSNoticeView(title: Localization.drawerOpenFailed,
                                          icon: Image(systemName: "exclamationmark.triangle"),
                                          style: .alertLowest,
                                          onDismiss: { self.drawerError = nil }) {
                                Text(drawerError)
                            }
                        }

                        POSInformationCard {
                            VStack(alignment: .leading, spacing: POSSpacing.medium) {
                                Text(Localization.startingCashLabel)
                                    .font(.posBodyLargeBold)
                                    .foregroundStyle(Color.posOnSurface)

                                HStack {
                                    POSCashAmountTextField(
                                        amount: $startingCashAmount,
                                        isFocused: $isAmountFocused,
                                        currencySettings: currencyProvider.currencySettings,
                                        preset: 0,
                                        onSubmit: { isAmountFocused = false }
                                    )
                                    Spacer()
                                }
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.posSurface)
                                .clipShape(RoundedRectangle(cornerRadius: POSCornerRadiusStyle.medium.value))

                            }
                        }
                    }
                }
                .padding(.horizontal, POSPadding.medium)
            }
            .scrollDismissesKeyboard(.interactively)

            if !controller.isSaving {
                actionButtons
                    .padding(.horizontal, POSPadding.medium)
                    .padding(.vertical, POSPadding.medium)
            }
        }
        .ignoresSafeArea(.posContainerRegionToIgnore, edges: .bottom)
        .background(Color.posSurface)
        .accessibilityIdentifier("pos-cash-drawer-start-session-view")
    }

    private var actionButtons: some View {
        VStack(spacing: POSSpacing.small) {
            HStack(spacing: POSSpacing.small) {
                Button {
                    guard let cashDrawer = posModel?.cashDrawer else { return }
                    drawerError = nil
                    isOpeningDrawer = true
                    Task {
                        let result = await cashDrawer.openBeforeSession()
                        isOpeningDrawer = false
                        switch result {
                        case .opened:
                            isAmountFocused = true
                        case .notConnected:
                            drawerError = Localization.printerNotConnected
                        case .failed, .noSession:
                            drawerError = Localization.drawerOpenFailed
                        }
                    }
                } label: {
                    Text(Localization.openDrawerButtonTitle)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                }
                .buttonStyle(POSOutlinedButtonStyle(size: .normal, isLoading: isOpeningDrawer))
                .disabled(!isDrawerConnected || isOpeningDrawer)
                .frame(maxWidth: .infinity)
                .accessibilityIdentifier("pos-cash-drawer-open-before-session-button")

                Button {
                    analytics.track(.pointOfSaleCashDrawerStartSessionButtonTapped)
                    startError = nil
                    guard let amount = money.parse(startingCashAmount), amount >= 0 else {
                        startError = Localization.invalidAmount
                        return
                    }
                    Task {
                        if await controller.start(openingCash: amount) {
                            onStarted()
                        } else {
                            startError = controller.errorMessage ?? Localization.startFailed
                            controller.errorMessage = nil
                        }
                    }
                } label: {
                    Text(Localization.startSessionButtonTitle)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                }
                .buttonStyle(POSFilledButtonStyle(size: .normal))
                .disabled(isOpeningDrawer)
                .frame(maxWidth: .infinity)
            }

            if !isDrawerConnected {
                Text(Localization.printerNotConnected)
                    .font(.posBodySmallRegular())
                    .foregroundStyle(Color.posOnSurfaceVariantLowest)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}

private extension POSStartCashSessionView {
    enum Constants {
        static let loadingCardHeight: CGFloat = 220
    }

    enum Localization {
        static let title = NSLocalizedString(
            "pointOfSaleStartCashSessionView.cashSessionTitle",
            value: "Start a cash session",
            comment: "Title of the start cash session screen."
        )

        static let compactTitle = NSLocalizedString("pointOfSaleStartCashSessionView.compactTitle", value: "Start session",
                                                    comment: "Title of the start cash session screen on iPhone")

        static let startingCashLabel = NSLocalizedString(
            "pointOfSaleStartCashSessionView.startingCashLabel",
            value: "Starting cash",
            comment: "Label for the starting cash amount field when starting a cash session."
        )

        static let startSessionButtonTitle = NSLocalizedString(
            "pointOfSaleStartCashSessionView.startSessionButtonTitle",
            value: "Start session",
            comment: "Title of the button that starts a new cash session."
        )

        static let openDrawerButtonTitle = NSLocalizedString(
            "pointOfSaleStartCashSessionView.openDrawerButtonTitle",
            value: "Open drawer",
            comment: "Button that opens the drawer before the cashier counts starting cash."
        )

        static let drawerOpenFailed = NSLocalizedString(
            "pointOfSaleStartCashSessionView.drawerOpenFailed",
            value: "Could not open the drawer",
            comment: "Error shown when opening the cash drawer before a session fails."
        )

        static let printerNotConnected = NSLocalizedString(
            "pointOfSaleStartCashSessionView.printerNotConnected",
            value: "Connect the receipt printer in Settings, then try again.",
            comment: "Error shown when the cash drawer cannot open because its receipt printer is disconnected."
        )

        static let invalidAmount = NSLocalizedString(
            "pointOfSaleStartCashSessionView.invalidAmount",
            value: "Enter a valid starting cash amount.",
            comment: "Error shown when starting cash cannot be parsed."
        )

        static let startingSession = NSLocalizedString(
            "pointOfSaleStartCashSessionView.startingSession",
            value: "Starting session",
            comment: "Loading message while opening a cash session."
        )

        static let startFailed = NSLocalizedString(
            "pointOfSaleStartCashSessionView.startFailed",
            value: "Could not start the session",
            comment: "Error heading when a cash session fails to open."
        )
    }
}

#if DEBUG
#Preview {
    POSStartCashSessionView(controller: POSCashSessionController(service: POSMockCashSessionService()), onStarted: {})
        .environment(POSPreviewHelpers.makePreviewAggregateModel())
}
#endif
