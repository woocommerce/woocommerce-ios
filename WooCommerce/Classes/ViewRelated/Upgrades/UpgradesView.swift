import Foundation
import SwiftUI

/// Hosting controller for `UpgradesView`
/// To be used to display available current plan Subscriptions, available plan Upgrades,
/// and the CTA to upgrade
///
@MainActor
final class UpgradesHostingController: UIHostingController<UpgradesView> {
    init(siteID: Int64) {
        let upgradesViewModel = UpgradesViewModel(siteID: siteID)
        let subscriptionsViewModel = SubscriptionsViewModel()

        super.init(rootView: UpgradesView(upgradesViewModel: upgradesViewModel,
                                          subscriptionsViewModel: subscriptionsViewModel))
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("Not implemented")
    }
}

struct UpgradesView: View {
    @ObservedObject var upgradesViewModel: UpgradesViewModel
    @ObservedObject var subscriptionsViewModel: SubscriptionsViewModel

    @State var isPurchasing = false

    init(upgradesViewModel: UpgradesViewModel, subscriptionsViewModel: SubscriptionsViewModel) {
        self.upgradesViewModel = upgradesViewModel
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
                    if let availableProduct = upgradesViewModel.retrievePlanDetailsIfAvailable(.essentialMonthly) {
                        Text(availableProduct.displayName)
                            .font(.title)
                        Text(Constants.upgradeSubtitle)
                            .font(.body)
                        Text(availableProduct.displayPrice)
                            .font(.title)
                    }
                }
            }
            Section {
                if upgradesViewModel.products.isEmpty || isPurchasing {
                    ActivityIndicator(isAnimating: .constant(true), style: .medium)
                } else {
                    ForEach(upgradesViewModel.products, id: \.id) { product in
                        Button("Purchase \(product.displayName)") {
                            // TODO: Add product entitlement check
                            Task {
                                isPurchasing = true
                                await upgradesViewModel.purchaseProduct(with: product.id)
                                isPurchasing = false
                            }
                        }
                    }
                }
            }
        }
        .task {
            await upgradesViewModel.loadProducts()
        }
        .navigationBarTitle("Plans")
        .navigationBarTitleDisplayMode(.large)
    }
}

private extension UpgradesView {
    struct Constants {
        static let planName = NSLocalizedString("Your Plan: ", comment: "")
        static let daysLeftInTrial = NSLocalizedString("Days left in trial: ", comment: "")
        static let upgradeSubtitle = NSLocalizedString("Everything you need to launch an online store",
                                                       comment: "")
    }
}
