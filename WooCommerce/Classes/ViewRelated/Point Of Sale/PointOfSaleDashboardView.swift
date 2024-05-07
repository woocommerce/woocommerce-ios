import SwiftUI

// Potential separation between Items and Products, but keeping a common contract:
protocol POSItem: Hashable {
    var siteID: Int64 { get }
}

struct POSProduct: POSItem {
    let siteID: Int64
    let productID: Int64
    let name: String
    let price: String
}

struct POSProductListView: View {
    private var products: [POSProduct]

    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    init(products: [POSProduct]) {
        self.products = products
    }

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(products, id: \.self) { product in
                    POSProductView(product: product)
                }
            }
        }
    }
}

struct POSProductView: View {
    var product: POSProduct

    init(product: POSProduct) {
        self.product = product
    }

    var body: some View {
        VStack {
            Text(product.name)
            Text(product.price)
        }
        .padding()
        .background(Color.cyan)
    }
}

final class PointOfSaleDashboardViewModel: ObservableObject {
    // Another option is to inject the product data here, and use the adapter to transform from productData to productList (POS-specific)
    // private let productData: [Data]
    @Published private(set) var productList: [POSProduct]

    init() {
        self.productList = []
    }

    func setup() {
        productList = POSProductAdapter.makePOSProductList()
    }
}

struct PointOfSaleDashboardView: View {
    @ObservedObject private var viewModel: PointOfSaleDashboardViewModel

    init(viewModel: PointOfSaleDashboardViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack {
            Text("WooCommerce Point Of Sale")
            POSProductListView(products: viewModel.productList)
        }
        .onAppear(perform: {
            viewModel.setup()
        })
    }
}
