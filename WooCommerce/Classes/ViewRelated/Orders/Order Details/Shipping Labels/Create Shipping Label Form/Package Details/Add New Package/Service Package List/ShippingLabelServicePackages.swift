import SwiftUI
import Yosemite

struct ShippingLabelServicePackages: View {
    private let viewModel = ShippingLabelServicePackagesViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                ListHeaderView(text: "Set up the package you'll be using to ship your products. We'll save it for future orders.", alignment: .left)
                    .background(Color(.listBackground))
            }
        }
    }

    init(state: ShippingLabelAddNewPackageViewModel.State, predefinedOptions: [ShippingLabelPredefinedOption]) {

    }
}

struct ShippingLabelServicePackages_Previews: PreviewProvider {
    static var previews: some View {
        ShippingLabelServicePackages(state: .results, predefinedOptions: [])
    }
}
