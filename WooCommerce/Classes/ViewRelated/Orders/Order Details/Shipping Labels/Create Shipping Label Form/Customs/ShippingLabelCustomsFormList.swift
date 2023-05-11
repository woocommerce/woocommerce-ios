import SwiftUI
import Yosemite

final class ShippingCustomsFormListHostingController: UIHostingController<ShippingLabelCustomsFormList> {
    init(order: Order,
         customsForms: [ShippingLabelCustomsForm],
         destinationCountry: Country,
         countries: [Country],
         onCompletion: @escaping ([ShippingLabelCustomsForm]) -> Void,
         shouldDisplayShippingNotice: Bool = false) {
        let viewModel = ShippingLabelCustomsFormListViewModel(order: order,
                                                              customsForms: customsForms,
                                                              destinationCountry: destinationCountry,
                                                              countries: countries)
        super.init(rootView: .init(viewModel: viewModel, onCompletion: onCompletion))
    }

    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

struct ShippingLabelCustomsFormList: View {
    @Environment(\.presentationMode) var presentation
    @ObservedObject private var viewModel: ShippingLabelCustomsFormListViewModel
    private let onCompletion: ([ShippingLabelCustomsForm]) -> Void

    init(viewModel: ShippingLabelCustomsFormListViewModel,
         onCompletion: @escaping ([ShippingLabelCustomsForm]) -> Void) {
        self.viewModel = viewModel
        self.onCompletion = onCompletion
        ServiceLocator.analytics.track(.shippingLabelPurchaseFlow, withProperties: ["state": "customs_started"])
    }

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                EUShippingNoticeBanner(width: geometry.size.width)
                    .onDismiss {
                        viewModel.bannerDismissTapped()
                    }
                    .onLearnMore { instructionsURL in
                        viewModel.bannerLearnMoreTapped(instructionsURL: instructionsURL)
                    }
                    .renderedIf(viewModel.shouldDisplayShippingNotice)
                    .fixedSize(horizontal: false, vertical: true)

                ForEach(Array(viewModel.inputViewModels.enumerated()), id: \.offset) { (index, item) in
                    ShippingLabelCustomsFormInput(isCollapsible: viewModel.multiplePackagesDetected,
                                                  packageNumber: index + 1,
                                                  safeAreaInsets: geometry.safeAreaInsets,
                                                  viewModel: item)
                }
                .padding(.bottom, insets: geometry.safeAreaInsets)
            }
            .background(Color(.listBackground))
            .ignoresSafeArea(.container, edges: [.horizontal, .bottom])
        }
        .navigationTitle(Localization.navigationTitle)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button(action: {
                    onCompletion(viewModel.validatedCustomsForms)
                    presentation.wrappedValue.dismiss()
                    ServiceLocator.analytics.track(.shippingLabelPurchaseFlow, withProperties: ["state": "customs_complete"])
                }, label: {
                    Text(Localization.doneButton)
                }).disabled(!viewModel.doneButtonEnabled)
            }
        }
        .wooNavigationBarStyle()
    }
}

private extension ShippingLabelCustomsFormList {
    enum Localization {
        static let navigationTitle = NSLocalizedString("Customs", comment: "Navigation title for Customs screen in Shipping Label flow")
        static let doneButton = NSLocalizedString("Done", comment: "Done navigation button in the Customs screen in Shipping Label flow")
    }
}

#if DEBUG
struct ShippingLabelCustomsFormList_Previews: PreviewProvider {
    static let sampleViewModel: ShippingLabelCustomsFormListViewModel = {
        let sampleOrder = ShippingLabelSampleData.sampleOrder()
        let sampleForm = ShippingLabelCustomsForm(packageID: "Food Package", packageName: "Food Package", items: [])
        return ShippingLabelCustomsFormListViewModel(order: sampleOrder,
                                                     customsForms: [sampleForm],
                                                     destinationCountry: Country(code: "VN", name: "Vietnam", states: []),
                                                     countries: [])
    }()

    static var previews: some View {
        ShippingLabelCustomsFormList(viewModel: sampleViewModel) { _ in }
    }
}
#endif
