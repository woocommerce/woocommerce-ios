import SwiftUI
import WooFoundation

struct TotalsView: View {
    @Environment(PointOfSaleAggregateModel.self) private var posModel
    @Environment(POSPaymentModel.self) private var paymentModel
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
    private var shouldShowTotalsFields: Bool {
        viewHelper.shouldShowTotalsFields(for: paymentModel.paymentState)
    }

    var body: some View {
        HStack {
            switch posModel.orderState {
            case .idle, .syncing, .loaded:
                VStack(alignment: .center) {
                    Spacer()
                        .renderedIf(cardReaderViewLayout.topPadding == nil)

                    VStack(alignment: .center, spacing: 0) {
                        if isShowingPaymentView {
                            PaymentViewContent(
                                paymentState: paymentModel.paymentState,
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

                        if isShowingTotalsFields {
                            TotalsFieldsContent(
                                orderState: posModel.orderState,
                                paymentState: paymentModel.paymentState,
                                cart: posModel.cart,
                                totalsFieldAnimation: totalsFieldAnimation
                            )
                            .opacity(shouldShowTotalsFields ? 1 : 0)
                        }
                    }

                    Spacer()
                        .renderedIf(viewHelper.shouldApplyPadding(paymentState: paymentModel.paymentState))

                    CashPaymentButton(
                        orderState: posModel.orderState,
                        paymentState: paymentModel.paymentState,
                        cardReaderConnectionStatus: paymentModel.cardReaderConnectionStatus,
                        startCashPaymentAction: { await paymentModel.startCashPayment() }
                    )
                }
                .animation(.default, value: isShowingPaymentView)
                .scrollVerticallyIfNeeded()
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
        .animation(.default, value: paymentModel.paymentState)
        .animation(.default, value: posModel.orderState.isError)
        .onAppear {
            isShowingTotalsFields = shouldShowTotalsFields
        }
        .onChange(of: shouldShowTotalsFields) {
            hideTotalsFieldsWithDelay(shouldShowTotalsFields)
        }
        .geometryGroup()
    }

    private var backgroundColor: Color {
        viewHelper.paymentBackgroundColor(for: paymentModel.paymentState)
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
            // When the order's being created or synced, we only show the shimmering totals.
            // Before the order exists, we don't want to show the card payment status, as it will
            // show for a second initially, then disappear the moment we start syncing the order.
            return false
        }

        switch paymentModel.cardReaderConnectionStatus {
        case .connected, .disconnecting, .cancellingConnection:
            // Show card payment UI if there's a message, or cash payment UI when not idle
            switch paymentModel.paymentState.activePaymentMethod {
            case .cash:
                return true
            case .card:
                return paymentModel.cardPresentPaymentInlineMessage != nil
            }
        case .reconnecting:
            switch paymentModel.paymentState.activePaymentMethod {
            case .cash:
                return true
            case .card:
                return paymentModel.cardPresentPaymentInlineMessage != nil ||
                       totalsViewHelper.shouldShowReconnectingMessage(readerConnectionStatus: paymentModel.cardReaderConnectionStatus,
                                                                      paymentState: paymentModel.paymentState)
            }
        case .disconnected:
            // Since the reader is disconnected, this will show the "Connect your reader" CTA button view.
            return true
        }
    }

    private var cardReaderViewLayout: PaymentViewLayout {
        guard isShowingPaymentView else {
            return .primary
        }

        switch paymentModel.paymentState.activePaymentMethod {
        case .cash:
            return PaymentViewLayout(topPadding: POSPadding.none,
                                     bottomPadding: paymentModel.paymentState.cash == .collectingCash ? nil : POSPadding.none,
                                     sidePadding: POSPadding.none)
        case .card:
            switch paymentModel.paymentState.card {
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
                                                                paymentState: paymentModel.paymentState) {
                    return .primary
                }
                if viewHelper.shouldShowDisconnectedMessage(readerConnectionStatus: paymentModel.cardReaderConnectionStatus,
                                                          paymentState: paymentModel.paymentState) {
                    return .outlined
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

    var body: some View {
        content
            .opacity(shimmeringActive ? 0.6 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: shimmeringActive)
    }

    @ViewBuilder
    private var content: some View {
        if shimmeringActive {
            ShimmeringLineView(
                width: TotalsView.Constants.shimmeringWidth,
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

    var body: some View {
        content
            .opacity(shimmeringActive ? 0.6 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: shimmeringActive)
    }

    @ViewBuilder
    private var content: some View {
        if shimmeringActive {
            ShimmeringLineView(
                width: TotalsView.Constants.shimmeringWidth,
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
    let width: CGFloat
    let height: CGFloat

    var body: some View {
        Color.posOnSurfaceVariantLowest
            .frame(width: width, height: height)
            .fixedSize(horizontal: true, vertical: true)
            .shimmering(active: true)
            .cornerRadius(TotalsView.Constants.shimmeringCornerRadius)
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

    private let viewHelper = POSPaymentViewHelper()

    var body: some View {
        paymentView
            .font(.title)
            .if(viewHelper.shouldApplyPadding(paymentState: paymentState)) {
                $0.paymentViewPadding(layout: cardReaderViewLayout)
            }
            .transition(.opacity)
            .accessibilityShowsLargeContentViewer()
            .background(backgroundColor.ignoresSafeArea(.all))
            .dynamicTypeSize(...DynamicTypeSize.accessibility1)
            .minimumScaleFactor(isShowingTotalsFields ? 0.5 : 1)
            .geometryGroup()
    }

    @ViewBuilder private var paymentView: some View {
        switch paymentState.activePaymentMethod {
        case .cash:
            if case .loaded(let total) = orderState {
                POSCashPaymentContentView(
                    cashPaymentState: paymentState.cash,
                    formattedOrderTotal: total.orderTotal)
            }
        case .card:
            POSCardPaymentContentView(
                cardReaderConnectionStatus: cardReaderConnectionStatus,
                paymentState: paymentState,
                cardPresentPaymentInlineMessage: cardPresentPaymentInlineMessage,
                connectCardReaderAction: connectCardReaderAction,
                cancelReconnectionAction: cancelReconnectionAction)
        }
    }
}

private struct CashPaymentButton: View {
    let orderState: PointOfSaleOrderState
    let paymentState: PointOfSalePaymentState
    let cardReaderConnectionStatus: CardPresentPaymentReaderConnectionStatus
    let startCashPaymentAction: () async -> Void

    private let viewHelper = TotalsViewHelper()

    var body: some View {
        Button(action: {
            Task { @MainActor in
                await startCashPaymentAction()
            }
        }, label: {
            Text(TotalsView.Localization.cashPaymentButtonTitle)
                .font(POSFontStyle.posBodyLargeBold)
        })
        .layoutPriority(1)
        .dynamicTypeSize(...DynamicTypeSize.accessibility1)
        .buttonStyle(POSOutlinedButtonStyle(size: .normal))
        .accessibilityIdentifier("pos-cash-payment-button")
        .padding(.horizontal, TotalsView.Constants.buttonHorizontalPadding)
        .safeAreaPadding(.bottom, TotalsView.Constants.cashButtonBottomPadding)
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
