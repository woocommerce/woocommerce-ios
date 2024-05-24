import SwiftUI

struct TotalsView: View {
    @ObservedObject private var viewModel: PointOfSaleDashboardViewModel

    init(viewModel: PointOfSaleDashboardViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack {
            Text("Totals")
                .font(.title)
                .foregroundColor(Color.white)
            ScrollView {
                ForEach(viewModel.productsInCart, id: \.product.productID) { cartProduct in
                    VStack {
                        HStack {
                            Text("\(cartProduct.quantity) x \(cartProduct.product.name) ")
                            Spacer()
                            Text("\(cartProduct.product.price)")
                        }
                    }
                    .foregroundColor(.white)
                }
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
