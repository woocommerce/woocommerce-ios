import SwiftUI
import Yosemite
import Shimmer

struct ShippingLabelCarriers: View {

    @ObservedObject private var viewModel: ShippingLabelCarriersViewModel
    @Environment(\.presentationMode) var presentation

    /// Completion callback
    ///
    typealias Completion = (_ selectedRate: ShippingLabelCarrierRate?,

                            _ selectedSignatureRate: ShippingLabelCarrierRate?,

                            _ selectedAdultSignatureRate: ShippingLabelCarrierRate?) -> Void
    private let onCompletion: Completion

    init(viewModel: ShippingLabelCarriersViewModel,
         completion: @escaping Completion) {
        self.viewModel = viewModel
        onCompletion = completion
    }

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                ShippingLabelCarrierAndRatesTopBanner(width: geometry.size.width)
                LazyVStack {
                    switch viewModel.syncStatus {
                    case .loading:
                        ForEach(viewModel.ghostRows) { ghostRowVM in
                            ShippingLabelCarrierRow(ghostRowVM)
                                .redacted(reason: .placeholder)
                                .shimmering()
                            Divider().padding(.leading, Constants.dividerPadding)
                        }
                    case .success:
                        ForEach(viewModel.rows) { carrierRowVM in
                            ShippingLabelCarrierRow(carrierRowVM)
                            Divider().padding(.leading, Constants.dividerPadding)
                        }
                    default:
                        EmptyView()
                    }
                }
            }
            .navigationTitle(Localization.titleView)
            .navigationBarItems(trailing: Button(action: {
                onCompletion(viewModel.getSelectedRates().selectedRate,
                             viewModel.getSelectedRates().selectedSignatureRate,
                             viewModel.getSelectedRates().selectedAdultSignatureRate)
                presentation.wrappedValue.dismiss()
            }, label: {
                Text(Localization.doneButton)
            })
            .disabled(!viewModel.isDoneButtonEnabled()))
        }
    }

    enum Constants {
        static let dividerPadding: CGFloat = 80
    }
}

private extension ShippingLabelCarriers {
    enum Localization {
        static let titleView = NSLocalizedString("Carrier and Rates",

                                                 comment: "Navigation bar title of shipping label carrier and rates screen")
        static let doneButton = NSLocalizedString("Done", comment: "Done navigation button in shipping label carrier and rates screen")
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
        ShippingLabelCarriers(viewModel: vm) { (_, _, _) in
        }
    }
}
