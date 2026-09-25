import SwiftUI
import WooFoundation

/// Detail pane shown when "Start session" is selected in `POSCashDrawerView`.
struct POSStartCashSessionView: View {
    @Environment(\.posAnalytics) private var analytics
    @Environment(\.posCurrencyProvider) private var currencyProvider
    @FocusState private var isAmountFocused: Bool
    @State private var startingCashAmount: String = ""
    @State private var startError: String?

    let controller: POSCashSessionController
    let onStarted: () -> Void

    init(controller: POSCashSessionController, onStarted: @escaping () -> Void, initialError: String? = nil) {
        self.controller = controller
        self.onStarted = onStarted
        _startError = State(initialValue: initialError)
    }

    private var money: POSCashSessionMoney { .init(settings: currencyProvider.currencySettings) }

    var body: some View {
        VStack(spacing: POSSpacing.none) {
            POSPageHeaderView(title: Localization.title, backButtonConfiguration: nil)
                .accessibilityAddTraits(.isHeader)

            ScrollView {
                VStack(spacing: POSSpacing.medium) {
                    if controller.isSaving {
                        POSInformationCard {
                            VStack(spacing: POSSpacing.medium) {
                                ProgressView()
                                    .progressViewStyle(POSProgressViewStyle())
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

                                Button(Localization.startSessionButtonTitle) {
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
                                }
                                .buttonStyle(POSFilledButtonStyle(size: .normal))
                                .frame(maxWidth: .infinity)
                            }
                        }
                    }
                }
                .padding(.horizontal, POSPadding.medium)
            }
        }
        .background(Color.posSurface)
        .accessibilityIdentifier("pos-cash-drawer-start-session-view")
    }
}

private extension POSStartCashSessionView {
    enum Constants {
        static let loadingCardHeight: CGFloat = 220
    }

    enum Localization {
        static let title = NSLocalizedString(
            "pointOfSaleStartCashSessionView.title",
            value: "Start a cash drawer session",
            comment: "Title of the start cash drawer session screen."
        )

        static let startingCashLabel = NSLocalizedString(
            "pointOfSaleStartCashSessionView.startingCashLabel",
            value: "Starting cash",
            comment: "Label for the starting cash amount field when starting a cash drawer session."
        )

        static let startSessionButtonTitle = NSLocalizedString(
            "pointOfSaleStartCashSessionView.startSessionButtonTitle",
            value: "Start session",
            comment: "Title of the button that starts a new cash drawer session."
        )

        static let invalidAmount = NSLocalizedString(
            "pointOfSaleStartCashSessionView.invalidAmount",
            value: "Enter a valid starting cash amount.",
            comment: "Error shown when starting cash cannot be parsed."
        )

        static let startingSession = NSLocalizedString(
            "pointOfSaleStartCashSessionView.startingSession",
            value: "Starting session",
            comment: "Loading message while opening a cash drawer session."
        )

        static let startFailed = NSLocalizedString(
            "pointOfSaleStartCashSessionView.startFailed",
            value: "Could not start the session",
            comment: "Error heading when a cash drawer session fails to open."
        )
    }
}

#if DEBUG
#Preview {
    POSStartCashSessionView(controller: POSCashSessionController(service: POSMockCashSessionService()), onStarted: {})
}
#endif
