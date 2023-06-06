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

    @State var isPurchasing = false

    init(viewModel: UpgradesViewModel, subscriptionsViewModel: SubscriptionsViewModel) {
        self.viewModel = viewModel
        self.subscriptionsViewModel = subscriptionsViewModel
    }

    var body: some View {
        List {
            Section {
                Text("\(Constants.planName)\(subscriptionsViewModel.planName)")
                Text("\(Constants.daysLeftInTrial)\(String(subscriptionsViewModel.planDaysLeft))")
            }
            Section {
                VStack {
                    Image(uiImage: .emptyOrdersImage)
                    // TODO: Move logic to viewmodel
                    if let availableProduct = viewModel.products.first(where: { $0.id == "debug.woocommerce.express.essential.monthly" }) {
                        Text("\(availableProduct.displayName)")
                            .font(.title)
                        Text("Everything you need to launch an online store")
                            .font(.body)
                        Text("\(availableProduct.displayPrice)")
                            .font(.title)
                    }
                }
            }
            Section {
                if viewModel.products.isEmpty || isPurchasing {
                    ActivityIndicator(isAnimating: .constant(true), style: .medium)
                } else {
                    ForEach(viewModel.products, id: \.id) { product in
                        // TODO: Move logic to viewmodel
                        if product.id == "debug.woocommerce.express.essential.monthly" {
                            Button("Purchase \(product.displayName)") {
                                // TODO: Add product entitlement check
                                Task {
                                    isPurchasing = true
                                    await viewModel.purchaseProduct(with: product.id)
                                    isPurchasing = false
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

private extension UpgradesView {
    struct Constants {
        static let planName = NSLocalizedString("Your Plan: ", comment: "")
        static let daysLeftInTrial = NSLocalizedString("Days left in trial: ", comment: "")
    }
}
