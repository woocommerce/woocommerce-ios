import SwiftUI
import WooFoundation // currencyformatter
import Yosemite

final class TotalsViewModel: ObservableObject {
    @Published private(set) var isSyncingOrder: Bool = false
    
    func doSync() {
        isSyncingOrder = true
    }
    
    func stopSync() {
        isSyncingOrder = false
    }

    /// Order created the first time the checkout is shown for a given transaction.
    /// If the merchant goes back to the product selection screen and makes changes, this should be updated when they return to the checkout.
    @Published private var order: POSOrder?

    var areAmountsFullyCalculated: Bool {
        isSyncingOrder == false &&
        formattedOrderTotalTaxPrice != nil &&
        formattedOrderTotalPrice != nil
    }

    var formattedOrderTotalTaxPrice: String? {
        formattedPrice(order?.totalTax, currency: order?.currency)
    }

    private func formattedPrice(_ price: String?, currency: String?) -> String? {
        guard let price, let currency else {
            return nil
        }
        // TODO: CurrencySettings dependency
        guard let formattedPrice = CurrencyFormatter(currencySettings: ServiceLocator.currencySettings).formatAmount(price, with: currency) else {
            return nil
        }
        return formattedPrice
    }

    var formattedOrderTotalPrice: String? {
        return formattedPrice(order?.total, currency: order?.currency)
    }

    var showRecalculateButton: Bool {
        return !areAmountsFullyCalculated && isSyncingOrder == false
    }
}

struct TotalsView: View {
    @ObservedObject private var dashboardViewModel: PointOfSaleDashboardViewModel
    @ObservedObject private var totalsViewModel: TotalsViewModel

    init(dashboardViewModel: PointOfSaleDashboardViewModel, totalsViewModel: TotalsViewModel) {
        self.dashboardViewModel = dashboardViewModel
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
                                               // Relies on Cart and itemsInCart
                                               formattedPrice: dashboardViewModel.formattedCartTotalPrice,
                                               shimmeringActive: false,
                                               redacted: false)
                                Divider()
                                    .overlay(Color.posTotalsSeparator)
                                priceFieldView(title: "Taxes",
                                               formattedPrice:
                                                totalsViewModel.formattedOrderTotalTaxPrice,
                                               shimmeringActive: totalsViewModel.isSyncingOrder,
                                               redacted: totalsViewModel.formattedOrderTotalTaxPrice == nil || totalsViewModel.isSyncingOrder)
                                Divider()
                                    .overlay(Color.posTotalsSeparator)
                                totalPriceView(formattedPrice: totalsViewModel.formattedOrderTotalPrice,
                                               shimmeringActive: totalsViewModel.isSyncingOrder,
                                               redacted: totalsViewModel.formattedOrderTotalPrice == nil || totalsViewModel.isSyncingOrder)
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
                                // Relies on syncing the order
                                dashboardViewModel.calculateAmountsTapped()
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
            // Relies on CardPresentService
            dashboardViewModel.onTotalsViewDisappearance()
        }
    }

    private var gradientStops: [Gradient.Stop] {
        // Relies on CardPresentService
        if dashboardViewModel.paymentState == .cardPaymentSuccessful {
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

    private var paymentButtonsDisabled: Bool {
        return !totalsViewModel.areAmountsFullyCalculated
    }
}

private extension TotalsView {
    private var newTransactionButton: some View {
        Button(action: {
            dashboardViewModel.startNewTransaction()
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
        if dashboardViewModel.paymentState == .cardPaymentSuccessful {
            newTransactionButton
        }
        else {
            EmptyView()
        }
    }

    @ViewBuilder private var cardReaderView: some View {
        switch dashboardViewModel.cardReaderConnectionViewModel.connectionStatus {
        case .connected:
            if let inlinePaymentMessage = dashboardViewModel.cardPresentPaymentInlineMessage {
                PointOfSaleCardPresentPaymentInLineMessage(messageType: inlinePaymentMessage)
            } else {
                Text("Reader connected")
                Button(action: dashboardViewModel.cardPaymentTapped) {
                    Text("Collect Payment")
                }
            }
        case .disconnected:
            Text("Reader disconnected")
            Button(action: dashboardViewModel.cardPaymentTapped) {
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

//#if DEBUG
//#Preview {
//    TotalsView(viewModel: .init(itemProvider: POSItemProviderPreview(),
//                                cardPresentPaymentService: CardPresentPaymentPreviewService(),
//                                orderService: POSOrderPreviewService()))
//}
//#endif
