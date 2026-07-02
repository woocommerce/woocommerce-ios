import CocoaLumberjackSwift
import SwiftUI
import WooFoundation
import Experiments

struct TotalsView: View {
    @Environment(PointOfSaleAggregateModel.self) private var posModel
    @Environment(POSPaymentModel.self) private var paymentModel
    @Environment(\.posFeatureFlags) private var featureFlags
    @Environment(\.posAnalytics) private var analytics
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.posAccessSession) private var session
    private let viewHelper = POSPaymentViewHelper()
    private let totalsViewHelper = TotalsViewHelper()

    /// Used together with .matchedGeometryEffect to synchronize the animations of shimmeringLineView and text fields.
    /// This makes SwiftUI treat these views as a single entity in the context of animation.
    /// It allows for a simultaneous transition from the shimmering effect to the text fields,
    /// and movement from the center of the VStack to their respective positions.
    @Namespace private var totalsFieldAnimation

    // The source of truth for whether totals _are_ showing; separate from whether they
    // _should be_ showing, so that we can animate the change.
    // Default true so totals fields would be included in the view hiearchy on first render and animate with TotalsView
    @State private var isShowingTotalsFields: Bool = true
    @State private var isShowingOtherPaymentMethodsSheet: Bool = false
    /// True between the merchant tapping a hero / bottom-strip button and the
    /// payment state machine actually leaving idle. Disables the hero CTA and
    /// the bottom-strip buttons during that brief async window so a quick
    /// double-tap can't kick off two payment flows.
    @State private var isStartingPayment: Bool = false

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

                    if shouldPrioritizePaymentViewOverHero {
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
                    } else if useTapToPayHeroLayout {
                        POSTapToPayHeroView(onPayTapped: handleTapToPayTapped,
                                            isPayDisabled: isStartingPayment)
                    } else if isShowingPaymentView {
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

                    if (useTapToPayHeroLayout || isShowingPaymentView) && isShowingTotalsFields {
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

                    switch bottomControlState {
                    case .readerAndOtherMethods:
                        readerAndOtherMethodsBottomStrip
                    case .cashAndOtherMethods:
                        cashAndOtherMethodsBottomStrip
                    case .checkoutMethods(let methods):
                        POSCheckoutPaymentButtonsRow(
                            methods: methods,
                            onSelect: handlePaymentMethodSelection
                        )
                    case .hidden:
                        EmptyView()
                    }
                }
                .scrollVerticallyIfNeeded()
                .animation(.default, value: isShowingPaymentView)
                .animation(.default, value: useTapToPayHeroLayout)
                .animation(.default, value: bottomControlState)
            case .error(.other(let message), let handler):
                PointOfSaleOrderSyncErrorMessageView(message: message, retryHandler: handler)
                    .transition(.opacity)

            case .error(.orderDoesNotMatchCart, _):
                PointOfSaleOrderSyncErrorMessageView(
                    title: Localization.orderMismatchTitle,
                    message: Localization.orderMismatchMessage,
                    actionTitle: Localization.orderMismatchActionTitle,
                    action: posModel.addMoreToCart
                )
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
        .onChange(of: paymentModel.paymentState.card) {
            // Any card state change means the payment state machine has reacted
            // to the merchant's tap (preparingReader, error, idle after cancel,
            // etc.). Release the double-tap gate so the buttons become
            // tappable again whenever the layout decides to show them.
            isStartingPayment = false
        }
        .onChange(of: paymentModel.paymentState.cash) {
            isStartingPayment = false
        }
        .onChange(of: paymentModel.paymentState.scanToPay) {
            // Scan to Pay transitions out of `.idle` when the QR flow starts —
            // release the gate so the merchant can interact with the next state.
            isStartingPayment = false
        }
        .onChange(of: paymentModel.paymentState.markAsPaid) {
            // Mark as Paid transitions out of `.idle` when the confirmation push
            // happens — release the gate so the merchant can interact with the
            // next state.
            isStartingPayment = false
        }
        .onChange(of: paymentModel.isPaymentSessionActive) { _, isActive in
            // The card-state onChange above doesn't always fire when a flow
            // wraps up — TTP filters intermediate states (idle → idle on
            // cancel is a no-op). When the gate closes after a TTP
            // cancel-on-reader, this signals "session ended" — release the
            // double-tap lock so the merchant can tap the hero CTA again.
            if !isActive {
                isStartingPayment = false
            }
        }
        .onChange(of: paymentModel.cardPresentPaymentAlertViewModel == nil) { _, becameNil in
            // BT scan cancel doesn't trigger any of the signals above:
            // `currentPaymentMethod` stays `.bluetooth` (we deliberately stopped
            // auto-clearing on `.idle` to avoid racing the reader-reconnection
            // observer), and `paymentState.card` was never non-idle to begin
            // with. The reliable signal there is the scan alert dismissing —
            // when the alert goes from non-nil to nil while card is idle the
            // merchant has stepped out of a connect flow that never reached
            // collect.
            if becameNil && paymentModel.paymentState.card == .idle {
                isStartingPayment = false
            }
        }
        // Phone-only: on iPad the picker is an anchored popover hosted on the
        // "Other payment methods" button (see `otherPaymentMethodsButton`).
        .posSheet(isPresented: isShowingOtherPaymentMethodsBottomSheet) {
            POSOtherPaymentMethodsSheet(
                isTapToPayAvailable: isTapToPayRowAvailableInOtherMethodsSheet,
                isTapToPayEnabled: isTapToPayRowEnabledInOtherMethodsSheet,
                onTapToPay: {
                    guard !isStartingPayment else { return }
                    isStartingPayment = true
                    Task { @MainActor in
                        await paymentModel.startCardPayment(with: .tapToPay)
                    }
                },
                isCardReaderEnabled: isCardReaderRowEnabledInOtherMethodsSheet,
                onCardReader: {
                    guard !isStartingPayment else { return }
                    isStartingPayment = true
                    Task { @MainActor in
                        await paymentModel.startCardPayment(with: .bluetoothReader)
                    }
                },
                isScanToPayAvailable: featureFlags.isFeatureFlagEnabled(.pointOfSaleScanToPay),
                onScanToPay: handleScanToPaySelected,
                isMarkOrderAsPaidAvailable: featureFlags.isFeatureFlagEnabled(.pointOfSaleMarkOrderAsPaid),
                onMarkOrderAsPaid: handleMarkAsPaidSelected
            )
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
        .onChange(of: session.isLocked) { _, isLocked in
            // POSSheet presents at the UIWindow level, so it sits above the view-level
            // lock overlay. Dismiss on lock so the PIN screen isn't obscured.
            guard isLocked else { return }
            isShowingOtherPaymentMethodsSheet = false
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
                    // On phone, drop the sidePadding (POSPadding.small) so the connect-reader
                    // button can anchor to the same POSPadding.medium screen-edge insets as
                    // the cash button below (which uses .padding(.horizontal, POSPadding.medium)
                    // directly off the screen).
                    return horizontalSizeClass == .compact
                        ? PaymentViewLayout(topPadding: nil, bottomPadding: POSPadding.small, sidePadding: POSPadding.none)
                        : .primary
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
        static let customAmountsTotal = NSLocalizedString(
            "pos.totalsView.customAmountsTotal",
            value: "Custom amounts",
            comment: "Title for the custom amounts total amount field in the Point of Sale totals breakdown")
        static let cardReaderButtonTitle = NSLocalizedString(
            "pos.totalsView.cardReader.button.title",
            value: "Card reader",
            comment: "Title for the card reader button on the Point of Sale checkout. "
                + "Tapping it starts the connect-reader flow when no reader is connected.")
        static let cashPaymentButtonTitle = NSLocalizedString(
            "pos.totalsView.cash.button.title",
            value: "Cash payment",
            comment: "Title for the cash payment button title")
        static let otherPaymentMethodsButtonTitle = NSLocalizedString(
            "pos.totalsView.otherPaymentMethods.button.title",
            value: "Other payment methods",
            comment: "Title for the Other payment methods button shown alongside the Tap to Pay hero on phone POS checkout. "
                + "Tapping it opens a sheet with non-TTP options (currently Card reader).")
        static let orderMismatchTitle = NSLocalizedString(
            "pos.totalsView.orderMismatch.error.title",
            value: "Couldn't check out",
            comment: "Title shown when the POS order created by the server does not match the cart contents.")
        static let orderMismatchMessage = NSLocalizedString(
            "pos.totalsView.orderMismatch.error.message",
            value: "There was a problem creating this order, the items don't match your selection. Check the cart contents and try again.",
            comment: "Message shown when the POS order created by the server does not match the cart contents.")
        static let orderMismatchActionTitle = NSLocalizedString(
            "pos.totalsView.orderMismatch.error.editOrder",
            value: "Edit order",
            comment: "Button to return to item selection when the POS order created by the server does not match the cart contents.")
    }
}

private struct TotalsFieldsContent: View {
    let orderState: PointOfSaleOrderState
    let paymentState: PointOfSalePaymentState
    let cart: Cart
    let totalsFieldAnimation: Namespace.ID
    private let paymentViewHelper = POSPaymentViewHelper()
    private let viewHelper = TotalsViewHelper()
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

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

            if viewHelper.shouldShowCustomAmountsField(cart: cart, orderTotals: orderTotals) {
                SubtotalFieldView(
                    title: TotalsView.Localization.customAmountsTotal,
                    formattedPrice: orderTotals?.customAmountsTotal,
                    shimmeringActive: totalsLoading
                )
                Spacer().frame(height: TotalsView.Constants.subtotalsVerticalSpacing)
            }

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
        .if(horizontalSizeClass == .compact) {
            $0.frame(maxWidth: .infinity)
        }
        .if(horizontalSizeClass != .compact) {
            $0
                .frame(minWidth: TotalsView.Constants.pricesIdealWidth)
                .fixedSize(horizontal: true, vertical: false)
        }
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

private extension TotalsView {
    func handlePaymentMethodSelection(_ method: POSCheckoutPaymentMethod) {
        switch method {
        case .tapToPay:
            handleTapToPayTapped()
        case .cardReader:
            guard paymentModel.isCompactCardPaymentSelectionEnabled else {
                paymentModel.connectCardReader()
                return
            }
            guard !isStartingPayment else { return }
            isStartingPayment = true
            Task { @MainActor in
                await paymentModel.startCardPayment(with: .bluetoothReader)
            }
        case .cashPayment:
            paymentModel.startCashPayment()
        }
    }

    /// True when the card payment has reached a state that should take over
    /// the hero immediately: a terminal state (success / error), or the
    /// `.processingPayment` window between Apple's TTP modal closing and the
    /// success card rendering. The default hero → PaymentViewContent priority
    /// order is fine for every other transition; this short-circuits those
    /// specific cases so the merchant sees the inline "Processing payment" /
    /// success / error UI immediately rather than the hero fading out + the
    /// Checkout chrome ghosting through.
    private var shouldPrioritizePaymentViewOverHero: Bool {
        switch displayPaymentState.card {
        case .processingPayment,
                .cardPaymentSuccessful,
                .paymentError,
                .validatingOrderError,
                .paymentIntentCreationError:
            return true
        case .idle,
                .acceptingCard,
                .cardInserted,
                .validatingOrder,
                .preparingReader:
            return false
        }
    }

    /// Shows the Tap to Pay hero when Tap to Pay is available and no payment is in progress.
    var useTapToPayHeroLayout: Bool {
        guard posModel.tapToPayAvailabilityController?.state.isAvailable == true else { return false }
        if paymentModel.isCompactCardPaymentSelectionEnabled {
            guard paymentModel.selectedCardPaymentRail == .tapToPay else { return false }
        }
        // Keep method-specific success UI visible instead of returning to the hero.
        guard displayPaymentState.card == .idle && displayPaymentState.cash == .idle else { return false }
        guard displayPaymentState.scanToPay == .idle && displayPaymentState.markAsPaid == .idle else { return false }
        guard case .loaded(let totals) = posModel.orderState else { return false }
        guard !totals.orderTotalDecimal.isZero else { return false }
        // Hide the hero only while Bluetooth is the active connected path.
        if case .connected = paymentModel.cardReaderConnectionStatus,
           paymentModel.currentPaymentMethod == .bluetooth || paymentModel.lastConnectedMethod == .bluetooth {
            return false
        }
        return true
    }

    /// Cash + Other payment methods buttons shown below the totals for the Tap to Pay hero
    /// and active Bluetooth reader layouts.
    @ViewBuilder
    var cashAndOtherMethodsBottomStrip: some View {
        VStack(spacing: POSSpacing.medium) {
            Button(action: handleCashPaymentTapped) {
                Text(Localization.cashPaymentButtonTitle)
                    .font(POSFontStyle.posBodyLargeBold)
            }
            .buttonStyle(POSOutlinedButtonStyle(size: .normal))
            .disabled(isStartingPayment)
            .accessibilityIdentifier("pos-cash-payment-button")

            otherPaymentMethodsButton
        }
        .if(horizontalSizeClass == .compact) {
            $0.posPhoneBottomButtonPadding()
        }
        .if(horizontalSizeClass != .compact) {
            $0
                .padding(.horizontal, POSPadding.medium)
                .padding(.bottom, POSPadding.xxLarge)
        }
    }

    /// "Reader not connected" layout for devices where Tap to Pay is unavailable
    /// (e.g. iPad). The reader connect button is the primary (filled) CTA on its
    /// own row, with Cash and "Other payment methods" sharing the row below.
    /// Without a TTP hero the reader is the main card path, so it stays a
    /// first-class button rather than being demoted into the sheet.
    @ViewBuilder
    var readerAndOtherMethodsBottomStrip: some View {
        VStack(spacing: POSSpacing.medium) {
            Button {
                handlePaymentMethodSelection(.cardReader)
            } label: {
                Text(Localization.cardReaderButtonTitle)
                    .font(POSFontStyle.posBodyLargeBold)
            }
            .buttonStyle(POSFilledButtonStyle(size: .normal))
            .disabled(isStartingPayment)
            .accessibilityIdentifier("pos-card-reader-button")

            Button(action: handleCashPaymentTapped) {
                Text(Localization.cashPaymentButtonTitle)
                    .font(POSFontStyle.posBodyLargeBold)
            }
            .buttonStyle(POSOutlinedButtonStyle(size: .normal))
            .disabled(isStartingPayment)
            .accessibilityIdentifier("pos-cash-payment-button")

            otherPaymentMethodsButton
        }
        .if(horizontalSizeClass == .compact) {
            $0.posPhoneBottomButtonPadding()
        }
        .if(horizontalSizeClass != .compact) {
            $0
                .padding(.horizontal, POSPadding.medium)
                .padding(.bottom, POSPadding.xxLarge)
        }
    }

    var bottomControlState: TotalsViewHelper.BottomControlState {
        totalsViewHelper.bottomControlState(
            orderState: posModel.orderState,
            paymentState: displayPaymentState,
            cardReaderConnectionStatus: paymentModel.cardReaderConnectionStatus,
            tapToPayAvailabilityState: posModel.tapToPayAvailabilityController?.state,
            hasOtherPaymentMethodsAvailable: hasOtherPaymentMethodsAvailable,
            isTapToPayHeroVisible: useTapToPayHeroLayout,
            isBluetoothReaderSelected: paymentModel.isBluetoothReaderSelected
        )
    }

    /// True when at least one "Other payment methods" sheet entry — Scan to Pay
    /// or Mark as Paid — is enabled. Drives whether the bottom strip (and its
    /// "Other payment methods" button) replaces `POSCheckoutPaymentButtonsRow`
    /// when Tap to Pay isn't the primary CTA, e.g. on iPad.
    var hasOtherPaymentMethodsAvailable: Bool {
        featureFlags.isFeatureFlagEnabled(.pointOfSaleScanToPay) ||
        featureFlags.isFeatureFlagEnabled(.pointOfSaleMarkOrderAsPaid)
    }

    var isTapToPayRowAvailableInOtherMethodsSheet: Bool {
        posModel.tapToPayAvailabilityController?.state.isAvailable == true
    }

    var isTapToPayRowEnabledInOtherMethodsSheet: Bool {
        guard paymentModel.isCompactCardPaymentSelectionEnabled else { return true }
        return paymentModel.selectedCardPaymentRail != .tapToPay
    }

    /// Card reader is disabled only while Bluetooth is the active payment method.
    /// `cardReaderConnectionStatus` is not enough because Tap to Pay pre-connects can also report `.connected`.
    var isCardReaderRowEnabledInOtherMethodsSheet: Bool {
        paymentModel.currentPaymentMethod != .bluetooth
    }

    func handleTapToPayTapped() {
        guard !isStartingPayment else { return }
        isStartingPayment = true
        Task { @MainActor in
            await paymentModel.startCardPayment(with: .tapToPay)
        }
    }

    func handleCashPaymentTapped() {
        guard !isStartingPayment else { return }
        isStartingPayment = true
        paymentModel.startCashPayment()
    }

    func handleOtherPaymentMethodsTapped() {
        isShowingOtherPaymentMethodsSheet = true
    }

    func handleScanToPaySelected() {
        // Same double-tap guard the bottom sheet uses: a quick double-tap in the
        // window between the merchant tapping Scan to Pay and `paymentState.scanToPay`
        // leaving `.idle` could otherwise fire `startScanToPayPayment()` twice.
        guard !isStartingPayment else { return }
        isStartingPayment = true
        Task { @MainActor in
            await paymentModel.startScanToPayPayment()
        }
    }

    func handleMarkAsPaidSelected() {
        // Mark as Paid dispatches into a navigation push the merchant could otherwise
        // re-trigger by tapping the row a second time during the same render frame.
        guard !isStartingPayment else { return }
        isStartingPayment = true
        paymentModel.startMarkAsPaidPayment()
    }

    /// The "Other payment methods" outlined button shared by both bottom strips.
    ///
    /// On iPad the picker is a popover anchored to this button (native, with an
    /// arrow pointing at it); on phone the body-level `posSheet` hosts the bottom
    /// sheet instead. The two presentations are split by size class via
    /// `isShowingOtherPaymentMethodsPopover` / `isShowingOtherPaymentMethodsBottomSheet`
    /// so only one fires. The popover only ever lists Scan to Pay / Mark as Paid —
    /// on iPad the Card reader is a first-class strip button, never an "other" method.
    @ViewBuilder
    var otherPaymentMethodsButton: some View {
        Button(action: handleOtherPaymentMethodsTapped) {
            Text(Localization.otherPaymentMethodsButtonTitle)
                .font(POSFontStyle.posBodyLargeBold)
        }
        .buttonStyle(POSOutlinedButtonStyle(size: .normal))
        .frame(maxWidth: .infinity)
        .disabled(isStartingPayment)
        .accessibilityIdentifier("pos-other-payment-methods-button")
        .popover(isPresented: isShowingOtherPaymentMethodsPopover,
                 attachmentAnchor: .point(.top),
                 arrowEdge: .bottom) {
            PointOfSaleSecondaryPaymentMethodsPopover(
                isScanToPayAvailable: featureFlags.isFeatureFlagEnabled(.pointOfSaleScanToPay),
                isMarkOrderAsPaidAvailable: featureFlags.isFeatureFlagEnabled(.pointOfSaleMarkOrderAsPaid),
                onScanToPay: handleScanToPaySelected,
                onMarkOrderAsPaid: handleMarkAsPaidSelected
            )
        }
    }

    /// iPad presentation of the Other payment methods picker — an anchored popover.
    /// Derived from the shared trigger so it only fires in regular width.
    var isShowingOtherPaymentMethodsPopover: Binding<Bool> {
        Binding(get: { isShowingOtherPaymentMethodsSheet && horizontalSizeClass != .compact },
                set: { isShowingOtherPaymentMethodsSheet = $0 })
    }

    /// Phone presentation of the Other payment methods picker — the bottom sheet.
    /// Derived from the shared trigger so it only fires in compact width.
    var isShowingOtherPaymentMethodsBottomSheet: Binding<Bool> {
        Binding(get: { isShowingOtherPaymentMethodsSheet && horizontalSizeClass == .compact },
                set: { isShowingOtherPaymentMethodsSheet = $0 })
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
