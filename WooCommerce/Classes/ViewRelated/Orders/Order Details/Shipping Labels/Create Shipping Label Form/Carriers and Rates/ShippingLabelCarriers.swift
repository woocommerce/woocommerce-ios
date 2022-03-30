import SwiftUI
import Yosemite
import Shimmer

struct ShippingLabelCarriers: View {

    @ObservedObject private var viewModel: ShippingLabelCarriersViewModel
    @Environment(\.presentationMode) var presentation

    /// Completion callback
    ///
    typealias Completion = ([ShippingLabelSelectedRate]) -> Void
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
                        ForEach(Array(viewModel.sections.enumerated()), id: \.offset) { index, sectionVM in
                            ShippingLabelCarriersSection(section: sectionVM, safeAreaInsets: geometry.safeAreaInsets)
                                .background(Color(.listForeground))
                            Spacer().frame(height: Constants.spaceBetweenSections)
                        }
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
            .background(Color(.listBackground))
            .ignoresSafeArea(.container, edges: [.horizontal, .bottom])
            .navigationTitle(Localization.titleView)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(action: {
                        onCompletion(viewModel.getSelectedRates())
                        ServiceLocator.analytics.track(.shippingLabelPurchaseFlow, withProperties: ["state": "carrier_rates_selected"])
                        presentation.wrappedValue.dismiss()
                    }, label: {
                        Text(Localization.doneButton)
                    })
                    .disabled(!viewModel.isDoneButtonEnabled())
                }
            }
            .wooNavigationBarStyle()
        }
    }

    enum Constants {
        static let spaceBetweenSections: CGFloat = 16
        static let dividerPadding: CGFloat = 80
    }

    private struct ShippingLabelCarriersSection: View {
        let section: ShippingLabelCarriersSectionViewModel
        @State private var isCollapsed: Bool = false
        let safeAreaInsets: EdgeInsets

        var body: some View {
            CollapsibleView(isCollapsible: true,
                            isCollapsed: $isCollapsed,
                            safeAreaInsets: safeAreaInsets) {
                ShippingLabelCarrierSectionHeader(packageNumber: section.packageNumber)
            } content: {
                ForEach(section.rows) { rowVM in
                    ShippingLabelCarrierRow(rowVM)
                        .padding(.horizontal, insets: safeAreaInsets)

                    // The separator will be added only if the element is not the last one of the list
                    if section.rows.last != rowVM {
                        Divider().padding(.leading, Constants.dividerPadding)
                    }
                }
            }
        }
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

#if DEBUG
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

        let vm = ShippingLabelCarriersViewModel(order: ShippingLabelSampleData.sampleOrder(),
                                                originAddress: shippingAddress,
                                                destinationAddress: shippingAddress,
                                                packages: [])
        ShippingLabelCarriers(viewModel: vm) { (_) in
        }
    }
}
#endif
