import CocoaLumberjackSwift
import SwiftUI
import WooFoundation

struct TotalsView: View {
    @Environment(PointOfSaleAggregateModel.self) private var posModel
    @Environment(POSPaymentModel.self) private var paymentModel
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
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

    /// Payment state with cash collection neutralized. Only `.collectingCash` is handled
    /// by NavigationStack push. Success and idle are visible to TotalsView.
    /// TODO: Consider removing cash state entirely - it no longer drives the cash view.
    private var displayPaymentState: PointOfSalePaymentState {
        let cash: PointOfSaleCashPaymentState = paymentModel.paymentState.cash == .collectingCash ? .idle : paymentModel.paymentState.cash
        return PointOfSalePaymentState(card: paymentModel.paymentState.card, cash: cash)
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

                    if useTapToPayHeroLayout {
                        POSTapToPayHeroView(onPayTapped: handleTapToPayTapped,
                                            isPayDisabled: isStartingPayment,
                                            isPreparing: paymentModel.isPreparingTapToPay)
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

                    if useTapToPayHeroLayout {
                        tapToPayBottomStrip
                    } else if !checkoutPaymentMethods.isEmpty {
                        POSCheckoutPaymentButtonsRow(
                            methods: checkoutPaymentMethods,
                            onSelect: handlePaymentMethodSelection
                        )
                    }
                }
                .scrollVerticallyIfNeeded()
                .animation(.default, value: isShowingPaymentView)
                .animation(.default, value: useTapToPayHeroLayout)
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
        .onChange(of: paymentModel.isTapToPaySessionActive) { _, isActive in
            // TTP path filters intermediate card states, so the card-state
            // onChange above never fires on cancel (idle → idle). When the
            // gate closes after a cancel-on-reader, this signals "session
            // ended" — release the double-tap lock so the merchant can tap
            // the hero CTA again.
            if !isActive {
                isStartingPayment = false
            }
        }
        .posSheet(isPresented: $isShowingOtherPaymentMethodsSheet) {
            POSOtherPaymentMethodsSheet(onCardReader: {
                guard !isStartingPayment else { return }
                isStartingPayment = true
                Task { @MainActor in
                    await paymentModel.startPaymentWithMethod(.bluetooth)
                }
            })
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
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
            case .cash:
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
        case .cash:
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
                    // On phone, drop the 8pt sidePadding so the connect-reader button can
                    // anchor to the same 16pt screen-edge insets as the cash button below
                    // (which uses .padding(.horizontal, 16) directly off the screen).
                    return horizontalSizeClass == .compact
                        ? PaymentViewLayout(topPadding: nil, bottomPadding: POSPadding.small, sidePadding: 0)
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
        static let separatorColor: Color = Color.posOutlineVariant

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
            comment: "Title for the Other payment methods button shown alongside the Tap to Pay hero on phone POS checkout. "
                + "Tapping it opens a sheet with non-TTP options (currently Card reader).")
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
    /// Builds the ordered list of payment methods rendered in the bottom buttons row.
    ///
    /// When the cash button visibility checks fail (syncing, reconnecting, zero total)
    /// the row is hidden entirely. Otherwise the row is composed from:
    ///
    /// - `.tapToPay` — prepended when the availability controller has resolved
    ///   `.available` (device + site eligibility passed and the feature flag is on).
    ///   First slot, so it renders as the primary (filled) button on phone.
    /// - `.cardReader` — included when no reader is connected. Tapping it starts the
    ///   connect flow the in-pane "Connect your reader" CTA used to drive.
    /// - `.cashPayment` — always last, always present when the row is visible.
    ///
    /// `.tapToPay`'s action is intentionally a no-op at this stage — wiring it to
    /// the actual collection flow happens in a later, focused commit.
    var checkoutPaymentMethods: [POSCheckoutPaymentMethod] {
        guard totalsViewHelper.shouldShowCollectCashPaymentButton(
            orderState: posModel.orderState,
            paymentState: displayPaymentState,
            cardReaderConnectionStatus: paymentModel.cardReaderConnectionStatus
        ) else {
            return []
        }
        let viewHelper = POSPaymentViewHelper()
        let isReaderDisconnected = viewHelper.shouldShowDisconnectedMessage(
            readerConnectionStatus: paymentModel.cardReaderConnectionStatus,
            paymentState: displayPaymentState
        )
        let isTapToPayAvailable = posModel.tapToPayAvailabilityController?.state.isAvailable == true

        var methods: [POSCheckoutPaymentMethod] = []
        if isTapToPayAvailable {
            methods.append(.tapToPay)
        }
        if isReaderDisconnected {
            methods.append(.cardReader)
        }
        methods.append(.cashPayment)
        return methods
    }

    func handlePaymentMethodSelection(_ method: POSCheckoutPaymentMethod) {
        switch method {
        case .tapToPay:
            handleTapToPayTapped()
        case .cardReader:
            paymentModel.connectCardReader()
        case .cashPayment:
            paymentModel.startCashPayment()
        }
    }

    /// True when the merchant should see the Android-style Tap to Pay hero +
    /// bottom-strip layout: TTP availability has resolved `.available`, no
    /// payment is currently in progress (idle card + idle cash), and the order
    /// has a real non-zero total to charge. When a TTP payment kicks off,
    /// `paymentState.card` transitions out of `.idle` and the existing
    /// `PaymentViewContent` flow takes over (preparing / accepting /
    /// processing / success / error).
    var useTapToPayHeroLayout: Bool {
        guard posModel.tapToPayAvailabilityController?.state.isAvailable == true else { return false }
        guard displayPaymentState.card == .idle && displayPaymentState.cash == .idle else { return false }
        // Empty-cart / syncing / reconnecting guards computed directly. We
        // can't reuse `shouldShowCollectCashPaymentButton` here — that helper
        // also requires the reader to be disconnected when card state is idle
        // (an iPad pay-row assumption). On TTP the device is silently
        // pre-connected, so reusing it would collapse the hero whenever the
        // pre-connect succeeds.
        guard case .loaded(let totals) = posModel.orderState else { return false }
        guard !totals.orderTotalDecimal.isZero else { return false }
        if case .reconnecting = paymentModel.cardReaderConnectionStatus { return false }
        return true
    }

    /// Cash + Other payment methods stacked outlined buttons rendered below the
    /// totals when the Tap to Pay hero is showing. Mirrors the Android phone POS
    /// "Cash + Other payment methods" row from samiuelson #15825.
    @ViewBuilder
    var tapToPayBottomStrip: some View {
        VStack(spacing: POSSpacing.medium) {
            Button(action: handleCashPaymentTapped) {
                Text(Localization.cashPaymentButtonTitle)
                    .font(POSFontStyle.posBodyLargeBold)
            }
            .buttonStyle(POSOutlinedButtonStyle(size: .normal))
            .disabled(isStartingPayment)
            .accessibilityIdentifier("pos-cash-payment-button")

            Button(action: handleOtherPaymentMethodsTapped) {
                Text(Localization.otherPaymentMethodsButtonTitle)
                    .font(POSFontStyle.posBodyLargeBold)
            }
            .buttonStyle(POSOutlinedButtonStyle(size: .normal))
            .disabled(isStartingPayment)
            .accessibilityIdentifier("pos-other-payment-methods-button")
        }
        .padding(.horizontal, POSPadding.medium)
        .padding(.bottom, POSPadding.xxLarge)
    }

    func handleTapToPayTapped() {
        guard !isStartingPayment else { return }
        isStartingPayment = true
        Task { @MainActor in
            await paymentModel.startPaymentWithMethod(.tapToPay)
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
