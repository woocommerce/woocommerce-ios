import SwiftUI

struct TotalsView: View {
    @ObservedObject private var viewModel: TotalsViewModel

    /// Used together with .matchedGeometryEffect to synchronize the animations of shimmeringLineView and text fields.
    /// This makes SwiftUI treat these views as a single entity in the context of animation.
    /// It allows for a simultaneous transition from the shimmering effect to the text fields,
    /// and movement from the center of the VStack to their respective positions.
    @Namespace private var totalsFieldAnimation
    @State private var isShowingTotalsFields: Bool
    @State private var isShowingPaymentsButtonSpacing: Bool = false

    @Environment(\.dynamicTypeSize) var dynamicTypeSize
    @Environment(\.colorScheme) var colorScheme

    init(viewModel: TotalsViewModel) {
        self.viewModel = viewModel
        self.isShowingTotalsFields = viewModel.isShowingTotalsFields
    }

    var body: some View {
        HStack {
            switch viewModel.orderState {
            case .idle, .syncing, .loaded:
                VStack(alignment: .center) {
                    filledSpacer(backgroundColor: cardReaderViewLayout.backgroundColor,
                                 height: cardReaderViewLayout.topPadding)

                    VStack(alignment: .center, spacing: Constants.verticalSpacing) {
                        if viewModel.isShowingCardReaderStatus {
                            cardReaderView
                                .font(.title)
                                .padding([.top, .leading, .trailing],
                                         dynamicTypeSize.isAccessibilitySize ? nil :
                                            cardReaderViewLayout.sidePadding)
                                .padding(.bottom,
                                         dynamicTypeSize.isAccessibilitySize ? nil :
                                            cardReaderViewLayout.bottomPadding)
                                .transition(.opacity)
                                .background(cardReaderViewLayout.backgroundColor)
                                .accessibilityShowsLargeContentViewer()
                                .minimumScaleFactor(0.1)
                                .layoutPriority(1)
                        }

                        if isShowingTotalsFields {
                            totalsFieldsView
                                .transition(.opacity)
                                .animation(.default, value: viewModel.isShimmering)
                                .opacity(viewModel.isShowingTotalsFields ? 1 : 0)
                                .layoutPriority(2)
                        }
                    }
                    .animation(.default, value: viewModel.isShowingCardReaderStatus)
                    paymentsActionButtons
                    Spacer()
                }
            case .error(let viewModel):
                PointOfSaleOrderSyncErrorMessageView(viewModel: viewModel)
            }
        }
        .background(backgroundColor)
        .animation(.default, value: viewModel.isPaymentSuccessState)
        .onDisappear {
            viewModel.onTotalsViewDisappearance()
        }
        .onChange(of: viewModel.isShowingTotalsFields, perform: hideTotalsFieldsWithDelay)
    }

    private var backgroundColor: Color {
        switch viewModel.paymentState {
        case .cardPaymentSuccessful:
            colorScheme == .light ? Color(.wooCommerceEmerald(.shade20)) : Color(red: 0/255, green: 81/255, blue: 57/255)
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
            VStack() {
                subtotalFieldView(title: Localization.subtotal,
                                  formattedPrice: viewModel.formattedCartTotalPrice,
                                  shimmeringActive: viewModel.isShimmering,
                                  redacted: viewModel.isSubtotalFieldRedacted,
                                  matchedGeometryId: Constants.matchedGeometrySubtotalId)
                Spacer().frame(height: Constants.subtotalsVerticalSpacing)
                subtotalFieldView(title: Localization.taxes,
                                  formattedPrice: viewModel.formattedOrderTotalTaxPrice,
                                  shimmeringActive: viewModel.isShimmering,
                                  redacted: viewModel.isTaxFieldRedacted,
                                  matchedGeometryId: Constants.matchedGeometryTaxId)
                Spacer().frame(height: Constants.totalVerticalSpacing)
                Divider()
                    .overlay(Color.posTotalsSeparator)
                Spacer().frame(height: Constants.totalVerticalSpacing)
                totalFieldView(formattedPrice: viewModel.formattedOrderTotalPrice,
                               shimmeringActive: viewModel.isShimmering,
                               redacted: viewModel.isTotalPriceFieldRedacted,
                               matchedGeometryId: Constants.matchedGeometryTotalId)
            }
            .padding(Constants.totalsLineViewPadding)
            .frame(minWidth: Constants.pricesIdealWidth)
            .fixedSize(horizontal: true, vertical: false)
            Spacer()
        }
    }

    @ViewBuilder
    func subtotalFieldView(title: String,
                           formattedPrice: String?,
                           shimmeringActive: Bool,
                           redacted: Bool,
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
                    .redacted(reason: redacted ? [.placeholder] : [])
            }
            .accessibilityElement(children: .combine)
            .foregroundColor(Color.posPrimaryText)
            .matchedGeometryEffect(id: matchedGeometryId, in: totalsFieldAnimation)
        }
    }

    @ViewBuilder
    func totalFieldView(formattedPrice: String?,
                        shimmeringActive: Bool,
                        redacted: Bool,
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
                    .redacted(reason: redacted ? [.placeholder] : [])
            }
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isHeader)
            .foregroundColor(Color.posPrimaryText)
            .matchedGeometryEffect(id: matchedGeometryId, in: totalsFieldAnimation)
        }
    }

    func shimmeringLineView(width: CGFloat, height: CGFloat) -> some View {
        Color.posTotalsSeparator
            .frame(width: width, height: height)
            .fixedSize(horizontal: true, vertical: true)
            .redacted(reason: [.placeholder])
            .shimmering(active: true)
            .cornerRadius(Constants.shimmeringCornerRadius)
    }

    /// Hide totals fields with animation after a delay when starting to processing a payment
    /// - Parameter isShowing
    private func hideTotalsFieldsWithDelay(_ isShowing: Bool) {
        guard !isShowing && viewModel.paymentState == .processingPayment else {
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
            viewModel.startNewOrder()
        }, label: {
            HStack(spacing: Constants.newOrderButtonSpacing) {
                Image(systemName: Constants.newOrderImageName)
                    .font(.body.bold())
                    .aspectRatio(contentMode: .fit)
                Text(Localization.newOrder)
                    .font(Constants.newOrderButtonFont)
            }
            .frame(minWidth: UIScreen.main.bounds.width / 2)
        })
        .padding(Constants.newOrderButtonPadding)
        .foregroundColor(Color.posPrimaryText)
        .overlay(
            RoundedRectangle(cornerRadius: Constants.defaultBorderLineCornerRadius)
                .stroke(Color.posPrimaryText, lineWidth: Constants.defaultBorderLineWidth)
        )
    }

    @ViewBuilder
    private var paymentsActionButtons: some View {
        if viewModel.paymentState == .cardPaymentSuccessful {
            if isShowingPaymentsButtonSpacing {
                Spacer().frame(height: Constants.paymentsButtonSpacing)
            }
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
        switch viewModel.connectionStatus {
        case .connected:
            if let inlinePaymentMessage = viewModel.cardPresentPaymentInlineMessage {
                HStack(alignment: .center) {
                    Spacer()
                    PointOfSaleCardPresentPaymentInLineMessage(messageType: inlinePaymentMessage)
                    Spacer()
                }
            } else {
                EmptyView()
            }
        case .disconnected:
            PointOfSaleCardPresentPaymentReaderDisconnectedMessageView(viewModel: .init(connectReaderAction: viewModel.connectReaderTapped))
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
    }

    /// Creates a Spacer with backgroundColor and optional fixed height
    private func filledSpacer(backgroundColor: Color = .clear, height: CGFloat? = nil) -> some View {
        return ZStack {
            Spacer()
        }
        .background(backgroundColor)
        .if(height != nil) {
            $0.frame(height: height)
        }
    }

    private var cardReaderViewLayout: CardReaderViewLayout {
        guard viewModel.isShowingCardReaderStatus else {
            return .primary
        }

        if viewModel.paymentState == .validatingOrderError {
            return .outlined
        }

        if viewModel.connectionStatus == .disconnected {
            return .outlined
        }

        return .primary
    }
}

private extension TotalsView {
    enum Constants {
        static let pricesIdealWidth: CGFloat = 382
        static let defaultBorderLineWidth: CGFloat = 1
        static let defaultBorderLineCornerRadius: CGFloat = 8

        static let verticalSpacing: CGFloat = 56

        static let totalsLineViewPadding: EdgeInsets = .init(top: 20, leading: 24, bottom: 20, trailing: 24)
        static let subtotalsVerticalSpacing: CGFloat = 8
        static let totalVerticalSpacing: CGFloat = 16
        static let totalsHorizontalSpacing: CGFloat = 24
        static let subtotalTitleFont: POSFontStyle = .posBodyRegular
        static let subtotalAmountFont: POSFontStyle = .posBodyRegular
        static let totalTitleFont: POSFontStyle = .posTitleRegular
        static let totalAmountFont: POSFontStyle = .posTitleEmphasized

        static let shimmeringCornerRadius: CGFloat = 4
        static let shimmeringWidth: CGFloat = 334
        static let subtotalsShimmeringHeight: CGFloat = 36
        static let totalShimmeringHeight: CGFloat = 40

        static let paymentsButtonSpacing: CGFloat = 52
        static let paymentsButtonButtonSpacingAnimationDelay: CGFloat = 0.3
        static let newOrderButtonSpacing: CGFloat = 12
        static let newOrderButtonPadding: CGFloat = 22
        static let newOrderButtonFont: POSFontStyle = .posBodyEmphasized
        static let newOrderImageName: String = "arrow.uturn.backward"

        /// Used for synchronizing animations of shimmeringLine and textField
        static let matchedGeometrySubtotalId: String = "pos_totals_view_subtotal_matched_geometry_id"
        static let matchedGeometryTaxId: String = "pos_totals_view_tax_matched_geometry_id"
        static let matchedGeometryTotalId: String = "pos_totals_view_total_matched_geometry_id"

        static let totalsFieldsHideAnimationDelay: CGFloat = 0.8
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
        static let calculateAmounts = NSLocalizedString(
            "pos.totalsView.calculateAmounts",
            value: "Calculate amounts",
            comment: "Button title for calculate amounts button")
    }
}

#if DEBUG
#Preview {
    let totalsVM = TotalsViewModel(orderService: POSOrderPreviewService(),
                                   cardPresentPaymentService: CardPresentPaymentPreviewService(),
                                   currencyFormatter: .init(currencySettings: .init()),
                                    paymentState: .acceptingCard)
    return TotalsView(viewModel: totalsVM)
}
#endif
