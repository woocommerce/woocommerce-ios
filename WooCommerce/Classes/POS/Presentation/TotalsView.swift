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
                    VStack(alignment: .leading, spacing: 32) {
                        HStack {
                            VStack(spacing: Constants.totalsVerticalSpacing) {
                                priceFieldView(title: Localization.subtotal,
                                               formattedPrice: totalsViewModel.formattedCartTotalPrice,
                                               shimmeringActive: totalsViewModel.isShimmering,
                                               redacted: totalsViewModel.isSubtotalFieldRedacted)
                                Divider()
                                    .overlay(Color.posTotalsSeparator)
                                priceFieldView(title: Localization.taxes,
                                               formattedPrice:
                                                totalsViewModel.formattedOrderTotalTaxPrice,
                                               shimmeringActive: totalsViewModel.isShimmering,
                                               redacted: totalsViewModel.isTaxFieldRedacted)
                                Divider()
                                    .overlay(Color.posTotalsSeparator)
                                totalPriceView(formattedPrice: totalsViewModel.formattedOrderTotalPrice,
                                               shimmeringActive: totalsViewModel.isShimmering,
                                               redacted: totalsViewModel.isTotalPriceFieldRedacted)
                            }
                            .padding()
                            .frame(idealWidth: Constants.pricesIdealWidth)
                        }
                        .overlay(
                            RoundedRectangle(cornerRadius: Constants.defaultBorderLineCornerRadius)
                                .stroke(Color.posTotalsSeparator, lineWidth: Constants.defaultBorderLineWidth)
                        )
                        if totalsViewModel.showRecalculateButton {
                            Button(Localization.calculateAmounts) {
                                totalsViewModel.calculateAmountsTapped(
                                    with: cartViewModel.itemsInCart,
                                    allItems: viewModel.itemListViewModel.items)
                            }
                        }
                    }
                    .padding(Constants.totalsPadding)
                }
                .background(
                    LinearGradient(gradient: Gradient(stops: gradientStops),
                                   startPoint: .top,
                                   endPoint: .bottom)
                )
                paymentsActionButtons
                    .padding()
            }
        }
        .onDisappear {
            totalsViewModel.onTotalsViewDisappearance()
        }
    }

    private var gradientStops: [Gradient.Stop] {
        if totalsViewModel.paymentState == .cardPaymentSuccessful {
            return [
                Gradient.Stop(color: Color.clear, location: 0.0),
                Gradient.Stop(color: Color.posTotalsGradientGreen, location: 1.0)
            ]
        }
        else {
            return [
                Gradient.Stop(color: Color.clear, location: 0.0),
                Gradient.Stop(color: Color.posTotalsGradientPurple, location: 1.0)
            ]
        }
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

    @ViewBuilder func priceFieldView(title: String, formattedPrice: String?, shimmeringActive: Bool, redacted: Bool) -> some View {
        HStack(alignment: .top, spacing: .zero) {
            Text(title)
                .font(Constants.subtotalTitleFont)
            Spacer()
            Text(formattedPrice ?? "-----")
                .font(Constants.subtotalAmountFont)
                .redacted(reason: redacted ? [.placeholder] : [])
                .shimmering(active: shimmeringActive)
        }
        .foregroundColor(Color.primaryText)
    }

    @ViewBuilder func totalPriceView(formattedPrice: String?, shimmeringActive: Bool, redacted: Bool) -> some View {
        HStack(alignment: .top, spacing: .zero) {
            Text(Localization.total)
                .font(Constants.totalTitleFont)
                .fontWeight(.semibold)
            Spacer()
            Text(formattedPrice ?? "-----")
                .font(Constants.totalAmountFont)
                .redacted(reason: redacted ? [.placeholder] : [])
                .shimmering(active: shimmeringActive)
        }
        .foregroundColor(Color(UIColor.wooCommercePurple(.shade80)))
    }
}

private extension TotalsView {
    enum Constants {
        static let pricesIdealWidth: CGFloat = 380
        static let defaultBorderLineWidth: CGFloat = 1
        static let defaultBorderLineCornerRadius: CGFloat = 8

        static let totalsVerticalSpacing: CGFloat = 10
        static let totalsPadding: CGFloat = 50
        static let subtotalTitleFont: Font = Font.system(size: 20)
        static let subtotalAmountFont: Font = Font.system(size: 20)
        static let totalTitleFont: Font = Font.system(size: 21, weight: .semibold)
        static let totalAmountFont: Font = Font.system(size: 40, weight: .bold)

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
