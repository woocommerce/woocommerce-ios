import SwiftUI
import Yosemite

struct ShippingLabelCarriersAndRates: View {

    @ObservedObject private var viewModel: ShippingLabelCarriersAndRatesViewModel

    init(viewModel: ShippingLabelCarriersAndRatesViewModel) {
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
    }

    enum Constants {
        static let dividerPadding: CGFloat = 80
    }
}

struct ShippingLabelCarriersAndRates_Previews: PreviewProvider {
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

        let vm = ShippingLabelCarriersAndRatesViewModel(order: ShippingLabelPackageDetailsViewModel.sampleOrder(),
                                                        originAddress: shippingAddress,
                                                        destinationAddress: shippingAddress,
                                                        packages: [])
        ShippingLabelCarriersAndRates(viewModel: vm)
    }
}
