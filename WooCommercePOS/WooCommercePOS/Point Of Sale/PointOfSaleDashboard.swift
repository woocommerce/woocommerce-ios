import SwiftUI
import class Yosemite.StorageProduct
import struct Yosemite.Product
import enum Yosemite.ProductAction

final class PointOfSaleDashboardViewModel: ObservableObject {
    @Published private(set) var isSyncing: Bool = false

    private let dependencies: PointOfSaleDependencies

    init(dependencies: PointOfSaleDependencies) {
        self.dependencies = dependencies
        syncProducts()
    }
}

extension PointOfSaleDashboardViewModel {
    func syncProducts() {
        isSyncing = true
        dependencies.stores.dispatch(ProductAction.synchronizeProducts(siteID: dependencies.siteID,
                                                                       pageNumber: 1,
                                                                       pageSize: 20,
                                                                       stockStatus: nil,
                                                                       productStatus: nil,
                                                                       productType: .simple,
                                                                       productCategory: nil,
                                                                       sortOrder: .nameAscending,
                                                                       excludedProductIDs: [],
                                                                       shouldDeleteStoredProductsOnFirstPage: true,
                                                                       onCompletion: { [weak self] result in
            guard let self else { return }
            isSyncing = false
        }))
    }
}

extension Product: Identifiable {
    public var id: Int64 {
        productID
    }
}

struct PointOfSaleDashboard: View {
    @StateObject private var viewModel: PointOfSaleDashboardViewModel

    // SwiftUI equivalent of NSFetchedResultsController in UIKit table view
    @FetchRequest(sortDescriptors: [SortDescriptor(\.name, order: .forward)])
    private var products: FetchedResults<StorageProduct>

    init(viewModel: PointOfSaleDashboardViewModel) {
        self._viewModel = .init(wrappedValue: viewModel)
    }

    var body: some View {
        VStack {
            if viewModel.isSyncing {
                ProgressView()
            }

            List(products.map { $0.toReadOnly() }) { product in
                HStack {
                    Text(product.name)
                    Spacer()
                    Text(product.price)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle("WooCommerce Point Of Sale")
        .refreshable {
            viewModel.syncProducts()
        }
    }
}
