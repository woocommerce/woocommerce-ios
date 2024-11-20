import SwiftUI

struct TotalsView: View {
    @EnvironmentObject private var posModel: PointOfSaleAggregateModel
    @ObservedObject private var viewModel: TotalsViewModel

    /// Used together with .matchedGeometryEffect to synchronize the animations of shimmeringLineView and text fields.
    /// This makes SwiftUI treat these views as a single entity in the context of animation.
    /// It allows for a simultaneous transition from the shimmering effect to the text fields,
    /// and movement from the center of the VStack to their respective positions.
    @Namespace private var totalsFieldAnimation

    // The source of truth for whether totals _are_ showing; separate from whether they
    // _should be_ showing, so that we can animate the change.
    @State private var isShowingTotalsFields: Bool = false
    private var shouldShowTotalsFields: Bool {
        viewModel.shouldShowTotalsFields(for: posModel.paymentState)
    }
    @State private var isShowingPaymentsButtonSpacing: Bool = false

    @Environment(\.dynamicTypeSize) var dynamicTypeSize
    @Environment(\.colorScheme) var colorScheme

    private var shouldShowSendReceiptButton: Bool {
        ServiceLocator.featureFlagService.isFeatureFlagEnabled(.sendReceiptsForPointOfSale)
    }

    init(viewModel: TotalsViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        HStack {
            switch posModel.orderState {
            case .idle, .syncing, .loaded:
                VStack(alignment: .center) {
                    Spacer()
                        .renderedIf(cardReaderViewLayout.topPadding == nil)

                    VStack(alignment: .center, spacing: Constants.verticalSpacing) {
                        if isShowingCardReaderStatus {
                            cardReaderView
                                .font(.title)
                                .padding([.leading, .trailing],
                                         dynamicTypeSize.isAccessibilitySize ? nil :
                                            cardReaderViewLayout.sidePadding)
                                .padding(.bottom,
                                         dynamicTypeSize.isAccessibilitySize ? nil :
                                            cardReaderViewLayout.bottomPadding)
                                .padding(.top, dynamicTypeSize.isAccessibilitySize ? nil : cardReaderViewLayout.topPadding)
                                .transition(.opacity)
                                .background(cardReaderViewLayout.backgroundColor)
                                .accessibilityShowsLargeContentViewer()
                                .minimumScaleFactor(0.1)
                                .layoutPriority(1)
                        }

                        if isShowingTotalsFields {
                            totalsFieldsView
                                .transition(.opacity)
                                .animation(.default, value: posModel.orderState.isSyncing)
                                .opacity(viewModel.shouldShowTotalsFields(for: posModel.paymentState) ? 1 : 0)
                                .layoutPriority(2)
                        }
                    }
                    .animation(.default, value: posModel.cardPresentPaymentInlineMessage)
                    paymentsActionButtons
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
        .onDisappear {
            viewModel.onTotalsViewDisappearance()
        }
        .onAppear {
            isShowingTotalsFields = shouldShowTotalsFields
        }
        .onChange(of: shouldShowTotalsFields, perform: hideTotalsFieldsWithDelay)
        .geometryGroupIfSupported()
    }

    private var backgroundColor: Color {
        switch posModel.paymentState {
        case .cardPaymentSuccessful:
            .posSecondaryBackground
        case .processingPayment:
            colorScheme == .light ? Color(.wooCommercePurple(.shade70)) : Color(.wooCommercePurple(.shade10))
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
        guard !isShowing && posModel.paymentState == .processingPayment else {
            self.isShowingTotalsFields = isShowing
            return
        }

        withAnimation(.default.delay(Constants.totalsFieldsHideAnimationDelay)) {
            self.isShowingTotalsFields = false
        }
    }
}

private extension TotalsView {
    private var newOrderButton: some View {
        Button(action: {
            posModel.startNewCart()
        }, label: {
            HStack(spacing: Constants.buttonSpacing) {
                Text(Localization.newOrder)
                    .font(Constants.buttonFont)
            }
            .frame(minWidth: UIScreen.main.bounds.width / 2)
        })
        .padding(Constants.buttonPadding)
        .foregroundColor(Constants.posPrimaryTextInverted)
        .background(Constants.posOverlayFillInverted)
        .cornerRadius(Constants.buttonCornerRadius)
    }

    private var sendReceiptButton: some View {
        Button(action: {
            // no-op
            // https://github.com/woocommerce/woocommerce-ios/issues/14461
        }, label: {
            HStack(spacing: Constants.buttonSpacing) {
                Text(Localization.sendReceipt)
                    .font(Constants.buttonFont)
            }
            .frame(minWidth: UIScreen.main.bounds.width / 2)
        })
        .padding(Constants.buttonPadding)
        .foregroundColor(Color.posPrimaryText)
        .background(Color.clear)
        .overlay {
            RoundedRectangle(cornerRadius: Constants.buttonCornerRadius)
                        .stroke(Color.posPrimaryText, lineWidth: 1.0)
        }
    }

    @ViewBuilder
    private var paymentsActionButtons: some View {
        if posModel.paymentState == .cardPaymentSuccessful {
            if isShowingPaymentsButtonSpacing {
                Spacer().frame(height: Constants.paymentsButtonSpacing)
            }
            sendReceiptButton
                .renderedIf(shouldShowSendReceiptButton)
            newOrderButton
                .onAppear {
                    isShowingPaymentsButtonSpacing = false
                    withAnimation(.default.delay(Constants.paymentsButtonButtonSpacingAnimationDelay)) {
                        isShowingPaymentsButtonSpacing = true
                    }
                }
            Spacer().frame(height: Constants.paymentsButtonSpacing)
        }
        else {
            EmptyView()
        }
    }

    @ViewBuilder private var cardReaderView: some View {
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
            PointOfSaleCardPresentPaymentReaderDisconnectedMessageView()
        }
    }
}

private extension TotalsView {
    struct CardReaderViewLayout {
        let backgroundColor: Color
        let topPadding: CGFloat?
        let bottomPadding: CGFloat?
        let sidePadding: CGFloat = 8

        static let primary = CardReaderViewLayout(
            backgroundColor: .clear,
            topPadding: nil,
            bottomPadding: 8
        )

        static let outlined = CardReaderViewLayout(
            backgroundColor: Color(.quaternarySystemFill),
            topPadding: 40,
            bottomPadding: 40
        )

        static let topAligned = CardReaderViewLayout(
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

    private var cardReaderViewLayout: CardReaderViewLayout {
        guard isShowingCardReaderStatus else {
            return .primary
        }

        switch posModel.paymentState {
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

        if posModel.cardReaderConnectionStatus == .disconnected {
            return .outlined
        }

        return .primary
    }
}

private extension TotalsView {
    enum Constants {
        static let pricesIdealWidth: CGFloat = 382
        static let buttonCornerRadius: CGFloat = 8

        static let verticalSpacing: CGFloat = 56

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

        static let paymentsButtonSpacing: CGFloat = 80
        static let paymentsButtonButtonSpacingAnimationDelay: CGFloat = 0.3
        static let buttonSpacing: CGFloat = 12
        static let buttonPadding: CGFloat = 32
        static let buttonFont: POSFontStyle = .posBodyEmphasized

        /// Used for synchronizing animations of shimmeringLine and textField
        static let matchedGeometrySubtotalId: String = "pos_totals_view_subtotal_matched_geometry_id"
        static let matchedGeometryTaxId: String = "pos_totals_view_tax_matched_geometry_id"
        static let matchedGeometryTotalId: String = "pos_totals_view_total_matched_geometry_id"

        static let totalsFieldsHideAnimationDelay: CGFloat = 0.3

        static var posOverlayFillInverted: Color {
            Color(
                UIColor(
                    light: .black,
                    dark: .white
                )
            )
        }

        static var posPrimaryTextInverted: Color {
            Color(
                UIColor(
                    light: UIColor(.white),
                    dark: UIColor(.black)
                )
            )
        }
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
        static let newOrder = NSLocalizedString(
            "pos.totalsView.newOrder",
            value: "New order",
            comment: "Button title for new order button")
        static let sendReceipt = NSLocalizedString(
            "pos.totalsView.sendReceipt",
            value: "Receipt",
            comment: "Button title for the receipt button")
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
        itemProvider: POSItemProviderPreview(),
        cardPresentPaymentService: CardPresentPaymentPreviewService(),
        orderService: POSOrderPreviewService())
    let totalsVM = TotalsViewModel(posModel: posModel)
    TotalsView(viewModel: totalsVM)
        .environmentObject(posModel)
}
#endif
