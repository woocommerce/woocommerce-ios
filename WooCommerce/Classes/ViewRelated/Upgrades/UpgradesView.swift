import Foundation
import SwiftUI

/// Hosting controller for `UpgradesView`
/// To be used to display available plan Upgrades and the CTA to upgrade them
///
@MainActor
final class UpgradesHostingController: UIHostingController<UpgradesView> {
    init(siteID: Int64) {
        let upgradesViewModel = UpgradesViewModel()
        super.init(rootView: UpgradesView(viewModel: upgradesViewModel))
    }

    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("Not implemented")
    }
}

struct UpgradesView: View {

    @ObservedObject var viewModel: UpgradesViewModel

    @State var isLoading = false
    @State var isPurchasing = false

    init(viewModel: UpgradesViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        List {
            Section {
                Text("Upgrades view")
            }
            Section {
                Text("Plan details")
            }
            Section {
                if viewModel.products.isEmpty {
                    ActivityIndicator(isAnimating: .constant(true), style: .medium)
                } else {
                    ForEach(viewModel.products, id: \.id) { product in
                        if product.id == "debug.woocommerce.ecommerce.monthly" {
                            Button("Purchase \(product.displayName)") {
                                // TODO: Add product entitlement check
                                Task {
                                    await viewModel.purchaseProduct(with: product.id)
                                }                                
                            }
                        }
                    }
                }
            }
        }
        .task {
            await viewModel.loadProducts()
        }
    }
}
