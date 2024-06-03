import SwiftUI

struct TotalsView: View {
    @ObservedObject private var viewModel: PointOfSaleDashboardViewModel

    init(viewModel: PointOfSaleDashboardViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack(alignment: .leading) {
            VStack(alignment: .leading, spacing: 32) {
                HStack(spacing: 40) {
                    priceFieldView(title: "Subtotal", formattedPrice: viewModel.formattedCartTotalPrice ?? "-")
                    priceFieldView(title: "Taxes", formattedPrice: viewModel.formattedOrderTotalTaxPrice ?? "-")
                }
                totalPriceView(formattedPrice: viewModel.formattedOrderTotalPrice ?? "-")
            }
            .padding()
            Spacer()
            cardReaderView
                .padding()
            Spacer()
            paymentsView
                .padding()
        }
    }
}

private extension TotalsView {
    private var paymentsView: some View {
        HStack {
            Button("Take payment") { debugPrint("Not implemented") }
                .padding(.all, 10)
                .frame(maxWidth: .infinity, idealHeight: 120)
                .font(.title)
                .foregroundColor(Color.white)
                .border(.white, width: 2)
            Button("Cash") { debugPrint("Not implemented") }
                .padding(.all, 10)
                .frame(maxWidth: .infinity, idealHeight: 120)
                .font(.title)
                .foregroundColor(Color.primaryBackground)
                .background(Color.white)
            Button("Card") { debugPrint("Not implemented") }
                .padding(.all, 10)
                .frame(maxWidth: .infinity, idealHeight: 120)
                .font(.title)
                .foregroundColor(Color.primaryBackground)
                .background(Color.white)
        }
    }

    private var cardReaderView: some View {
        Text("Card reader status placeholder view")
    }

    @ViewBuilder func priceFieldView(title: String, formattedPrice: String) -> some View {
        VStack(alignment: .leading, spacing: .zero) {
            Text(title)
            Text(formattedPrice)
                .font(.title2)
                .fontWeight(.medium)
        }
    }

    @ViewBuilder func totalPriceView(formattedPrice: String) -> some View {
        VStack(alignment: .leading, spacing: .zero) {
            Text("Total")
                .font(.title2)
                .fontWeight(.medium)
            Text(formattedPrice)
                .font(.largeTitle)
                .bold()
        }
    }
}

#if DEBUG
#Preview {
    TotalsView(viewModel: .init(items: [],
                                currencySettings: .init(),
                                cardPresentPaymentService: CardPresentPaymentService(siteID: 0)))
}
#endif
