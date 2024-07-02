import SwiftUI

struct TotalsView: View {
    @ObservedObject private var viewModel: PointOfSaleDashboardViewModel
    @ObservedObject private var totalsViewModel: TotalsViewModel

    init(viewModel: PointOfSaleDashboardViewModel, totalsViewModel: TotalsViewModel) {
        self.viewModel = viewModel
        self.totalsViewModel = totalsViewModel
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                VStack {
                    cardReaderView
                        .font(.title)
                        .padding()
                    Spacer()
                    VStack(alignment: .leading, spacing: 32) {
                        HStack {
                            VStack(spacing: Constants.totalsVerticalSpacing) {
                                priceFieldView(title: "Subtotal",
                                               formattedPrice: totalsViewModel.formattedCartTotalPrice,
                                               shimmeringActive: false,
                                               redacted: false)
                                Divider()
                                    .overlay(Color.posTotalsSeparator)
                                priceFieldView(title: "Taxes",
                                               formattedPrice:
                                                totalsViewModel.formattedOrderTotalTaxPrice,
                                               shimmeringActive: totalsViewModel.isShimmering,
                                               redacted: totalsViewModel.isPriceFieldRedacted)
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
                            Button("Calculate amounts") {
                                totalsViewModel.calculateAmountsTapped(
                                    with: viewModel.cartViewModel.itemsInCart,
                                    allItems: viewModel.itemSelectorViewModel.items)
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
                Text("New transaction")
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
                Text("Reader connected")
                Button(action: totalsViewModel.cardPaymentTapped) {
                    Text("Collect Payment")
                }
            }
        case .disconnected:
            Text("Reader disconnected")
            Button(action: totalsViewModel.cardPaymentTapped) {
                Text("Collect Payment")
            }
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
            Text("Total")
                .font(Constants.totalTitleFont)
                .fontWeight(.semibold)
            Spacer()
            Text(formattedPrice ?? "-----")
                .font(Constants.totalAmountFont)
                .redacted(reason: redacted ? [.placeholder] : [])
                .shimmering(active: shimmeringActive)
        }
        .foregroundColor(Color.primaryText)
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
}

#if DEBUG
#Preview {
    TotalsView(viewModel: .init(itemProvider: POSItemProviderPreview(),
                                cardPresentPaymentService: CardPresentPaymentPreviewService(),
                                orderService: POSOrderPreviewService(),
                                currencyFormatter: .init(currencySettings: .init())),
               totalsViewModel: .init(orderService: POSOrderPreviewService(),
                                      cardPresentPaymentService: CardPresentPaymentPreviewService(),
                                      currencyFormatter: .init(currencySettings: .init())))
}
#endif
