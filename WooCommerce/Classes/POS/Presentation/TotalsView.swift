import SwiftUI

struct TotalsView: View {
    @EnvironmentObject private var posModel: PointOfSaleAggregateModel
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

    private var shouldShowCollectCashPaymentButton: Bool {
        ServiceLocator.featureFlagService.isFeatureFlagEnabled(.acceptCashForPointOfSale) &&
        posModel.orderState != .syncing &&
        (posModel.paymentState == .card(.idle) || posModel.paymentState == .card(.acceptingCard))
    }

    @Environment(\.dynamicTypeSize) var dynamicTypeSize
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        HStack {
            switch posModel.orderState {
            case .idle, .syncing, .loaded:
                VStack(alignment: .center) {
                    Spacer()
                        .renderedIf(cardReaderViewLayout.topPadding == nil)

                    VStack(alignment: .center, spacing: dynamicVerticalSpacing(for: dynamicTypeSize)) {
                        if isShowingCardReaderStatus {
                            paymentView
                                .font(.title)
                                .padding([.leading, .trailing],
                                         dynamicTypeSize.isAccessibilitySize ? nil :
                                            cardReaderViewLayout.sidePadding)
                                .padding(.bottom,
                                         dynamicTypeSize.isAccessibilitySize ? nil :
                                            cardReaderViewLayout.bottomPadding)
                                .padding(.top, dynamicTypeSize.isAccessibilitySize ? nil : cardReaderViewLayout.topPadding)
                                .transition(.opacity)
                                .accessibilityShowsLargeContentViewer()
                                .layoutPriority(1)
                                .background(backgroundColor)
                        }

                        if isShowingTotalsFields {
                            totalsFieldsView
                                .transition(.opacity)
                                .animation(.default, value: posModel.orderState.isSyncing)
                                .opacity(viewHelper.shouldShowTotalsFields(for: posModel.paymentState) ? 1 : 0)
                                .layoutPriority(2)
                        }
                        Button(action: {
                            Task { @MainActor in
                                await posModel.startCashPayment()
                            }
                        }, label: {
                            Text(Localization.cashPaymentButtonTitle)
                                .font(POSFontStyle.posBodyEmphasized)
                                .foregroundColor(.posPrimaryText)
                                .frame(height: Constants.buttonHeight)
                        })
                        .buttonStyle(SecondaryButtonStyle())
                        .padding(.horizontal, Constants.buttonHorizontalPadding)
                        .renderedIf(shouldShowCollectCashPaymentButton)
                    }
                    .animation(.default, value: posModel.cardPresentPaymentInlineMessage)
                    Spacer()
                }
                .animation(.default, value: isShowingCardReaderStatus)
            case .error(let viewModel):
                PointOfSaleOrderSyncErrorMessageView(viewModel: viewModel)
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
        .geometryGroupIfSupported()
    }

    private var backgroundColor: Color {
        switch posModel.paymentState {
        case .card(.cardPaymentSuccessful), .cash(.paymentSuccess):
            .posSecondaryBackground
        case .card(.processingPayment):
            colorScheme == .light ? Color(.wooCommercePurple(.shade70)) : Color(.wooCommercePurple(.shade10))
        case .cash(.collectingCash):
            colorScheme == .light ? .clear : Color.posSecondaryBackground
        default:
            .clear
        }
    }
}

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
            subtotalFieldView(title: Localization.taxes,
                              formattedPrice: orderTotals?.taxTotal,
                              shimmeringActive: totalsLoading,
                              matchedGeometryId: Constants.matchedGeometryTaxId)
            Spacer().frame(height: Constants.totalVerticalSpacing)
            Divider()
                .overlay(Constants.separatorColor)
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
            .foregroundColor(Color.posPrimaryText)
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
            .foregroundColor(Color.posPrimaryText)
            .matchedGeometryEffect(id: matchedGeometryId, in: totalsFieldAnimation)
        }
    }

    func shimmeringLineView(width: CGFloat, height: CGFloat) -> some View {
        Constants.separatorColor
            .frame(width: width, height: height)
            .fixedSize(horizontal: true, vertical: true)
            .redacted(reason: [.placeholder])
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

private extension TotalsView {

    @ViewBuilder private var paymentView: some View {
        switch posModel.paymentState {
        case .card:
            switch posModel.cardReaderConnectionStatus {
            case .connected, .disconnecting, .cancellingConnection:
                if let inlinePaymentMessage = posModel.cardPresentPaymentInlineMessage {
                    HStack(alignment: .center) {
                        Spacer()
                        PointOfSaleCardPresentPaymentInLineMessage(messageType: inlinePaymentMessage)
                        Spacer()
                    }
                } else {
                    EmptyView()
                }
            case .disconnected:
                PointOfSaleCardPresentPaymentReaderDisconnectedMessageView {
                    posModel.connectCardReader()
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
                    HStack(alignment: .center) {
                        Spacer()
                        PointOfSaleCardPresentPaymentInLineMessage(messageType: .paymentSuccess(viewModel: .init(formattedOrderTotal: total.orderTotal)))
                        Spacer()
                    }
                }
            }
        }
    }
}

private extension TotalsView {
    struct PaymentViewLayout {
        let backgroundColor: Color
        let topPadding: CGFloat?
        let bottomPadding: CGFloat?
        let sidePadding: CGFloat = 8

        static let primary = PaymentViewLayout(
            backgroundColor: .clear,
            topPadding: nil,
            bottomPadding: 8
        )

        static let outlined = PaymentViewLayout(
            backgroundColor: Color(.quaternarySystemFill),
            topPadding: 40,
            bottomPadding: 40
        )

        static let topAligned = PaymentViewLayout(
            backgroundColor: .clear,
            topPadding: 96,
            bottomPadding: 96
        )
    }

    private var isShowingCardReaderStatus: Bool {
        guard posModel.orderState.isLoaded else {
            // When the order's being created or synced, we only show the shimmering totals.
            // Before the order exists, we don’t want to show the card payment status, as it will
            // show for a second initially, then disappear the moment we start syncing the order.
            return false
        }

        switch posModel.cardReaderConnectionStatus {
        case .connected, .disconnecting, .cancellingConnection:
            return posModel.cardPresentPaymentInlineMessage != nil
        case .disconnected:
            // Since the reader is disconnected, this will show the "Connect your reader" CTA button view.
            return true
        }
    }

    private var cardReaderViewLayout: PaymentViewLayout {
        guard isShowingCardReaderStatus else {
            return .primary
        }

        switch posModel.paymentState {
        case .card(let cardPaymentState):
            switch cardPaymentState {
            case .validatingOrderError:
                return .outlined
            case .paymentError:
                return .topAligned
            case .idle,
                    .acceptingCard,
                    .validatingOrder,
                    .preparingReader,
                    .processingPayment,
                    .cardPaymentSuccessful:
                break
            }
        case .cash:
            return PaymentViewLayout(backgroundColor: backgroundColor,
                                     topPadding: nil,
                                     bottomPadding: nil)
        }

        if posModel.cardReaderConnectionStatus == .disconnected {
            return .outlined
        }

        return .primary
    }
}

private extension TotalsView {
    enum Constants {
        static let pricesIdealWidth: CGFloat = 382
        static let verticalSpacing: CGFloat = 56
        static let buttonHeight: CGFloat = 56
        static let buttonHorizontalPadding: CGFloat = 48

        static let totalsLineViewPadding: EdgeInsets = .init(top: 20, leading: 24, bottom: 20, trailing: 24)
        static let subtotalsVerticalSpacing: CGFloat = 8
        static let totalVerticalSpacing: CGFloat = 16
        static let totalsHorizontalSpacing: CGFloat = 24
        static let subtotalTitleFont: POSFontStyle = .posBodyRegular
        static let subtotalAmountFont: POSFontStyle = .posBodyRegular
        static let totalTitleFont: POSFontStyle = .posTitleRegular
        static let totalAmountFont: POSFontStyle = .posTitleEmphasized
        static let separatorColor: Color = Color(.systemGray3)

        static let shimmeringCornerRadius: CGFloat = 4
        static let shimmeringWidth: CGFloat = 334
        static let subtotalsShimmeringHeight: CGFloat = 36
        static let totalShimmeringHeight: CGFloat = 40

        /// Used for synchronizing animations of shimmeringLine and textField
        static let matchedGeometrySubtotalId: String = "pos_totals_view_subtotal_matched_geometry_id"
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
        static let cashPaymentButtonTitle = NSLocalizedString(
            "pos.totalsView.cash.button.title",
            value: "Cash payment",
            comment: "Title for the cash payment button title")
    }

    private func dynamicVerticalSpacing(for size: DynamicTypeSize) -> CGFloat {
        switch size {
        case    .accessibility1,
                .accessibility2,
                .accessibility3,
                .accessibility4,
                .accessibility5:
            return 0
        case .xLarge, .xxLarge:
            return Constants.verticalSpacing * 0.75
        case .xxxLarge:
            return Constants.verticalSpacing * 0.5
        default:
            return Constants.verticalSpacing
        }
    }
}

private extension View {
    ///  Force the position and size values to be resolved and animated by the parent
    ///  before being passed down to each subview.
    ///  GeometryGroup is created to ensure that childs views stay locked together as animations are applied.
    ///  It results in the whole TotalsView animated together when transitioning.
    func geometryGroupIfSupported() -> some View {
        if #available(iOS 17.0, *) {
            return self.geometryGroup()
        } else {
            return self
        }
    }
}

#if DEBUG
#Preview {
    let posModel = PointOfSaleAggregateModel(
        itemsController: PointOfSalePreviewItemsController(),
        cardPresentPaymentService: CardPresentPaymentPreviewService(),
        orderController: PointOfSalePreviewOrderController())
    TotalsView()
        .environmentObject(posModel)
}
#endif
