import Foundation
import SwiftUI

/// Hosting controller for `UpgradesView`
/// To be used to display available current plan Subscriptions, available plan Upgrades,
/// and the CTA to upgrade
///
@MainActor
final class UpgradesHostingController: UIHostingController<UpgradesView> {
    init(siteID: Int64) {
        let upgradesViewModel = UpgradesViewModel()
        let subscriptionsViewModel = SubscriptionsViewModel()

        super.init(rootView: UpgradesView(viewModel: upgradesViewModel,
                                          subscriptionsViewModel: subscriptionsViewModel))
    }

    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("Not implemented")
    }
}

struct UpgradesView: View {

    @ObservedObject var viewModel: UpgradesViewModel
    @ObservedObject var subscriptionsViewModel: SubscriptionsViewModel

    @State var isLoading = false
    @State var isPurchasing = false

    init(viewModel: UpgradesViewModel, subscriptionsViewModel: SubscriptionsViewModel) {
        self.viewModel = viewModel
        self.subscriptionsViewModel = subscriptionsViewModel
    }

    var body: some View {
        List {
            Section {
                Text("Your Plan: \(subscriptionsViewModel.planName)")
                Text("Days left in trial: \(String(subscriptionsViewModel.planDaysLeft))")
            }
            Section {
                VStack {
                    Image(uiImage: .emptyOrdersImage)
                    Text("Essential")
                        .font(.title)
                    Text("Everything you need to launch an online store")
                        .font(.body)
                    Text("$39")
                        .font(.title)
                }
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
        .navigationBarTitle("Plans")
        .navigationBarTitleDisplayMode(.large)
    }
}
