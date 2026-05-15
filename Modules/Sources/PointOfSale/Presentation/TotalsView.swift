import SwiftUI
import WooFoundation
import Experiments

struct TotalsView: View {
    @Environment(PointOfSaleAggregateModel.self) private var posModel
    @Environment(POSPaymentModel.self) private var paymentModel
    @Environment(\.posFeatureFlags) private var featureFlags
    @Environment(\.posAnalytics) private var analytics
    private let viewHelper = POSPaymentViewHelper()
    private let totalsViewHelper = TotalsViewHelper()

    @State private var isShowingOtherPaymentMethodsPopover: Bool = false

    /// Used together with .matchedGeometryEffect to synchronize the animations of shimmeringLineView and text fields.
    /// This makes SwiftUI treat these views as a single entity in the context of animation.
    /// It allows for a simultaneous transition from the shimmering effect to the text fields,
    /// and movement from the center of the VStack to their respective positions.
    @Namespace private var totalsFieldAnimation

    // The source of truth for whether totals _are_ showing; separate from whether they
    // _should be_ showing, so that we can animate the change.
    // Default true so totals fields would be included in the view hiearchy on first render and animate with TotalsView
    @State private var isShowingTotalsFields: Bool = true

    /// Payment state with in-progress secondary methods neutralized.
    /// `.collectingCash` (cash), `.showingQRCode` (scan-to-pay), and `.confirming`/`.processing`
    /// (mark-as-paid) all live in their own modal/navigation push, so we hide them from TotalsView.
    /// Only success and idle remain visible.
    private var displayPaymentState: PointOfSalePaymentState {
        let cash: PointOfSaleCashPaymentState = paymentModel.paymentState.cash == .collectingCash
            ? .idle : paymentModel.paymentState.cash
        let scanToPay: PointOfSaleScanToPayState = paymentModel.paymentState.scanToPay.isShowingQRCode
            ? .idle : paymentModel.paymentState.scanToPay
        let markAsPaid: PointOfSaleMarkAsPaidState = paymentModel.paymentState.markAsPaid == .confirming
            || paymentModel.paymentState.markAsPaid == .processing
            ? .idle : paymentModel.paymentState.markAsPaid
        return PointOfSalePaymentState(card: paymentModel.paymentState.card,
                                       cash: cash,
                                       scanToPay: scanToPay,
                                       markAsPaid: markAsPaid)
    }

    private var shouldShowTotalsFields: Bool {
        viewHelper.shouldShowTotalsFields(for: displayPaymentState)
    }

    var body: some View {
        HStack {
            switch posModel.orderState {
            case .idle, .syncing, .loaded:
                VStack(alignment: .center) {
                    Spacer()

                    if isShowingPaymentView {
                        PaymentViewContent(
                            paymentState: displayPaymentState,
                            cardReaderViewLayout: cardReaderViewLayout,
                            isShowingTotalsFields: isShowingTotalsFields,
                            backgroundColor: backgroundColor,
                            orderState: posModel.orderState,
                            cardReaderConnectionStatus: paymentModel.cardReaderConnectionStatus,
                            cardPresentPaymentInlineMessage: paymentModel.cardPresentPaymentInlineMessage,
                            connectCardReaderAction: paymentModel.connectCardReader,
                            cancelReconnectionAction: posModel.cancelReconnection
                        )
                    }

                    if isShowingPaymentView && isShowingTotalsFields {
                        Spacer()
                    }

                    if isShowingTotalsFields {
                        TotalsFieldsContent(
                            orderState: posModel.orderState,
                            paymentState: displayPaymentState,
                            cart: posModel.cart,
                            totalsFieldAnimation: totalsFieldAnimation
                        )
                        .opacity(shouldShowTotalsFields ? 1 : 0)
                    }

                    Spacer()

                    SecondaryPaymentButtons(
                        orderState: posModel.orderState,
                        paymentState: displayPaymentState,
                        cardReaderConnectionStatus: paymentModel.cardReaderConnectionStatus,
                        isScanToPayEnabled: featureFlags.isFeatureFlagEnabled(.pointOfSaleScanToPay),
                        isMarkOrderAsPaidEnabled: featureFlags.isFeatureFlagEnabled(.pointOfSaleMarkOrderAsPaid),
                        isShowingOtherPaymentMethodsPopover: $isShowingOtherPaymentMethodsPopover,
                        startCashPaymentAction: { paymentModel.startCashPayment() },
                        startOtherPaymentMethodsAction: {
                            analytics.track(.pointOfSaleOtherPaymentMethodsTapped)
                            isShowingOtherPaymentMethodsPopover = true
                        },
                        startScanToPayAction: {
                            Task { @MainActor in
                                await paymentModel.startScanToPayPayment()
                            }
                        },
                        startMarkOrderAsPaidAction: {
                            paymentModel.startMarkAsPaidPayment()
                        }
                    )
                }
                .scrollVerticallyIfNeeded()
                .animation(.default, value: isShowingPaymentView)
            case .error(.other(let message), let handler):
                PointOfSaleOrderSyncErrorMessageView(message: message, retryHandler: handler)
                    .transition(.opacity)

            case .error(.invalidCoupon(let message), let handler):
                PointOfSaleOrderSyncCouponsErrorMessageView(message: message, retryHandler: handler)
                    .transition(.opacity)
            case .error(.missingProducts(let missingProducts), let handler):
                PointOfSaleOrderSyncMissingProductsErrorMessageView(missingProducts: missingProducts, retryHandler: handler)
                    .transition(.opacity)
            }
        }
        .background(backgroundColor)
        .animation(.default, value: posModel.orderState.isError)
        .onAppear {
            isShowingTotalsFields = shouldShowTotalsFields
        }
        .onChange(of: shouldShowTotalsFields) {
            hideTotalsFieldsWithDelay(shouldShowTotalsFields)
        }
    }

    private var backgroundColor: Color {
        viewHelper.paymentBackgroundColor(for: displayPaymentState)
    }
}

private extension TotalsView {
    private func hideTotalsFieldsWithDelay(_ isShowing: Bool) {
        guard !isShowing && paymentModel.paymentState.card == .processingPayment else {
            self.isShowingTotalsFields = isShowing
            return
        }

        withAnimation(.default.delay(Constants.totalsFieldsHideAnimationDelay)) {
            self.isShowingTotalsFields = false
        }
    }
}


private extension TotalsView {
    struct PaymentViewLayout {
        let topPadding: CGFloat?
        let bottomPadding: CGFloat?
        let sidePadding: CGFloat

        init(topPadding: CGFloat?, bottomPadding: CGFloat?, sidePadding: CGFloat = 8) {
            self.topPadding = topPadding
            self.bottomPadding = bottomPadding
            self.sidePadding = sidePadding
        }

        static let primary = PaymentViewLayout(
            topPadding: nil,
            bottomPadding: POSPadding.small
        )

        static let outlined = PaymentViewLayout(
            topPadding: POSPadding.xxLarge,
            bottomPadding: POSPadding.xxLarge
        )
    }

    private var isShowingPaymentView: Bool {
        guard posModel.orderState.isLoaded else {
            return false
        }

        switch paymentModel.cardReaderConnectionStatus {
        case .disconnected:
            return true
        case .connected, .disconnecting, .cancellingConnection, .reconnecting:
            switch displayPaymentState.activePaymentMethod {
            case .cash, .scanToPay, .markAsPaid:
                return true
            case .card:
                return paymentModel.cardPresentPaymentInlineMessage != nil ||
                       totalsViewHelper.shouldShowReconnectingMessage(readerConnectionStatus: paymentModel.cardReaderConnectionStatus,
                                                                      paymentState: displayPaymentState)
            }
        }
    }

    private var cardReaderViewLayout: PaymentViewLayout {
        guard isShowingPaymentView else {
            return .primary
        }

        switch displayPaymentState.activePaymentMethod {
        case .cash, .scanToPay, .markAsPaid:
            return PaymentViewLayout(topPadding: POSPadding.none,
                                     bottomPadding: POSPadding.none,
                                     sidePadding: POSPadding.none)
        case .card:
            switch displayPaymentState.card {
            case .validatingOrderError,
                    .paymentIntentCreationError:
                return .outlined
            case .paymentError:
                return PaymentViewLayout(topPadding: POSPadding.none,
                                         bottomPadding: POSPadding.none,
                                         sidePadding: POSPadding.none)
            case .cardPaymentSuccessful:
                return PaymentViewLayout(topPadding: POSPadding.none,
                                         bottomPadding: POSPadding.none,
                                         sidePadding: POSPadding.none)
            case .idle,
                    .acceptingCard,
                    .cardInserted,
                    .validatingOrder,
                    .preparingReader,
                    .processingPayment:
                if totalsViewHelper.shouldShowReconnectingMessage(readerConnectionStatus: paymentModel.cardReaderConnectionStatus,
                                                                paymentState: displayPaymentState) {
                    return .primary
                }
                if viewHelper.shouldShowDisconnectedMessage(readerConnectionStatus: paymentModel.cardReaderConnectionStatus,
                                                          paymentState: displayPaymentState) {
                    return .primary
                }
            }
        }

        return .primary
    }
}

extension TotalsView {
    fileprivate struct PaymentViewPaddingModifier: ViewModifier {
        @Environment(\.dynamicTypeSize) var dynamicTypeSize
        let layout: PaymentViewLayout

        func body(content: Content) -> some View {
            content.padding(
                [.leading, .trailing],
                dynamicTypeSize.isAccessibilitySize ? nil : layout.sidePadding
            )
            .padding(.bottom, dynamicTypeSize.isAccessibilitySize ? nil : layout.bottomPadding)
            .padding(.top, dynamicTypeSize.isAccessibilitySize ? nil : layout.topPadding)
        }
    }
}

fileprivate extension View {
    func paymentViewPadding(layout: TotalsView.PaymentViewLayout) -> some View {
        modifier(TotalsView.PaymentViewPaddingModifier(layout: layout))
    }
}

private extension TotalsView {
    enum Constants {
        static let pricesIdealWidth: CGFloat = 382
        static let buttonHorizontalPadding: CGFloat = POSPadding.medium
        static let cashButtonBottomPadding: CGFloat = POSPadding.medium

        static let totalsLineViewPadding: EdgeInsets = .init(
            top: POSPadding.medium,
            leading: POSPadding.large,
            bottom: POSPadding.medium,
            trailing: POSPadding.large
        )
        static let subtotalsVerticalSpacing: CGFloat = POSSpacing.medium
        static let totalVerticalSpacing: CGFloat = POSSpacing.medium
        static let totalsHorizontalSpacing: CGFloat = POSSpacing.large
        static let subtotalTitleFont: POSFontStyle = .posBodyLargeRegular()
        static let subtotalAmountFont: POSFontStyle = .posBodyLargeRegular()
        static let totalTitleFont: POSFontStyle = .posHeadingBold
        static let totalAmountFont: POSFontStyle = .posHeadingBold
        static let separatorColor = Color.posOutlineVariant

        static let shimmeringCornerRadius: CGFloat = POSCornerRadiusStyle.medium.value
        static let shimmeringWidth: CGFloat = 342
        static let subtotalsShimmeringHeight: CGFloat = 36
        static let totalShimmeringHeight: CGFloat = 46

        static let totalsFieldsHideAnimationDelay: CGFloat = 0.3
    }

    enum Localization {
        static let total = NSLocalizedString(
            "pos.totalsView.total",
            value: "Total",
            comment: "Title for total amount field")
        static let subtotal = NSLocalizedString(
            "pos.totalsView.subtotal",
            value: "Subtotal",
            comment: "Title for subtotal amount field")
        static let taxes = NSLocalizedString(
            "pos.totalsView.taxes",
            value: "Taxes",
            comment: "Title for taxes amount field")
        static let discountTotal = NSLocalizedString(
            "pos.totalsView.discountTotal2",
            value: "Discount total",
            comment: "Title for discount total amount field")
        static let cashPaymentButtonTitle = NSLocalizedString(
            "pos.totalsView.cash.button.title",
            value: "Cash payment",
            comment: "Title for the cash payment button title")
        static let otherPaymentMethodsButtonTitle = NSLocalizedString(
            "pos.totalsView.otherPaymentMethods.button.title",
            value: "Other payment methods",
            comment: "Title for the Other payment methods button in the Point of Sale checkout. " +
            "Tapping this button opens a sheet listing alternative payment methods like Scan to Pay " +
            "or Mark order as paid.")
    }
}

private struct TotalsFieldsContent: View {
    let orderState: PointOfSaleOrderState
    let paymentState: PointOfSalePaymentState
    let cart: Cart
    let totalsFieldAnimation: Namespace.ID
    private let paymentViewHelper = POSPaymentViewHelper()
    private let viewHelper = TotalsViewHelper()

    /// Used for synchronizing animations of shimmeringLine and textField
    static let matchedGeometryId: String = "pos_totals_view_matched_geometry_id"

    var body: some View {
        HStack(alignment: .center) {
            Spacer()
            switch orderState {
            case .idle, .syncing, .error:
                totalsFields(orderTotals: nil)
            case .loaded(let orderTotals):
                totalsFields(orderTotals: orderTotals)
            }
            Spacer()
        }
        .transition(.opacity)
        .animation(.default, value: orderState.isSyncing)
        .opacity(paymentViewHelper.shouldShowTotalsFields(for: paymentState) ? 1 : 0)
        .layoutPriority(1)
        .dynamicTypeSize(...DynamicTypeSize.accessibility1)
    }

    @ViewBuilder func totalsFields(orderTotals: PointOfSaleOrderTotals?) -> some View {
        let totalsLoading = orderTotals == nil
        VStack {
            SubtotalFieldView(
                title: TotalsView.Localization.subtotal,
                formattedPrice: orderTotals?.cartTotal,
                shimmeringActive: totalsLoading
            )
            Spacer().frame(height: TotalsView.Constants.subtotalsVerticalSpacing)

            if viewHelper.shouldShowTotalDiscountField(cart: cart, orderTotals: orderTotals) {
                SubtotalFieldView(
                    title: TotalsView.Localization.discountTotal,
                    formattedPrice: orderTotals?.discountTotal,
                    shimmeringActive: totalsLoading
                )
                Spacer().frame(height: TotalsView.Constants.subtotalsVerticalSpacing)
            }

            SubtotalFieldView(
                title: TotalsView.Localization.taxes,
                formattedPrice: orderTotals?.taxTotal,
                shimmeringActive: totalsLoading
            )
            Spacer().frame(height: TotalsView.Constants.totalVerticalSpacing)
            Divider()
                .overlay(TotalsView.Constants.separatorColor)
                .renderedIf(!totalsLoading)
            Spacer().frame(height: TotalsView.Constants.totalVerticalSpacing)
            TotalFieldView(
                formattedPrice: orderTotals?.orderTotal,
                shimmeringActive: totalsLoading
            )
        }
        .padding(TotalsView.Constants.totalsLineViewPadding)
        .frame(minWidth: TotalsView.Constants.pricesIdealWidth)
        .fixedSize(horizontal: true, vertical: false)
        .matchedGeometryEffect(id: Self.matchedGeometryId, in: totalsFieldAnimation)
    }
}

private struct SubtotalFieldView: View {
    let title: String
    let formattedPrice: String?
    let shimmeringActive: Bool
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    var body: some View {
        content
            .opacity(shimmeringActive ? 0.6 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: shimmeringActive)
    }

    @ViewBuilder
    private var content: some View {
        if shimmeringActive {
            ShimmeringLineView(
                width: horizontalSizeClass == .compact ? nil : TotalsView.Constants.shimmeringWidth,
                height: TotalsView.Constants.subtotalsShimmeringHeight
            )
        } else {
            HStack(alignment: .top, spacing: .zero) {
                Text(title)
                    .font(TotalsView.Constants.subtotalTitleFont)
                Spacer()
                Text(formattedPrice ?? "")
                    .font(TotalsView.Constants.subtotalAmountFont)
            }
            .accessibilityElement(children: .combine)
            .foregroundColor(Color.posOnSurface)
        }
    }
}

private struct TotalFieldView: View {
    let formattedPrice: String?
    let shimmeringActive: Bool
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    var body: some View {
        content
            .opacity(shimmeringActive ? 0.6 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: shimmeringActive)
    }

    @ViewBuilder
    private var content: some View {
        if shimmeringActive {
            ShimmeringLineView(
                width: horizontalSizeClass == .compact ? nil : TotalsView.Constants.shimmeringWidth,
                height: TotalsView.Constants.totalShimmeringHeight
            )
        } else {
            HStack(alignment: .top, spacing: .zero) {
                Text(TotalsView.Localization.total)
                    .font(TotalsView.Constants.totalTitleFont)
                    .fontWeight(.semibold)
                Spacer(minLength: TotalsView.Constants.totalsHorizontalSpacing)
                Text(formattedPrice ?? "")
                    .font(TotalsView.Constants.totalAmountFont)
            }
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isHeader)
            .accessibilityIdentifier("pos-total-field")
            .foregroundColor(Color.posOnSurface)
        }
    }
}

private struct ShimmeringLineView: View {
    /// When nil, the bar stretches to the available container width (used on phone, where the
    /// fixed iPad-tuned width would render asymmetrically inside a centered HStack).
    let width: CGFloat?
    let height: CGFloat

    var body: some View {
        if let width {
            Color.posOnSurfaceVariantLowest
                .frame(width: width, height: height)
                .fixedSize(horizontal: true, vertical: true)
                .shimmering(active: true)
                .cornerRadius(TotalsView.Constants.shimmeringCornerRadius)
        } else {
            Color.posOnSurfaceVariantLowest
                .frame(maxWidth: .infinity)
                .frame(height: height)
                .shimmering(active: true)
                .cornerRadius(TotalsView.Constants.shimmeringCornerRadius)
                .padding(.horizontal, POSPadding.medium)
        }
    }
}

private struct PaymentViewContent: View {
    let paymentState: PointOfSalePaymentState
    let cardReaderViewLayout: TotalsView.PaymentViewLayout
    let isShowingTotalsFields: Bool
    let backgroundColor: Color
    let orderState: PointOfSaleOrderState
    let cardReaderConnectionStatus: CardPresentPaymentReaderConnectionStatus
    let cardPresentPaymentInlineMessage: PointOfSaleCardPresentPaymentMessageType?
    let connectCardReaderAction: () -> Void
    let cancelReconnectionAction: () -> Void
    @Namespace private var paymentMessageNamespace

    private let viewHelper = POSPaymentViewHelper()

    var body: some View {
        paymentView
            .animation(.default, value: paymentState.card)
            .font(.title)
            .if(viewHelper.shouldApplyPadding(paymentState: paymentState)) {
                $0.paymentViewPadding(layout: cardReaderViewLayout)
            }
            .transition(.opacity)
            .accessibilityShowsLargeContentViewer()
            .background(backgroundColor.ignoresSafeArea(.all))
            .dynamicTypeSize(...DynamicTypeSize.accessibility1)
            .minimumScaleFactor(isShowingTotalsFields ? 0.5 : 1)
    }

    @ViewBuilder private var paymentView: some View {
        if paymentState.cash == .paymentSuccess, case .loaded(let total) = orderState {
            PointOfSaleCardPresentPaymentInLineMessage(
                messageType: .paymentSuccess(
                    viewModel: .init(formattedOrderTotal: total.orderTotal,
                                     paymentMethod: .cash)),
                animation: .init(namespace: paymentMessageNamespace))
        } else if case .paymentSuccess = paymentState.scanToPay,
                  case .loaded(let total) = orderState {
            PointOfSaleCardPresentPaymentInLineMessage(
                messageType: .paymentSuccess(
                    viewModel: .init(formattedOrderTotal: total.orderTotal,
                                     paymentMethod: .scanToPay)),
                animation: .init(namespace: paymentMessageNamespace))
        } else if paymentState.markAsPaid == .paymentSuccess, case .loaded(let total) = orderState {
            PointOfSaleCardPresentPaymentInLineMessage(
                messageType: .paymentSuccess(
                    viewModel: .init(formattedOrderTotal: total.orderTotal,
                                     paymentMethod: .markAsPaid)),
                animation: .init(namespace: paymentMessageNamespace))
        } else {
            POSCardPaymentContentView(
                cardReaderConnectionStatus: cardReaderConnectionStatus,
                paymentState: paymentState,
                cardPresentPaymentInlineMessage: cardPresentPaymentInlineMessage,
                connectCardReaderAction: connectCardReaderAction,
                cancelReconnectionAction: cancelReconnectionAction)
        }
    }
}

/// Bottom-of-totals action row with the always-on Cash payment button plus a feature-flagged
/// "Other payment methods" button rendered side-by-side. When neither secondary payment-method
/// flag is enabled, the layout collapses to the original single Cash button — the feature flags
/// gate the second button entirely so App Store builds see no regression vs trunk.
///
/// The Other-payment popover is hosted *here*, anchored to its own button, rather than at the
/// outer view level. SwiftUI's `.popover` requires an anchor view; pinning it to the trigger
/// gives the merchant a clear "the menu came from this button" relationship and dismisses on
/// outside tap without the modal-stack optics of the previous bottom-sheet implementation.
private struct SecondaryPaymentButtons: View {
    let orderState: PointOfSaleOrderState
    let paymentState: PointOfSalePaymentState
    let cardReaderConnectionStatus: CardPresentPaymentReaderConnectionStatus
    let isScanToPayEnabled: Bool
    let isMarkOrderAsPaidEnabled: Bool
    @Binding var isShowingOtherPaymentMethodsPopover: Bool
    let startCashPaymentAction: () -> Void
    let startOtherPaymentMethodsAction: () -> Void
    let startScanToPayAction: () -> Void
    let startMarkOrderAsPaidAction: () -> Void

    private let viewHelper = TotalsViewHelper()

    private var isAnySecondaryPaymentMethodEnabled: Bool {
        isScanToPayEnabled || isMarkOrderAsPaidEnabled
    }

    var body: some View {
        HStack(spacing: POSSpacing.small) {
            Button(action: {
                startCashPaymentAction()
            }, label: {
                Text(TotalsView.Localization.cashPaymentButtonTitle)
                    .font(POSFontStyle.posBodyLargeBold)
                    .frame(maxWidth: .infinity)
            })
            .layoutPriority(1)
            .dynamicTypeSize(...DynamicTypeSize.accessibility1)
            .buttonStyle(POSOutlinedButtonStyle(size: .normal))
            .accessibilityIdentifier("pos-cash-payment-button")

            Button(action: {
                startOtherPaymentMethodsAction()
            }, label: {
                Text(TotalsView.Localization.otherPaymentMethodsButtonTitle)
                    .font(POSFontStyle.posBodyLargeBold)
                    .frame(maxWidth: .infinity)
            })
            .layoutPriority(1)
            .dynamicTypeSize(...DynamicTypeSize.accessibility1)
            .buttonStyle(POSOutlinedButtonStyle(size: .normal))
            .accessibilityIdentifier("pos-other-payment-methods-button")
            .popover(isPresented: $isShowingOtherPaymentMethodsPopover,
                     attachmentAnchor: .point(.top),
                     arrowEdge: .bottom) {
                PointOfSaleSecondaryPaymentMethodsPopover(
                    isScanToPayAvailable: isScanToPayEnabled,
                    isMarkOrderAsPaidAvailable: isMarkOrderAsPaidEnabled,
                    onScanToPay: startScanToPayAction,
                    onMarkOrderAsPaid: startMarkOrderAsPaidAction
                )
            }
            .renderedIf(isAnySecondaryPaymentMethodEnabled)
        }
        .padding(.horizontal, TotalsView.Constants.buttonHorizontalPadding)
        .safeAreaPadding(.bottom, TotalsView.Constants.cashButtonBottomPadding)
        // Gate the whole row on the cash visibility envelope. Without this, when the cash
        // button is hidden (e.g. during card processing) the HStack still applies its
        // safeAreaPadding(.bottom), reserving space at the bottom of the totals view that
        // didn't exist before this row was introduced. Other-payment visibility shares the
        // same envelope, so this single check is enough.
        .renderedIf(viewHelper.shouldShowCollectCashPaymentButton(
            orderState: orderState,
            paymentState: paymentState,
            cardReaderConnectionStatus: cardReaderConnectionStatus
        ))
    }
}

#if DEBUG
#Preview("Card Reader Not Connected") {
    let model = POSPreviewHelpers.makePreviewAggregateModel(
        cardPresentPaymentService: CardPresentPaymentPreviewService(connectionStatus: .disconnected)
    )
    TotalsView()
        .environment(model)
        .environment(model.paymentModel)
}

#Preview("Card Reader Connected") {
    let model = POSPreviewHelpers.makePreviewAggregateModel(
        cardPresentPaymentService: CardPresentPaymentPreviewService(
            connectionStatus: .connected(CardPresentPaymentCardReader(name: "Reader", batteryLevel: 0.85))
        )
    )
    TotalsView()
        .environment(model)
        .environment(model.paymentModel)
}

#Preview("Validating Order") {
    let model = POSPreviewHelpers.makePreviewAggregateModel(
        cardPresentPaymentService: CardPresentPaymentPreviewService(
            connectionStatus: .connected(CardPresentPaymentCardReader(name: "Reader", batteryLevel: 0.85))
        )
    )
    Task { @MainActor in
        model.setPreviewState(
            paymentState: PointOfSalePaymentState(card: .validatingOrder, cash: .idle),
            inlineMessage: .validatingOrder(viewModel: PointOfSaleCardPresentPaymentValidatingOrderMessageViewModel())
        )
    }
    return TotalsView()
        .environment(model)
        .environment(model.paymentModel)
}

#Preview("Accepting Card") {
    let model = POSPreviewHelpers.makePreviewAggregateModel(
        cardPresentPaymentService: CardPresentPaymentPreviewService(
            connectionStatus: .connected(CardPresentPaymentCardReader(name: "Reader", batteryLevel: 0.85))
        )
    )
    Task { @MainActor in
        model.setPreviewState(
            paymentState: PointOfSalePaymentState(card: .acceptingCard, cash: .idle),
            inlineMessage: .tapSwipeOrInsertCard(viewModel: PointOfSaleCardPresentPaymentTapSwipeInsertCardMessageViewModel(inputMethods: []))
        )
    }
    return TotalsView()
        .environment(model)
        .environment(model.paymentModel)
}

#Preview("Processing Payment") {
    let model = POSPreviewHelpers.makePreviewAggregateModel(
        cardPresentPaymentService: CardPresentPaymentPreviewService(
            connectionStatus: .connected(CardPresentPaymentCardReader(name: "Reader", batteryLevel: 0.85))
        )
    )
    Task { @MainActor in
        model.setPreviewState(
            paymentState: PointOfSalePaymentState(card: .processingPayment, cash: .idle),
            inlineMessage: .processing(viewModel: PointOfSaleCardPresentPaymentProcessingMessageViewModel())
        )
    }
    return TotalsView()
        .environment(model)
        .environment(model.paymentModel)
}

#Preview("Card Payment Successful") {
    let model = POSPreviewHelpers.makePreviewAggregateModel(
        cardPresentPaymentService: CardPresentPaymentPreviewService(
            connectionStatus: .connected(CardPresentPaymentCardReader(name: "Reader", batteryLevel: 0.85))
        )
    )
    Task { @MainActor in
        model.setPreviewState(
            paymentState: PointOfSalePaymentState(card: .cardPaymentSuccessful, cash: .idle),
            inlineMessage: .paymentSuccess(viewModel: PointOfSalePaymentSuccessViewModel(formattedOrderTotal: "$12.00", paymentMethod: .card))
        )
    }
    return TotalsView()
        .environment(model)
        .environment(model.paymentModel)
}

#Preview("Display Reader Message") {
    let model = POSPreviewHelpers.makePreviewAggregateModel(
        cardPresentPaymentService: CardPresentPaymentPreviewService(
            connectionStatus: .connected(CardPresentPaymentCardReader(name: "Reader", batteryLevel: 0.85))
        )
    )
    Task { @MainActor in
        model.setPreviewState(
            paymentState: PointOfSalePaymentState(card: .processingPayment, cash: .idle),
            inlineMessage: .displayReaderMessage(viewModel: PointOfSaleCardPresentPaymentDisplayReaderMessageMessageViewModel(message: "Remove card"))
        )
    }
    return TotalsView()
        .environment(model)
        .environment(model.paymentModel)
}

#Preview("Payment Error") {
    let model = POSPreviewHelpers.makePreviewAggregateModel(
        cardPresentPaymentService: CardPresentPaymentPreviewService(
            connectionStatus: .connected(CardPresentPaymentCardReader(name: "Reader", batteryLevel: 0.85))
        )
    )
    Task { @MainActor in
        model.setPreviewState(
            paymentState: PointOfSalePaymentState(card: .paymentError, cash: .idle),
            inlineMessage: .paymentError(viewModel: PointOfSaleCardPresentPaymentErrorMessageViewModel(
                error: NSError(domain: "CardPaymentError", code: 1001, userInfo: [NSLocalizedDescriptionKey: "Card declined"]),
                tryPaymentAgainButtonAction: {},
                backToCheckoutButtonAction: {}
            ))
        )
    }
    return TotalsView()
        .environment(model)
        .environment(model.paymentModel)
}

#endif
