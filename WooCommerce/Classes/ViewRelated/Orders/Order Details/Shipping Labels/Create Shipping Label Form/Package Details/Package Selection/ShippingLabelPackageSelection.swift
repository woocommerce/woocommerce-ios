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
                                                             selectedPackages: [],
                                                             onPackageSyncCompletion: { _ in },
                                                             onPackageSaveCompletion: { _ in })
        let viewModelWithoutPackages = ShippingLabelPackageDetailsViewModel(order: ShippingLabelPackageDetailsViewModel.sampleOrder(),
                                                             packagesResponse: nil,
                                                             selectedPackages: [],
                                                             onPackageSyncCompletion: { _ in },
                                                             onPackageSaveCompletion: { _ in })

        ShippingLabelPackageSelection(viewModel: viewModelWithPackages)

        ShippingLabelPackageSelection(viewModel: viewModelWithoutPackages)
    }
}
