import SwiftUI

struct ShippingLabelPackageSelection: View {
    @ObservedObject var viewModel: ShippingLabelPackageListViewModel

    var body: some View {
        NavigationView {
            if viewModel.hasCustomOrPredefinedPackages {
                ShippingLabelPackageList(viewModel: viewModel)
            } else {
                ShippingLabelAddNewPackage(viewModel: viewModel.addNewPackageViewModel)
            }
        }
        .wooNavigationBarStyle()
    }
}

struct ShippingLabelPackageSelection_Previews: PreviewProvider {
    static var previews: some View {
        let viewModelWithPackages = ShippingLabelPackageListViewModel(siteID: 123,
                                                                      packagesResponse: ShippingLabelPackageDetailsViewModel.samplePackageDetails())
        let viewModelWithoutPackages = ShippingLabelPackageListViewModel(siteID: 123, packagesResponse: nil)

        ShippingLabelPackageSelection(viewModel: viewModelWithPackages)
        ShippingLabelPackageSelection(viewModel: viewModelWithoutPackages)
    }
}
