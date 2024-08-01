import SwiftUI

struct TotalsView: View {
    @ObservedObject private var viewModel: PointOfSaleDashboardViewModel
    @ObservedObject private var totalsViewModel: TotalsViewModel
    @ObservedObject private var cartViewModel: CartViewModel

    /// Used together with .matchedGeometryEffect to synchronize the animations of shimmeringLineView and text fields.
    /// This makes SwiftUI treat these views as a single entity in the context of animation.
    /// It allows for a simultaneous transition from the shimmering effect to the text fields,
    /// and movement from the center of the VStack to their respective positions.
    @Namespace private var totalsFieldAnimation
    @State private var hasViewAppeared: Bool = false

    init(viewModel: PointOfSaleDashboardViewModel,
         totalsViewModel: TotalsViewModel,
         cartViewModel: CartViewModel) {
        self.viewModel = viewModel
        self.totalsViewModel = totalsViewModel
        self.cartViewModel = cartViewModel
    }

    var body: some View {
        HStack {
            VStack(alignment: .center) {
                Spacer()
                VStack(alignment: .center, spacing: Constants.verticalSpacing) {
                    if totalsViewModel.isShowingCardReaderStatus {
                        cardReaderView
                            .font(.title)
                            .padding()
                            .transition(.opacity)
                    }

                    totalsFieldsView
                        .transition(.opacity)
                        .animation(.default, value: totalsViewModel.isShimmering)
                }
                .animation(.default, value: totalsViewModel.isShowingCardReaderStatus)
                .transaction { transaction in
                    // Disable animations within the view while the view is appearing
                    if !hasViewAppeared {
                        transaction.animation = nil
                    }
                }
                paymentsActionButtons
                    .padding()
                Spacer()
            }
        }
        .onAppear {
            hasViewAppeared = true
        }
        .onDisappear {
            totalsViewModel.onTotalsViewDisappearance()
        }
    }
}

private extension TotalsView {
    var totalsFieldsView: some View {
        HStack(alignment: .center) {
            Spacer()
            VStack() {
                subtotalFieldView(title: Localization.subtotal,
                                  formattedPrice: totalsViewModel.formattedCartTotalPrice,
                                  shimmeringActive: totalsViewModel.isShimmering,
                                  redacted: totalsViewModel.isSubtotalFieldRedacted,
                                  matchedGeometryId: Constants.matchedGeometrySubtotalId)
                Spacer().frame(height: Constants.subtotalsVerticalSpacing)
                subtotalFieldView(title: Localization.taxes,
                                  formattedPrice: totalsViewModel.formattedOrderTotalTaxPrice,
                                  shimmeringActive: totalsViewModel.isShimmering,
                                  redacted: totalsViewModel.isTaxFieldRedacted,
                                  matchedGeometryId: Constants.matchedGeometryTaxId)
                Spacer().frame(height: Constants.totalVerticalSpacing)
                Divider()
                    .overlay(Color.posTotalsSeparator)
                Spacer().frame(height: Constants.totalVerticalSpacing)
                totalFieldView(formattedPrice: totalsViewModel.formattedOrderTotalPrice,
                               shimmeringActive: totalsViewModel.isShimmering,
                               redacted: totalsViewModel.isTotalPriceFieldRedacted,
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
            .foregroundColor(Color.primaryText)
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
            .foregroundColor(Color.primaryText)
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
}

private extension TotalsView {
    private var newTransactionButton: some View {
        Button(action: {
            viewModel.startNewTransaction()
        }, label: {
            HStack(spacing: Constants.newTransactionButtonSpacing) {
                Spacer()
                Image(uiImage: .posNewTransactionImage)
                Text(Localization.newTransaction)
                    .font(Constants.newTransactionButtonFont)
                Spacer()
            }
        })
        .padding(Constants.newTransactionButtonPadding)
        .foregroundColor(Color.primaryText)
        .overlay(
            RoundedRectangle(cornerRadius: Constants.defaultBorderLineCornerRadius)
                .stroke(Color.primaryText, lineWidth: Constants.defaultBorderLineWidth)
        )
    }

    @ViewBuilder
    private var paymentsActionButtons: some View {
        if totalsViewModel.paymentState == .cardPaymentSuccessful {
            newTransactionButton
        }
        else {
            EmptyView()
        }
    }

    @ViewBuilder private var cardReaderView: some View {
        switch totalsViewModel.connectionStatus {
        case .connected:
            if let inlinePaymentMessage = totalsViewModel.cardPresentPaymentInlineMessage {
                PointOfSaleCardPresentPaymentInLineMessage(messageType: inlinePaymentMessage)
            } else {
                EmptyView()
            }
        case .disconnected:
            PointOfSaleCardPresentPaymentReaderDisconnectedMessageView(viewModel: .init(collectPaymentAction: totalsViewModel.cardPaymentTapped))
        }
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
        static let subtotalTitleFont: Font = Font.system(size: 24)
        static let subtotalAmountFont: Font = Font.system(size: 24)
        static let totalTitleFont: Font = Font.system(.largeTitle, design: .default, weight: .medium)
        static let totalAmountFont: Font = Font.system(.largeTitle, design: .default, weight: .bold)

        static let shimmeringCornerRadius: CGFloat = 4
        static let shimmeringWidth: CGFloat = 334
        static let subtotalsShimmeringHeight: CGFloat = 36
        static let totalShimmeringHeight: CGFloat = 40

        static let newTransactionButtonSpacing: CGFloat = 20
        static let newTransactionButtonPadding: CGFloat = 16
        static let newTransactionButtonFont: Font = Font.system(size: 32, weight: .medium)

        /// Used for synchronizing animations of shimmeringLine and textField
        static let matchedGeometrySubtotalId: String = UUID().uuidString
        static let matchedGeometryTaxId: String = UUID().uuidString
        static let matchedGeometryTotalId: String = UUID().uuidString
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
        static let newTransaction = NSLocalizedString(
            "pos.totalsView.newTransaction",
            value: "New transaction",
            comment: "Button title for new transaction button")
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
                                    paymentState: .acceptingCard,
                                   isSyncingOrder: false)
    let cartViewModel = CartViewModel()
    let itemsListViewModel = ItemListViewModel(itemProvider: POSItemProviderPreview())
    let posVM = PointOfSaleDashboardViewModel(cardPresentPaymentService: CardPresentPaymentPreviewService(),
                                              totalsViewModel: totalsVM,
                                              cartViewModel: cartViewModel,
                                              itemListViewModel: itemsListViewModel)
    return TotalsView(viewModel: posVM, totalsViewModel: totalsVM, cartViewModel: cartViewModel)
}
#endif
