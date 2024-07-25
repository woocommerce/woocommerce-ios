import SwiftUI

struct TotalsView: View {
    @ObservedObject private var viewModel: PointOfSaleDashboardViewModel
    @ObservedObject private var totalsViewModel: TotalsViewModel
    @ObservedObject private var cartViewModel: CartViewModel

    init(viewModel: PointOfSaleDashboardViewModel,
         totalsViewModel: TotalsViewModel,
         cartViewModel: CartViewModel) {
        self.viewModel = viewModel
        self.totalsViewModel = totalsViewModel
        self.cartViewModel = cartViewModel
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                VStack {
                    Spacer()
                    cardReaderView
                        .font(.title)
                        .padding()
                    Spacer()
                    totalsLinesView
                }
                paymentsActionButtons
                    .padding()
            }
        }
        .onDisappear {
            totalsViewModel.onTotalsViewDisappearance()
        }
    }
}

private extension TotalsView {
    var totalsLinesView: some View {
        HStack(alignment: .center) {
            Spacer()
            VStack() {
                priceFieldView(title: Localization.subtotal,
                               formattedPrice: totalsViewModel.formattedCartTotalPrice,
                               shimmeringActive: totalsViewModel.isShimmering,
                               redacted: totalsViewModel.isSubtotalFieldRedacted)
                Spacer().frame(height: Constants.subtotalsVerticalSpacing)
                priceFieldView(title: Localization.taxes,
                               formattedPrice:
                                totalsViewModel.formattedOrderTotalTaxPrice,
                               shimmeringActive: totalsViewModel.isShimmering,
                               redacted: totalsViewModel.isTaxFieldRedacted)
                Spacer().frame(height: Constants.totalVerticalSpacing)
                Divider()
                    .overlay(Color.posTotalsSeparator)
                Spacer().frame(height: Constants.totalVerticalSpacing)
                totalPriceFieldView(formattedPrice: totalsViewModel.formattedOrderTotalPrice,
                                    shimmeringActive: totalsViewModel.isShimmering,
                                    redacted: totalsViewModel.isTotalPriceFieldRedacted)
            }
            .padding(Constants.totalsLineViewPadding)
            .frame(minWidth: Constants.pricesIdealWidth)
            .fixedSize(horizontal: true, vertical: false)
            Spacer()
        }
    }

    @ViewBuilder
    func priceFieldView(title: String, formattedPrice: String?, shimmeringActive: Bool, redacted: Bool) -> some View {
        HStack(alignment: .top, spacing: .zero) {
            Text(title)
                .font(Constants.subtotalTitleFont)
            Spacer()
            Text(formattedPrice ?? "")
                .font(Constants.subtotalAmountFont)
        }
        .foregroundColor(Color.primaryText)
    }

    @ViewBuilder
    func totalPriceFieldView(formattedPrice: String?, shimmeringActive: Bool, redacted: Bool) -> some View {
        HStack(alignment: .top, spacing: .zero) {
            Text(Localization.total)
                .font(Constants.totalTitleFont)
                .fontWeight(.semibold)
            Spacer(minLength: Constants.totalsHorizontalSpacing)
            Text(formattedPrice ?? "")
                .font(Constants.totalAmountFont)
        }
        .foregroundColor(Color.primaryText)
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
                POSCardPresentPaymentMessageView(viewModel: .init(title: "Reader connected",
                                                                  buttons: [.init(title: "Collect Payment",
                                                                                  actionHandler: totalsViewModel.cardPaymentTapped)]))
            }
        case .disconnected:
            POSCardPresentPaymentMessageView(viewModel: .init(title: "Reader disconnected",
                                                              buttons: [.init(title: "Collect Payment",
                                                                              actionHandler: totalsViewModel.cardPaymentTapped)]))
        }
    }
}

private extension TotalsView {
    enum Constants {
        static let pricesIdealWidth: CGFloat = 382
        static let defaultBorderLineWidth: CGFloat = 1
        static let defaultBorderLineCornerRadius: CGFloat = 8

        static let totalsLineViewPadding: EdgeInsets = .init(top: 20, leading: 24, bottom: 20, trailing: 24)
        static let subtotalsVerticalSpacing: CGFloat = 8
        static let totalVerticalSpacing: CGFloat = 16
        static let totalsHorizontalSpacing: CGFloat = 24
        static let subtotalTitleFont: Font = Font.system(size: 24)
        static let subtotalAmountFont: Font = Font.system(size: 24)
        static let totalTitleFont: Font = Font.system(.largeTitle, design: .default, weight: .medium)
        static let totalAmountFont: Font = Font.system(.largeTitle, design: .default, weight: .bold)

        static let newTransactionButtonSpacing: CGFloat = 20
        static let newTransactionButtonPadding: CGFloat = 16
        static let newTransactionButtonFont: Font = Font.system(size: 32, weight: .medium)
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
    let posVM = PointOfSaleDashboardViewModel(itemProvider: POSItemProviderPreview(),
                                              cardPresentPaymentService: CardPresentPaymentPreviewService(),
                                              orderService: POSOrderPreviewService(),
                                              currencyFormatter: .init(currencySettings: .init()),
                                              totalsViewModel: totalsVM,
                                              cartViewModel: cartViewModel)
    return TotalsView(viewModel: posVM, totalsViewModel: totalsVM, cartViewModel: cartViewModel)
}
#endif
