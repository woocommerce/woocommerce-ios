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
    private let viewHelper = POSPaymentViewHelper()
    @Namespace private var paymentMessageNamespace

    /// Payment state with in-progress secondary methods neutralized.
    /// `.collectingCash` (cash) and `.confirming`/`.processing` (mark-as-paid) all live in their
    /// own modal/navigation push. Only success and idle remain visible here.
    private var displayPaymentState: PointOfSalePaymentState {
        let cash: PointOfSaleCashPaymentState = paymentModel.paymentState.cash == .collectingCash
            ? .idle : paymentModel.paymentState.cash
        let markAsPaid: PointOfSaleMarkAsPaidState = paymentModel.paymentState.markAsPaid == .confirming
            || paymentModel.paymentState.markAsPaid == .processing
            ? .idle : paymentModel.paymentState.markAsPaid
        return PointOfSalePaymentState(card: paymentModel.paymentState.card,
                                       cash: cash,
                                       markAsPaid: markAsPaid)
    }

    var body: some View {
        @Bindable var paymentModel = paymentModel

        VStack(spacing: POSSpacing.none) {
            Spacer()

            paymentContentView

            if shouldShowTotalsFields {
                Spacer()
                totalsFieldsView
            }

            Spacer()
                .renderedIf(viewHelper.shouldApplyPadding(paymentState: displayPaymentState))

            cashPaymentButtonView
        }
        .background(viewHelper.paymentBackgroundColor(for: displayPaymentState))
        .animation(.default, value: displayPaymentState.card)
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
           !displayPaymentState.shownFullScreen {
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
        switch displayPaymentState.activePaymentMethod {
        case .cash:
            PointOfSaleCardPresentPaymentInLineMessage(
                messageType: .paymentSuccess(
                    viewModel: .init(formattedOrderTotal: formattedTotal,
                                     paymentMethod: .cash)),
                animation: .init(namespace: paymentMessageNamespace))
        case .markAsPaid:
            PointOfSaleCardPresentPaymentInLineMessage(
                messageType: .paymentSuccess(
                    viewModel: .init(formattedOrderTotal: formattedTotal,
                                     paymentMethod: .markAsPaid)),
                animation: .init(namespace: paymentMessageNamespace))
        case .card:
            POSCardPaymentContentView(
                cardReaderConnectionStatus: paymentModel.cardReaderConnectionStatus,
                paymentState: displayPaymentState,
                cardPresentPaymentInlineMessage: paymentModel.cardPresentPaymentInlineMessage,
                connectCardReaderAction: paymentModel.connectCardReader,
                cancelReconnectionAction: paymentModel.cancelReconnection,
                showLoadingWhenIdle: !paymentModel.isZeroTotal)
        }
    }

    // MARK: - Totals Fields

    private var shouldShowTotalsFields: Bool {
        viewHelper.shouldShowTotalsFields(for: displayPaymentState)
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
            paymentState: displayPaymentState,
            cardReaderConnectionStatus: paymentModel.cardReaderConnectionStatus,
            isZeroTotal: paymentModel.isZeroTotal) {
            Button(action: {
                paymentModel.startCashPayment()
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
    let cancelReconnectionAction: () -> Void
    var showLoadingWhenIdle: Bool = false

    private let viewHelper = POSPaymentViewHelper()
    private let totalsViewHelper = TotalsViewHelper()
    @Namespace private var paymentMessageNamespace
    private var paymentMessageAnimation: POSCardPresentPaymentInLineMessageAnimation {
        .init(namespace: paymentMessageNamespace)
    }

    @ViewBuilder
    var body: some View {
        if totalsViewHelper.shouldShowReconnectingMessage(readerConnectionStatus: cardReaderConnectionStatus,
                                                          paymentState: paymentState) {
            PointOfSaleCardPresentPaymentReconnectingMessageView {
                cancelReconnectionAction()
            }
        } else if viewHelper.shouldShowDisconnectedMessage(readerConnectionStatus: cardReaderConnectionStatus,
                                                    paymentState: paymentState) {
            PointOfSaleCardPresentPaymentReaderDisconnectedMessageView(animation: paymentMessageAnimation)
        } else if let spinnerMessage = activeSpinnerMessage {
            POSPaymentLoadingView(title: spinnerMessage.title,
                                  message: spinnerMessage.message,
                                  animation: paymentMessageAnimation)
        } else if let inlineMessage = cardPresentPaymentInlineMessage {
            switch inlineMessage {
            case .paymentSuccess:
                PointOfSaleCardPresentPaymentInLineMessage(messageType: inlineMessage,
                                                           animation: paymentMessageAnimation)
            default:
                HStack(alignment: .center) {
                    Spacer()
                    PointOfSaleCardPresentPaymentInLineMessage(messageType: inlineMessage,
                                                               animation: paymentMessageAnimation)
                    Spacer()
                }
            }
        }
    }

    /// Routes all spinner states through one branch so the ProgressView keeps its identity.
    private var activeSpinnerMessage: (title: String, message: String)? {
        if let inlineMessage = cardPresentPaymentInlineMessage {
            switch inlineMessage {
            case .validatingOrder(let vm):
                return (vm.title, vm.message)
            case .preparingForPayment(let vm):
                return (vm.title, vm.message)
            default:
                return nil
            }
        }
        if showLoadingWhenIdle,
           case .idle = paymentState.card,
           case .connected = cardReaderConnectionStatus {
            return (POSPaymentLoadingView.Localization.title,
                    POSPaymentLoadingView.Localization.message)
        }
        return nil
    }
}

// MARK: - Payment Loading View

/// Spinner + text view used for idle-loading, validatingOrder, and preparingForPayment states.
/// Rendered as a single persistent branch so the ProgressView animation state is preserved.
struct POSPaymentLoadingView: View {
    let title: String
    let message: String
    let animation: POSCardPresentPaymentInLineMessageAnimation
    @AccessibilityFocusState private var isMessageFocused: Bool
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        VStack(alignment: .center, spacing: POSSpacing.xLarge) {
            ProgressView()
                .progressViewStyle(POSProgressViewStyle())
                .frame(width: 160, height: 160)
                .matchedGeometryEffect(id: animation.iconTransitionId, in: animation.namespace, properties: .position)
                .renderedIf(!dynamicTypeSize.isAccessibilitySize)

            VStack(alignment: .center, spacing: PointOfSaleCardPresentPaymentLayout.textSpacing) {
                Text(title)
                    .foregroundStyle(Color.posOnSurfaceVariantHighest)
                    .font(.posBodyLargeRegular())
                    .matchedGeometryEffect(id: animation.titleTransitionId, in: animation.namespace, properties: .position)

                Text(message)
                    .font(.posHeadingBold)
                    .foregroundStyle(Color.posOnSurface)
                    .accessibilityFocused($isMessageFocused)
                    .matchedGeometryEffect(id: animation.messageTransitionId, in: animation.namespace, properties: .position)
            }
            .transaction { $0.animation = nil }
        }
        .multilineTextAlignment(.center)
        .onAppear {
            isMessageFocused = true
        }
        .onChange(of: message) {
            isMessageFocused = true
        }
    }

    enum Localization {
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
