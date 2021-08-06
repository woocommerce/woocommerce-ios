import SwiftUI
import Yosemite

struct ShippingLabelCustomsFormList: View {
    @ObservedObject private var viewModel: ShippingLabelCustomsFormListViewModel
    private let onCompletion: ([ShippingLabelCustomsForm]) -> Void

    init(viewModel: ShippingLabelCustomsFormListViewModel,
         onCompletion: @escaping ([ShippingLabelCustomsForm]) -> Void) {
        self.viewModel = viewModel
        self.onCompletion = onCompletion
    }

    var body: some View {
        Text("Hello, World!")
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
