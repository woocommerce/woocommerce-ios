import SwiftUI

struct ShippingLabelAddNewPackage: View {
    @ObservedObject private var viewModel: ShippingLabelAddNewPackageViewModel

    var body: some View {
        ScrollView {
            let servicePackagesViewModel = ShippingLabelServicePackagesViewModel(state: viewModel.state, packagesResponse: viewModel.packagesResponse)
            ShippingLabelServicePackages(viewModel: servicePackagesViewModel)
                .background(Color(.systemBackground))
        }
        .background(Color(.listBackground))
        .navigationBarTitle(Text(Localization.title), displayMode: .inline)
    }

    init(siteID: Int64) {
        viewModel = ShippingLabelAddNewPackageViewModel(siteID: siteID)
    }
}

private extension ShippingLabelAddNewPackage {
    enum Localization {
        static let title = NSLocalizedString("Add New Package", comment: "Add New Package screen title in Shipping Label flow")
    }
}

struct ShippingLabelAddNewPackage_Previews: PreviewProvider {
    static var previews: some View {
        ShippingLabelAddNewPackage(siteID: 1234)
    }
}
