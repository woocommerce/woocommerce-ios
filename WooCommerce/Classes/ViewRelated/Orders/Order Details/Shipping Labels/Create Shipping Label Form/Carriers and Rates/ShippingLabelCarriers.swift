import SwiftUI
import Yosemite

struct ShippingLabelCarriers: View {

    @ObservedObject private var viewModel: ShippingLabelCarriersViewModel

    init(viewModel: ShippingLabelCarriersViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        ScrollView {
            LazyVStack {
                switch viewModel.syncStatus {
                case .loading:
                    ForEach(viewModel.ghostRows) { ghostRow in
                        ghostRow
                            .redacted(reason: .placeholder)
                            .shimmering()
                        Divider().padding(.leading, Constants.dividerPadding)
                    }
                case .success:
                    ForEach(viewModel.rows) { carrierRow in
                        carrierRow
                        Divider().padding(.leading, Constants.dividerPadding)
                    }
                default:
                    EmptyView()
                }
            }
        }
        .navigationTitle(Localization.titleView)
    }

    enum Constants {
        static let dividerPadding: CGFloat = 80
    }
}

private extension ShippingLabelCarriers {
    enum Localization {
        static let titleView = NSLocalizedString("Carrier and Rates",

                                                 comment: "Navigation bar title of shipping label carrier and rates screen")
    }
}

struct ShippingLabelCarriers_Previews: PreviewProvider {
    static var previews: some View {

        let shippingAddress = ShippingLabelAddress(company: "Automattic Inc.",

                                                   name: "Paolo",
                                                   phone: "01234567",
                                                   country: "USA",
                                                   state: "CA",
                                                   address1: "Woo Street",
                                                   address2: "",
                                                   city: "San Francisco",
                                                   postcode: "90210")

        let vm = ShippingLabelCarriersViewModel(order: ShippingLabelPackageDetailsViewModel.sampleOrder(),
                                                        originAddress: shippingAddress,
                                                        destinationAddress: shippingAddress,
                                                        packages: [])
        ShippingLabelCarriers(viewModel: vm)
    }
}
