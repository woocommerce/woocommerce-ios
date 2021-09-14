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
    }
}

struct ShippingLabelPackageSelection_Previews: PreviewProvider {
    static var previews: some View {
        let viewModelWithPackages = ShippingLabelPackageListViewModel(packagesResponse: ShippingLabelPackageDetailsViewModel.samplePackageDetails())
        let viewModelWithoutPackages = ShippingLabelPackageListViewModel(packagesResponse: nil)

        ShippingLabelPackageSelection(viewModel: viewModelWithPackages)
        ShippingLabelPackageSelection(viewModel: viewModelWithoutPackages)
    }
}
