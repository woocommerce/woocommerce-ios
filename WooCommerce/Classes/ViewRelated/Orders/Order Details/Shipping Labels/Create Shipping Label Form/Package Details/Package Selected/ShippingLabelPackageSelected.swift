import SwiftUI

struct ShippingLabelPackageSelected: View {
    @ObservedObject private var viewModel: ShippingLabelPackageSelectedViewModel

    var body: some View {
        ScrollView {
            let servicePackagesViewModel = ShippingLabelPackageListViewModel(state: viewModel.state, packagesResponse: viewModel.packagesResponse)
            ShippingLabelPackageList(viewModel: servicePackagesViewModel)
                .background(Color(.systemBackground))
        }
        .background(Color(.listBackground))
        .navigationBarTitle(Text(Localization.title), displayMode: .inline)
    }

    init(siteID: Int64) {
        viewModel = ShippingLabelPackageSelectedViewModel(siteID: siteID)
    }
}

private extension ShippingLabelPackageSelected {
    enum Localization {
        static let title = NSLocalizedString("Package Selected", comment: "Package Selected screen title in Shipping Label flow")
    }
}

struct ShippingLabelAddNewPackage_Previews: PreviewProvider {
    static var previews: some View {
        ShippingLabelPackageSelected(siteID: 1234)
    }
}
