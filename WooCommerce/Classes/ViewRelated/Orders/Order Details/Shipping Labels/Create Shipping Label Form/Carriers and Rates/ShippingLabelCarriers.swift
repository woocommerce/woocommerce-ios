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
        ServiceLocator.analytics.track(.shippingLabelPurchaseFlow, withProperties: ["state": "carrier_rates_started"])
    }

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                LazyVStack {
                    switch viewModel.syncStatus {
                    case .loading:
                        ForEach(viewModel.ghostRows) { ghostRowVM in
                            ShippingLabelCarrierRow(ghostRowVM)
                                .padding(.horizontal, insets: geometry.safeAreaInsets)
                                .redacted(reason: .placeholder)
                                .shimmering()
                            Divider().padding(.leading, Constants.dividerPadding)
                        }
                    case .success:
                        let edgeInsets = EdgeInsets(top: 0, leading: geometry.safeAreaInsets.leading, bottom: 0, trailing: geometry.safeAreaInsets.trailing)
                        ShippingLabelCarrierAndRatesTopBanner(width: geometry.size.width,
                                                              edgeInsets: edgeInsets,
                                                              shippingMethod: viewModel.shippingMethod,
                                                              shippingCost: viewModel.shippingCost).renderedIf(viewModel.shouldDisplayTopBanner)
                        ForEach(viewModel.rows) { carrierRowVM in
                            ShippingLabelCarrierRow(carrierRowVM)
                            Divider().padding(.leading, Constants.dividerPadding)
                        }
                        .padding(.horizontal, insets: geometry.safeAreaInsets)
                    case .error:
                        VStack {
                            HStack (alignment: .center) {
                                EmptyState(title: Localization.emptyStateTitle,
                                           description: Localization.emptyStateDescription,
                                           image: .productErrorImage)
                                    .frame(width: geometry.size.width)
                            }
                        }
                        .padding(.horizontal, insets: geometry.safeAreaInsets)
                        .frame(minHeight: geometry.size.height)
                    default:
                        EmptyView()
                    }
                }
                .padding(.bottom, insets: geometry.safeAreaInsets)
            }
            .ignoresSafeArea(.container, edges: [.horizontal, .bottom])
            .navigationTitle(Localization.titleView)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(action: {
                        onCompletion(viewModel.getSelectedRates().selectedRate,
                                     viewModel.getSelectedRates().selectedSignatureRate,
                                     viewModel.getSelectedRates().selectedAdultSignatureRate)
                        ServiceLocator.analytics.track(.shippingLabelPurchaseFlow, withProperties: ["state": "carrier_rates_selected"])
                        presentation.wrappedValue.dismiss()
                    }, label: {
                        Text(Localization.doneButton)
                    })
                    .disabled(!viewModel.isDoneButtonEnabled())
                }
            }
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
        static let emptyStateTitle = NSLocalizedString("No shipping rates available",
                                                       comment: "Error state title in shipping label carrier and rates screen")
        static let emptyStateDescription = NSLocalizedString("Please double check your package dimensions and weight " +
                                                                "or try using a different package in Package Details.",
                                                             comment: "Error state description in shipping label carrier and rates screen")
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
