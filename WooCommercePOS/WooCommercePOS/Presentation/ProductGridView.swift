import SwiftUI

struct PlusButtonView: View {

    private var buttonTapped: (() -> Void)?

    init(buttonTapped: (() -> Void)? = nil) {
        self.buttonTapped = buttonTapped
    }

    var body: some View {
        Button(action: {
            buttonTapped?()
        }) {
            Image(systemName: "plus")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 50, height: 50)
                .background(Circle().fill(Color.clear))
        }
    }
}

struct QuantityBadgeView: View {
    var body: some View {
        Text("2")
    }
}

struct ProductCardView: View {

    private let product: Product
    private var onProductCardTapped: (() -> Void)?

    init(product: Product, onProductCardTapped: (() -> Void)? = nil) {
        self.product = product
        self.onProductCardTapped = onProductCardTapped
    }

    var body: some View {
        Rectangle()
            .fill(.blue)
            .frame(minWidth: 200, maxWidth: .infinity, minHeight: 200)
            .aspectRatio(1, contentMode: .fit)
            .overlay {
                VStack {
                    Text(product.name)
                        .foregroundStyle(Color.cyan)
                    Text(product.price)
                        .foregroundStyle(Color.cyan)
                    HStack {
                        QuantityBadgeView()
                        PlusButtonView {
                            onProductCardTapped?()
                        }
                    }
                }
            }
    }
}

struct ProductGridView: View {
    @ObservedObject var viewModel: PointOfSaleDashboardViewModel

    init(viewModel: PointOfSaleDashboardViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        let columns: [GridItem] = Array(repeating: .init(.flexible()),
                                        count: viewModel.products.count)

        ScrollView {
            LazyVGrid(columns: columns, spacing: 20) {
                ForEach(viewModel.products, id: \.productID) { product in
                    ProductCardView(product: product)
                }
            }
        }
    }
}

#Preview {
    ProductGridView(viewModel: PointOfSaleDashboardViewModel(products: ProductFactory.makeFakeProducts()))
}
