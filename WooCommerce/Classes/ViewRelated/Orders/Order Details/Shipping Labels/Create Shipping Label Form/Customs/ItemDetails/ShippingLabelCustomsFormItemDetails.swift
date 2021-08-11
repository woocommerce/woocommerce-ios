import SwiftUI
import Yosemite

struct ShippingLabelCustomsFormItemDetails: View {
    private let itemNumber: Int
    private let safeAreaInsets: EdgeInsets

    @ObservedObject private var viewModel: ShippingLabelCustomsFormItemDetailsViewModel

    init(itemNumber: Int, viewModel: ShippingLabelCustomsFormItemDetailsViewModel, safeAreaInsets: EdgeInsets = .zero) {
        self.itemNumber = itemNumber
        self.viewModel = viewModel
        self.safeAreaInsets = safeAreaInsets
    }

    var body: some View {
        Text("Hello, World!")
    }
}

struct ShippingLabelCustomsFormItemDetails_Previews: PreviewProvider {
    static let sampleDetails = ShippingLabelCustomsForm.Item(description: "Notebook",
                                                             quantity: 1,
                                                             value: 10,
                                                             weight: 1.5,
                                                             hsTariffNumber: "",
                                                             originCountry: "US",
                                                             productID: 123)

    static let sampleViewModel = ShippingLabelCustomsFormItemDetailsViewModel(item: sampleDetails)

    static var previews: some View {
        ShippingLabelCustomsFormItemDetails(itemNumber: 1, viewModel: sampleViewModel, safeAreaInsets: .zero)
    }
}
