import SwiftUI

@available(iOS 17.0, *)
struct TotalsView: View {
    @Environment(PointOfSaleAggregateModel.self) private var posModel
    private let viewHelper = TotalsViewHelper()

    /// Used together with .matchedGeometryEffect to synchronize the animations of shimmeringLineView and text fields.
    /// This makes SwiftUI treat these views as a single entity in the context of animation.
    /// It allows for a simultaneous transition from the shimmering effect to the text fields,
    /// and movement from the center of the VStack to their respective positions.
    @Namespace private var totalsFieldAnimation

    // The source of truth for whether totals _are_ showing; separate from whether they
    // _should be_ showing, so that we can animate the change.
    @State private var isShowingTotalsFields: Bool = false
    private var shouldShowTotalsFields: Bool {
        viewHelper.shouldShowTotalsFields(for: posModel.paymentState)
    }

    @Environment(\.dynamicTypeSize) var dynamicTypeSize

    var body: some View {
        HStack {
            switch posModel.orderState {
            case .idle, .syncing, .loaded:
                VStack(alignment: .center) {
                    Spacer()
                        .renderedIf(cardReaderViewLayout.topPadding == nil)

                    VStack(alignment: .center, spacing: 0) {
                        if isShowingPaymentView {
                            paymentView
                                .font(.title)
                                .if(viewHelper.shouldApplyPadding(paymentState: posModel.paymentState)) {
                                    $0.paymentViewPadding(layout: cardReaderViewLayout)
                                }
                                .transition(.opacity)
                                .accessibilityShowsLargeContentViewer()
                                .background(backgroundColor.ignoresSafeArea(.all))
                                .dynamicTypeSize(...DynamicTypeSize.accessibility2)
                                .minimumScaleFactor(isShowingTotalsFields ? 0.5 : 1)
                                .geometryGroup()
                        }

                        if isShowingTotalsFields {
                            totalsFieldsView
                                .transition(.opacity)
                                .animation(.default, value: posModel.orderState.isSyncing)
                                .opacity(viewHelper.shouldShowTotalsFields(for: posModel.paymentState) ? 1 : 0)
                                .layoutPriority(1)
                                .dynamicTypeSize(...DynamicTypeSize.accessibility2)
                        }
                    }
                    .animation(.default, value: posModel.cardPresentPaymentInlineMessage)

                    Spacer()
                        .renderedIf(viewHelper.shouldApplyPadding(paymentState: posModel.paymentState))

                    Button(action: {
                        Task { @MainActor in
                            await posModel.startCashPayment()
                        }
                    }, label: {
                        Text(Localization.cashPaymentButtonTitle)
                            .font(POSFontStyle.posBodyLargeBold)
                    })
                    .layoutPriority(1)
                    .dynamicTypeSize(...DynamicTypeSize.accessibility2)
                    .buttonStyle(POSOutlinedButtonStyle(size: .normal))
                    .padding(.horizontal, Constants.buttonHorizontalPadding)
                    .safeAreaPadding(.bottom, Constants.cashButtonBottomPadding)
                    .renderedIf(viewHelper.shouldShowCollectCashPaymentButton(orderState: posModel.orderState,
                                                                              paymentState: posModel.paymentState,
                                                                              cardReaderConnectionStatus: posModel.cardReaderConnectionStatus))
                }
                .animation(.default, value: isShowingPaymentView)
            case .error(.other(let message), let handler):
                PointOfSaleOrderSyncErrorMessageView(message: message, retryHandler: handler)
                    .transition(.opacity)
            case .error(.invalidCoupon(let message), let handler):
                PointOfSaleOrderSyncCouponsErrorMessageView(message: message, retryHandler: handler)
                    .transition(.opacity)
            }
        }
        .background(backgroundColor)
        .animation(.default, value: posModel.paymentState)
        .animation(.default, value: posModel.orderState.isError)
        .onAppear {
            isShowingTotalsFields = shouldShowTotalsFields
        }
        .onChange(of: shouldShowTotalsFields, perform: hideTotalsFieldsWithDelay)
        .geometryGroup()
    }

    private var backgroundColor: Color {
        switch posModel.paymentState {
        case .card(.processingPayment):
            .posPrimary
        case .cash(.collectingCash):
            .posSurfaceBright
        default:
            .clear
        }
    }
}

@available(iOS 17.0, *)
private extension TotalsView {
    var totalsFieldsView: some View {
        HStack(alignment: .center) {
            Spacer()
            switch posModel.orderState {
            case .idle,
                    .syncing,
                    .error:
                totalsFields(orderTotals: nil)
            case .loaded(let orderTotals):
                totalsFields(orderTotals: orderTotals)
            }
            Spacer()
        }
    }

    @ViewBuilder func totalsFields(orderTotals: PointOfSaleOrderTotals?) -> some View {
        let totalsLoading = orderTotals == nil
        VStack {
            subtotalFieldView(title: Localization.subtotal,
                              formattedPrice: orderTotals?.cartTotal,
                              shimmeringActive: totalsLoading,
                              matchedGeometryId: Constants.matchedGeometrySubtotalId)
            Spacer().frame(height: Constants.subtotalsVerticalSpacing)

            if viewHelper.shouldShowTotalDiscountField(cart: posModel.cart, orderTotals: orderTotals) {
                subtotalFieldView(title: Localization.discount,
                                  formattedPrice: orderTotals?.discountTotal,
                                  shimmeringActive: totalsLoading,
                                  matchedGeometryId: Constants.matchedGeometryDiscountId)
                Spacer().frame(height: Constants.subtotalsVerticalSpacing)
            }

            subtotalFieldView(title: Localization.taxes,
                              formattedPrice: orderTotals?.taxTotal,
                              shimmeringActive: totalsLoading,
                              matchedGeometryId: Constants.matchedGeometryTaxId)
            Spacer().frame(height: Constants.totalVerticalSpacing)
            Divider()
                .overlay(Constants.separatorColor)
                .renderedIf(!totalsLoading)
            Spacer().frame(height: Constants.totalVerticalSpacing)
            totalFieldView(formattedPrice: orderTotals?.orderTotal,
                           shimmeringActive: totalsLoading,
                           matchedGeometryId: Constants.matchedGeometryTotalId)
        }
        .padding(Constants.totalsLineViewPadding)
        .frame(minWidth: Constants.pricesIdealWidth)
        .fixedSize(horizontal: true, vertical: false)
    }

    @ViewBuilder
    func subtotalFieldView(title: String,
                           formattedPrice: String?,
                           shimmeringActive: Bool,
                           matchedGeometryId: String) -> some View {
        if shimmeringActive {
            shimmeringLineView(width: Constants.shimmeringWidth, height: Constants.subtotalsShimmeringHeight)
                .matchedGeometryEffect(id: matchedGeometryId, in: totalsFieldAnimation)
        } else {
            HStack(alignment: .top, spacing: .zero) {
                Text(title)
                    .font(Constants.subtotalTitleFont)
                Spacer()
                Text(formattedPrice ?? "")
                    .font(Constants.subtotalAmountFont)
                    .redacted(reason: shimmeringActive ? [.placeholder] : [])
            }
            .accessibilityElement(children: .combine)
            .foregroundColor(Color.posOnSurface)
            .matchedGeometryEffect(id: matchedGeometryId, in: totalsFieldAnimation)
        }
    }

    @ViewBuilder
    func totalFieldView(formattedPrice: String?,
                        shimmeringActive: Bool,
                        matchedGeometryId: String) -> some View {
        if shimmeringActive {
            shimmeringLineView(width: Constants.shimmeringWidth, height: Constants.totalShimmeringHeight)
                .matchedGeometryEffect(id: matchedGeometryId, in: totalsFieldAnimation)
        } else {
            HStack(alignment: .top, spacing: .zero) {
                Text(Localization.total)
                    .font(Constants.totalTitleFont)
                    .fontWeight(.semibold)
                Spacer(minLength: Constants.totalsHorizontalSpacing)
                Text(formattedPrice ?? "")
                    .font(Constants.totalAmountFont)
                    .redacted(reason: shimmeringActive ? [.placeholder] : [])
            }
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isHeader)
            .foregroundColor(Color.posOnSurface)
            .matchedGeometryEffect(id: matchedGeometryId, in: totalsFieldAnimation)
        }
    }

    func shimmeringLineView(width: CGFloat, height: CGFloat) -> some View {
        Color.posOnSurfaceVariantLowest
            .frame(width: width, height: height)
            .fixedSize(horizontal: true, vertical: true)
            .shimmering(active: true)
            .cornerRadius(Constants.shimmeringCornerRadius)
    }

    /// Hide totals fields with animation after a delay when starting to processing a payment
    /// - Parameter isShowing
    private func hideTotalsFieldsWithDelay(_ isShowing: Bool) {
        guard !isShowing && posModel.paymentState == .card(.processingPayment) else {
            self.isShowingTotalsFields = isShowing
            return
        }

        withAnimation(.default.delay(Constants.totalsFieldsHideAnimationDelay)) {
            self.isShowingTotalsFields = false
        }
    }
}

@available(iOS 17.0, *)
private extension TotalsView {

    @ViewBuilder private var paymentView: some View {
        switch posModel.paymentState {
        case .card(let cardPaymentState):
            if TotalsViewHelper().shouldShowDisconnectedMessage(readerConnectionStatus: posModel.cardReaderConnectionStatus,
                                                                paymentState: cardPaymentState) {
                PointOfSaleCardPresentPaymentReaderDisconnectedMessageView {
                    posModel.connectCardReader()
                }
            } else if let inlinePaymentMessage = posModel.cardPresentPaymentInlineMessage {
                switch inlinePaymentMessage {
                case .paymentSuccess:
                    PointOfSaleCardPresentPaymentInLineMessage(messageType: inlinePaymentMessage)
                default:
                    HStack(alignment: .center) {
                        Spacer()
                        PointOfSaleCardPresentPaymentInLineMessage(messageType: inlinePaymentMessage)
                        Spacer()
                    }
                }
            }
        case .cash(let cashPaymentState):
            switch cashPaymentState {
            case .collectingCash:
                if case .loaded(let total) = posModel.orderState {
                    PointOfSaleCollectCashView(orderTotal: total.orderTotal)
                        .transition(.move(edge: .trailing))
                }
            case .paymentSuccess:
                if case .loaded(let total) = posModel.orderState {
                    PointOfSaleCardPresentPaymentInLineMessage(
                        messageType: .paymentSuccess(
                            viewModel: .init(formattedOrderTotal: total.orderTotal,
                                             paymentMethod: .cash)))
                }
            }
        }
    }
}

@available(iOS 17.0, *)
private extension TotalsView {
    struct PaymentViewLayout {
        let backgroundColor: Color
        let topPadding: CGFloat?
        let bottomPadding: CGFloat?
        let sidePadding: CGFloat

        init(backgroundColor: Color, topPadding: CGFloat?, bottomPadding: CGFloat?, sidePadding: CGFloat = 8) {
            self.backgroundColor = backgroundColor
            self.topPadding = topPadding
            self.bottomPadding = bottomPadding
            self.sidePadding = sidePadding
        }

        static let primary = PaymentViewLayout(
            backgroundColor: .clear,
            topPadding: nil,
            bottomPadding: POSPadding.small
        )

        static let outlined = PaymentViewLayout(
            backgroundColor: Color(.quaternarySystemFill),
            topPadding: POSPadding.xxLarge,
            bottomPadding: POSPadding.xxLarge
        )
    }

    private var isShowingPaymentView: Bool {
        guard posModel.orderState.isLoaded else {
            // When the order's being created or synced, we only show the shimmering totals.
            // Before the order exists, we don’t want to show the card payment status, as it will
            // show for a second initially, then disappear the moment we start syncing the order.
            return false
        }

        switch posModel.cardReaderConnectionStatus {
        case .connected, .disconnecting, .cancellingConnection:
            switch posModel.paymentState {
            case .card:
                return posModel.cardPresentPaymentInlineMessage != nil
            case .cash:
                return true
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

        switch posModel.paymentState {
        case .card(let cardPaymentState):
            switch cardPaymentState {
            case .validatingOrderError:
                return .outlined
            case .paymentError:
                return PaymentViewLayout(backgroundColor: backgroundColor,
                                         topPadding: POSPadding.none,
                                         bottomPadding: POSPadding.none,
                                         sidePadding: POSPadding.none)
            case .cardPaymentSuccessful:
                return PaymentViewLayout(backgroundColor: backgroundColor,
                                         topPadding: POSPadding.none,
                                         bottomPadding: POSPadding.none,
                                         sidePadding: POSPadding.none)
            case .idle,
                    .acceptingCard,
                    .validatingOrder,
                    .preparingReader,
                    .processingPayment:
                if TotalsViewHelper().shouldShowDisconnectedMessage(readerConnectionStatus: posModel.cardReaderConnectionStatus,
                                                                    paymentState: cardPaymentState) {
                    return .outlined
                } else {
                    return .primary
                }
            }
        case .cash(let cashPaymentState):
            switch cashPaymentState {
            case .collectingCash:
                return PaymentViewLayout(backgroundColor: backgroundColor,
                                         topPadding: POSPadding.none,
                                         bottomPadding: nil,
                                         sidePadding: POSPadding.none)
            case .paymentSuccess:
                return PaymentViewLayout(backgroundColor: backgroundColor,
                                         topPadding: POSPadding.none,
                                         bottomPadding: POSPadding.none,
                                         sidePadding: POSPadding.none)
            }
        }
    }
}

@available(iOS 17.0, *)
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

@available(iOS 17.0, *)
fileprivate extension View {
    func paymentViewPadding(layout: TotalsView.PaymentViewLayout) -> some View {
        modifier(TotalsView.PaymentViewPaddingModifier(layout: layout))
    }
}

@available(iOS 17.0, *)
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

        /// Used for synchronizing animations of shimmeringLine and textField
        static let matchedGeometrySubtotalId: String = "pos_totals_view_subtotal_matched_geometry_id"
        static let matchedGeometryDiscountId: String = "pos_totals_view_subtotal_matched_discount_id"
        static let matchedGeometryTaxId: String = "pos_totals_view_tax_matched_geometry_id"
        static let matchedGeometryTotalId: String = "pos_totals_view_total_matched_geometry_id"
        static let matchedGeometryCashId: String = "pos_totals_view_cash_matched_geometry_id"

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
        static let discount = NSLocalizedString(
            "pos.totalsView.discountTotal",
            value: "Discount",
            comment: "Title for discount amount field")
        static let cashPaymentButtonTitle = NSLocalizedString(
            "pos.totalsView.cash.button.title",
            value: "Cash payment",
            comment: "Title for the cash payment button title")
    }
}

#if DEBUG
@available(iOS 17.0, *)
#Preview {
    let posModel = PointOfSaleAggregateModel(
        itemsController: PointOfSalePreviewItemsController(),
        couponsController: PointOfSalePreviewItemsController(),
        cardPresentPaymentService: CardPresentPaymentPreviewService(),
        orderController: PointOfSalePreviewOrderController(),
        collectOrderPaymentAnalyticsTracker: POSCollectOrderPaymentAnalytics())
    TotalsView()
        .environment(posModel)
}
#endif
