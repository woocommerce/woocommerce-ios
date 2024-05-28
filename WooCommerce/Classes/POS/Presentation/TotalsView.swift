import SwiftUI

struct TotalsView: View {
    @ObservedObject private var viewModel: PointOfSaleDashboardViewModel

    init(viewModel: PointOfSaleDashboardViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack {
            VStack(alignment: .leading, spacing: 32) {
                HStack {
                    priceFieldView(title: "Subtotal", formattedPrice: viewModel.formattedCartTotalPrice ?? "-")
                    priceFieldView(title: "Taxes", formattedPrice: "$0.60")
                }
                totalPriceView(formattedPrice: "$6.59")
            }
            Spacer()
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
    }
}

private extension TotalsView {
    @ViewBuilder func priceFieldView(title: String, formattedPrice: String) -> some View {
        VStack(alignment: .leading, spacing: .zero) {
            Text(title)
            Text(formattedPrice)
        }
    }

    @ViewBuilder func totalPriceView(formattedPrice: String) -> some View {
        VStack(alignment: .leading, spacing: .zero) {
            Text("Total")
                .bold()
            Text(formattedPrice)
                .font(.title)
        }
    }
}

#if DEBUG
#Preview {
    TotalsView(viewModel: .init(products: [],
                                cardReaderConnectionViewModel: .init(state: .connectingToReader),
                                currencySettings: .init()))
}
#endif
