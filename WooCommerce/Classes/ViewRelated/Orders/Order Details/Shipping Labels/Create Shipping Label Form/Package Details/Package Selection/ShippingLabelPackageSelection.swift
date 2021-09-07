import SwiftUI

struct ShippingLabelPackageSelection: View {
    @ObservedObject var viewModel: ShippingLabelPackageDetailsViewModel

    var body: some View {
        NavigationView {
            if viewModel.hasCustomOrPredefinedPackages {
                ShippingLabelPackageList(viewModel: viewModel)
            } else {
                ShippingLabelAddNewPackage(viewModel: viewModel.addNewPackageViewModel)
            }
        }
    }
}

struct ShippingLabelPackageSelection_Previews: PreviewProvider {
    static var previews: some View {
        let viewModelWithPackages = ShippingLabelPackageDetailsViewModel(order: ShippingLabelPackageDetailsViewModel.sampleOrder(),
                                                             packagesResponse: ShippingLabelPackageDetailsViewModel.samplePackageDetails(),
                                                             selectedPackageID: nil,
                                                             totalWeight: nil)
        let viewModelWithoutPackages = ShippingLabelPackageDetailsViewModel(order: ShippingLabelPackageDetailsViewModel.sampleOrder(),
                                                             packagesResponse: nil,
                                                             selectedPackageID: nil,
                                                             totalWeight: nil)

        ShippingLabelPackageSelection(viewModel: viewModelWithPackages)

        ShippingLabelPackageSelection(viewModel: viewModelWithoutPackages)
    }
}
