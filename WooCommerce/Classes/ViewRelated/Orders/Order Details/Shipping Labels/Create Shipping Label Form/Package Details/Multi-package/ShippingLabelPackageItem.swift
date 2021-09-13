import SwiftUI

struct ShippingLabelPackageItem: View {

    @ObservedObject private var viewModel: ShippingLabelPackageItemViewModel
    @State private var isCollapsed: Bool = false
    @State private var isShowingPackageSelection = false

    private let isCollapsible: Bool
    private let packageNumber: Int
    private let safeAreaInsets: EdgeInsets

    init(packageNumber: Int,
         isCollapsible: Bool,
         safeAreaInsets: EdgeInsets,
         viewModel: ShippingLabelPackageItemViewModel) {
        self.packageNumber = packageNumber
        self.isCollapsible = isCollapsible
        self.safeAreaInsets = safeAreaInsets
        self.viewModel = viewModel
        self.isCollapsed = packageNumber > 1
    }

    var body: some View {
        CollapsibleView(isCollapsible: isCollapsible, isCollapsed: $isCollapsed, safeAreaInsets: safeAreaInsets) {
            // TODO-4599 - Update view
            ShippingLabelPackageNumberRow(packageNumber: packageNumber, numberOfItems: 1)
        } content: {
            // TODO-4599 - Update view
            EmptyView()
        }
    }
}

struct ShippingLabelPackageItem_Previews: PreviewProvider {
    static var previews: some View {
        let order = ShippingLabelPackageDetailsViewModel.sampleOrder()
        let packageResponse = ShippingLabelPackageDetailsViewModel.samplePackageDetails()
        let viewModel = ShippingLabelPackageItemViewModel(order: order,
                                                          orderItems: order.items,
                                                          packagesResponse: packageResponse,
                                                          selectedPackageID: "Box 1",
                                                          totalWeight: "",
                                                          products: [],
                                                          productVariations: [])
        ShippingLabelPackageItem(packageNumber: 1, isCollapsible: true, safeAreaInsets: .zero, viewModel: viewModel)
    }
}
