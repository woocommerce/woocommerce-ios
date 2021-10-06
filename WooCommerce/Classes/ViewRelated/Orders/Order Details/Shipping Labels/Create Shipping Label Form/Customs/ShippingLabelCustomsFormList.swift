import SwiftUI
import Yosemite

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
    }
}

private extension ShippingLabelCustomsFormList {
    enum Localization {
        static let navigationTitle = NSLocalizedString("Customs", comment: "Navigation title for Customs screen in Shipping Label flow")
        static let doneButton = NSLocalizedString("Done", comment: "Done navigation button in the Customs screen in Shipping Label flow")
    }
}

struct ShippingLabelCustomsFormList_Previews: PreviewProvider {
    static let sampleViewModel: ShippingLabelCustomsFormListViewModel = {
        let sampleOrder = ShippingLabelPackageDetailsViewModel.sampleOrder()
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
