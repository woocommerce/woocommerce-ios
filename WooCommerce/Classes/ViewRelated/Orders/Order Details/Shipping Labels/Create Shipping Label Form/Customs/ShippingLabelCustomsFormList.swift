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
    }

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
        
            }
            .background(Color(.listBackground))
            .ignoresSafeArea()
        }
        .navigationTitle(Localization.navigationTitle)
        .navigationBarItems(trailing: Button(action: {
            onCompletion(viewModel.customsForms)
            presentation.wrappedValue.dismiss()
        }, label: {
            Text(Localization.doneButton)
        }))
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
        let sampleForm = ShippingLabelCustomsForm(packageID: "Food Package", productIDs: sampleOrder.items.map { $0.productID })
        return ShippingLabelCustomsFormListViewModel(order: sampleOrder, customsForms: [sampleForm])
    }()

    static var previews: some View {
        ShippingLabelCustomsFormList(viewModel: sampleViewModel) { _ in }
    }
}
