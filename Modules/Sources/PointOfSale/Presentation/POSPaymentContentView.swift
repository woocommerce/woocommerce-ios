import SwiftUI

// MARK: - Shared Payment Content View

/// Shared payment content view used by the bookings flow.
/// Handles close button, payment state rendering, static totals fields, cash button,
/// background color, and payment modal bindings.
///
/// The cart flow (TotalsView) uses the shared sub-components directly
/// because it has additional complexity (shimmering, order errors, layout padding).
struct POSPaymentContentView: View {
    let formattedSubtotal: String
    let formattedTax: String
    let formattedTotal: String
    let onDismiss: (() -> Void)?

    @Environment(POSPaymentModel.self) private var paymentModel
    private let viewHelper = TotalsViewHelper()

    var body: some View {
        @Bindable var paymentModel = paymentModel

        VStack(spacing: POSSpacing.none) {
            Spacer()

            paymentContentView

            if shouldShowTotalsFields {
                totalsFieldsView
            }

            Spacer()
                .renderedIf(viewHelper.shouldApplyPadding(paymentState: paymentModel.paymentState))

            cashPaymentButtonView
        }
        .background(viewHelper.paymentBackgroundColor(for: paymentModel.paymentState))
        .animation(.default, value: paymentModel.paymentState)
        .overlay(alignment: .topTrailing) {
            closeButton
        }
        .posModal(item: $paymentModel.cardPresentPaymentAlertViewModel, onDismiss: {
            paymentModel.cardPresentPaymentAlertViewModel?.onDismiss?()
        }) { alertType in
            PointOfSaleCardPresentPaymentAlert(alertType: alertType)
                .posInteractiveDismissDisabled(alertType.isDismissDisabled)
        }
        .posModal(item: $paymentModel.cardPresentPaymentOnboardingViewContainer, onDismiss: {
            paymentModel.cancelCardPaymentsOnboarding()
        }) { factory in
            PointOfSaleCardPresentPaymentOnboardingView(viewModel: .init(
                onboardingViewContainer: factory,
                onDismissTap: {
                    paymentModel.cancelCardPaymentsOnboarding()
                }))
            .onAppear {
                paymentModel.trackCardPaymentsOnboardingShown()
            }
        }
    }

    // MARK: - Close Button

    @ViewBuilder
    private var closeButton: some View {
        if let onDismiss,
           paymentModel.configuration.showInitialCloseButton,
           !paymentModel.paymentState.shownFullScreen {
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.posBodyLargeBold)
                    .dynamicTypeSize(...DynamicTypeSize.accessibility2)
                    .foregroundColor(.posOnSurface)
                    .padding(POSPadding.small)
            }
            .padding(POSPadding.medium)
        }
    }

    // MARK: - Payment Content

    @ViewBuilder
    private var paymentContentView: some View {
        switch paymentModel.paymentState.activePaymentMethod {
        case .cash:
            POSCashPaymentContentView(
                cashPaymentState: paymentModel.paymentState.cash,
                formattedOrderTotal: formattedTotal)
        case .card:
            POSCardPaymentContentView(
                cardReaderConnectionStatus: paymentModel.cardReaderConnectionStatus,
                paymentState: paymentModel.paymentState,
                cardPresentPaymentInlineMessage: paymentModel.cardPresentPaymentInlineMessage,
                connectCardReaderAction: paymentModel.connectCardReader,
                showLoadingWhenIdle: true)
        }
    }

    // MARK: - Totals Fields

    private var shouldShowTotalsFields: Bool {
        viewHelper.shouldShowTotalsFields(for: paymentModel.paymentState)
    }

    @ViewBuilder
    private var totalsFieldsView: some View {
        HStack(alignment: .center) {
            Spacer()
            VStack {
                subtotalRow(
                    title: Localization.subtotal,
                    formattedPrice: formattedSubtotal)

                Spacer().frame(height: POSSpacing.medium)

                subtotalRow(
                    title: Localization.taxes,
                    formattedPrice: formattedTax)

                Spacer().frame(height: POSSpacing.medium)

                Divider()
                    .overlay(Color.posOutlineVariant)

                Spacer().frame(height: POSSpacing.medium)

                HStack(alignment: .top, spacing: .zero) {
                    Text(Localization.total)
                        .font(.posHeadingBold)
                        .fontWeight(.semibold)
                    Spacer(minLength: POSSpacing.large)
                    Text(formattedTotal)
                        .font(.posHeadingBold)
                }
                .accessibilityElement(children: .combine)
                .accessibilityAddTraits(.isHeader)
                .foregroundColor(Color.posOnSurface)
            }
            .padding(EdgeInsets(
                top: POSPadding.medium,
                leading: POSPadding.large,
                bottom: POSPadding.medium,
                trailing: POSPadding.large))
            .frame(minWidth: 382)
            .fixedSize(horizontal: true, vertical: false)
            Spacer()
        }
        .transition(.opacity)
        .layoutPriority(1)
        .dynamicTypeSize(...DynamicTypeSize.accessibility1)
    }

    @ViewBuilder
    private func subtotalRow(title: String, formattedPrice: String) -> some View {
        HStack(alignment: .top, spacing: .zero) {
            Text(title)
                .font(.posBodyLargeRegular())
            Spacer()
            Text(formattedPrice)
                .font(.posBodyLargeRegular())
        }
        .accessibilityElement(children: .combine)
        .foregroundColor(Color.posOnSurface)
    }

    // MARK: - Cash Payment Button

    @ViewBuilder
    private var cashPaymentButtonView: some View {
        if viewHelper.shouldShowCashPaymentButton(
            paymentState: paymentModel.paymentState,
            cardReaderConnectionStatus: paymentModel.cardReaderConnectionStatus) {
            Button(action: {
                Task { @MainActor in
                    await paymentModel.startCashPayment()
                }
            }) {
                Text(Localization.cashPaymentButton)
                    .font(POSFontStyle.posBodyLargeBold)
            }
            .buttonStyle(POSOutlinedButtonStyle(size: .normal))
            .padding(.horizontal, POSPadding.medium)
            .safeAreaPadding(.bottom, POSPadding.medium)
        }
    }
}

// MARK: - Localization

private extension POSPaymentContentView {
    enum Localization {
        static let subtotal = NSLocalizedString(
            "pointOfSale.paymentContent.subtotal",
            value: "Subtotal",
            comment: "Label for the subtotal amount in the payment content view"
        )

        static let taxes = NSLocalizedString(
            "pointOfSale.paymentContent.taxes",
            value: "Taxes",
            comment: "Label for the taxes amount in the payment content view"
        )

        static let total = NSLocalizedString(
            "pointOfSale.paymentContent.total",
            value: "Total",
            comment: "Label for the total amount in the payment content view"
        )

        static let cashPaymentButton = NSLocalizedString(
            "pointOfSale.paymentContent.cashPaymentButton",
            value: "Cash payment",
            comment: "Button to start a cash payment in the payment flow"
        )
    }
}

// MARK: - Shared Card Payment Content

/// Shared card payment content rendering used by both cart and bookings flows.
/// Handles reader disconnected message, inline payment messages, and optional loading state.
struct POSCardPaymentContentView: View {
    let cardReaderConnectionStatus: CardPresentPaymentReaderConnectionStatus
    let paymentState: PointOfSalePaymentState
    let cardPresentPaymentInlineMessage: PointOfSaleCardPresentPaymentMessageType?
    let connectCardReaderAction: () -> Void
    var showLoadingWhenIdle: Bool = false

    private let viewHelper = TotalsViewHelper()

    @ViewBuilder
    var body: some View {
        if viewHelper.shouldShowDisconnectedMessage(readerConnectionStatus: cardReaderConnectionStatus,
                                                    paymentState: paymentState) {
            PointOfSaleCardPresentPaymentReaderDisconnectedMessageView {
                connectCardReaderAction()
            }
        } else if let inlineMessage = cardPresentPaymentInlineMessage {
            switch inlineMessage {
            case .paymentSuccess:
                PointOfSaleCardPresentPaymentInLineMessage(messageType: inlineMessage)
            default:
                HStack(alignment: .center) {
                    Spacer()
                    PointOfSaleCardPresentPaymentInLineMessage(messageType: inlineMessage)
                    Spacer()
                }
            }
        } else if showLoadingWhenIdle,
                  case .idle = paymentState.card,
                  case .connected = cardReaderConnectionStatus {
            POSPaymentLoadingView()
        }
    }
}

// MARK: - Shared Cash Payment Content

/// Shared cash payment content rendering used by both cart and bookings flows.
struct POSCashPaymentContentView: View {
    let cashPaymentState: PointOfSaleCashPaymentState
    let formattedOrderTotal: String
    @Environment(\.posCurrencyProvider) private var currencyProvider

    var body: some View {
        switch cashPaymentState {
        case .collectingCash:
            PointOfSaleCollectCashView(orderTotal: formattedOrderTotal,
                                       currencySettings: currencyProvider.currencySettings)
                .transition(.move(edge: .trailing))
        case .paymentSuccess:
            PointOfSaleCardPresentPaymentInLineMessage(
                messageType: .paymentSuccess(
                    viewModel: .init(formattedOrderTotal: formattedOrderTotal,
                                     paymentMethod: .cash)))
        case .idle:
            EmptyView()
        }
    }
}

// MARK: - Payment Loading View

/// Loading spinner shown while waiting for order data during payment.
struct POSPaymentLoadingView: View {
    var body: some View {
        VStack(alignment: .center, spacing: POSSpacing.xLarge) {
            ProgressView()
                .progressViewStyle(POSProgressViewStyle())
                .frame(width: 160, height: 160)

            VStack(alignment: .center, spacing: PointOfSaleCardPresentPaymentLayout.textSpacing) {
                Text(Localization.title)
                    .foregroundStyle(Color.posOnSurfaceVariantHighest)
                    .font(.posBodyLargeRegular())

                Text(Localization.message)
                    .font(.posHeadingBold)
                    .foregroundStyle(Color.posOnSurface)
            }
        }
        .multilineTextAlignment(.center)
    }

    private enum Localization {
        static let title = NSLocalizedString(
            "pointOfSale.payment.loading.title",
            value: "Getting ready",
            comment: "Title shown while loading the order for a payment in Point of Sale"
        )

        static let message = NSLocalizedString(
            "pointOfSale.payment.loading.message",
            value: "Loading order",
            comment: "Message shown while loading the order for a payment in Point of Sale"
        )
    }
}
