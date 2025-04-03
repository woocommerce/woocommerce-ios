import SwiftUI

struct WooShippingShipmentDetailsView: View {
    @ObservedObject private var viewModel: WooShippingShipmentDetailsViewModel

    init(viewModel: WooShippingShipmentDetailsViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack(spacing: Layout.verticalSpacing) {
            if viewModel.canViewLabel, let postPurchase = viewModel.postPurchase {
                WooShippingPostPurchaseView(viewModel: postPurchase)
            }

            WooShippingItems(itemsCountLabel: viewModel.itemsCountLabel,
                             itemsDetailLabel: viewModel.itemsDetailLabel,
                             items: viewModel.itemsRowViewModels)

            WooShippingHazmatRow(selectedCategory: $viewModel.hazmatCategory,
                                 enabled: !viewModel.canViewLabel)

            WooShippingCustomsRow(informationIsCompleted: viewModel.customsInformationIsCompleted,
                                  customsFormViewModel: viewModel.customsFormViewModel)
                .padding(.bottom, Layout.contentSpacing)
                .renderedIf(viewModel.customsFormRequired)

            if viewModel.canViewLabel {
                EmptyView()
            } else if let package = viewModel.selectedPackage,
                      let shippingService = viewModel.shippingService {
                WooShippingSelectedPackageView(package: package,
                                               totalWeight: $viewModel.shipmentWeight,
                                               updateSelectedPackage: viewModel.selectPackage)
                WooShippingServiceView(viewModel: shippingService)
            } else {
                WooShippingPackageAndRatePlaceholder(onSelectPackage: viewModel.selectPackage)
            }
        }
    }
}

private extension WooShippingShipmentDetailsView {
    enum Layout {
        static let verticalSpacing: CGFloat = 8
        static let contentSpacing: CGFloat = 16
    }
}
