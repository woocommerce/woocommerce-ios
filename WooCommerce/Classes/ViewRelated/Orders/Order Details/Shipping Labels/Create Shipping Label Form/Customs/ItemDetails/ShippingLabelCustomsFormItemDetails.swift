import SwiftUI
import Yosemite

struct ShippingLabelCustomsFormItemDetails: View {
    private let itemNumber: Int
    private let safeAreaInsets: EdgeInsets

    @State private var isCollapsed: Bool = true
    @ObservedObject private var viewModel: ShippingLabelCustomsFormItemDetailsViewModel

    init(itemNumber: Int, viewModel: ShippingLabelCustomsFormItemDetailsViewModel, safeAreaInsets: EdgeInsets = .zero) {
        self.itemNumber = itemNumber
        self.viewModel = viewModel
        self.safeAreaInsets = safeAreaInsets
    }

    var body: some View {
        CollapsibleView(isCollapsed: $isCollapsed, safeAreaInsets: safeAreaInsets, label: {
            HStack(spacing: Constants.horizontalSpacing) {
                Image(uiImage: .inventoryImage)
                Text(String(format: Localization.customLineTitle, itemNumber))
                    .font(.body)
            }
        }, content: {
            VStack(spacing: 0) {
                TitleAndTextFieldRow(title: Localization.descriptionTitle,
                                     placeholder: Localization.descriptionTitle,
                                     text: $viewModel.description)
                    .padding(.horizontal, insets: safeAreaInsets)
                Divider()
                    .padding(.leading, Constants.horizontalSpacing)
                    .padding(.horizontal, insets: safeAreaInsets)

                TitleAndTextFieldRow(title: Localization.hsTariffNumberTitle,
                                     placeholder: Localization.hsTariffNumberPlaceholder,
                                     text: $viewModel.hsTariffNumber)
                    .padding(.horizontal, insets: safeAreaInsets)
                Divider()
                    .padding(.leading, Constants.horizontalSpacing)
                    .padding(.horizontal, insets: safeAreaInsets)
            }
            .background(Color(.listForeground))
        })
    }
}

private extension ShippingLabelCustomsFormItemDetails {
    enum Constants {
        static let horizontalSpacing: CGFloat = 16
    }

    enum Localization {
        static let customLineTitle = NSLocalizedString("Custom Line %1$d", comment: "Custom line index in Customs Form of Shipping Label flow")
        static let descriptionTitle = NSLocalizedString("Description",
                                                        comment: "Title of Description row in Package Content section in Customs screen of Shipping Label flow")
        static let hsTariffNumberTitle = NSLocalizedString("HS Tariff Number",
                                                           comment: "Title of HS Tariff Number row in Package Content" +
                                                                " section in Customs screen of Shipping Label flow")
        static let hsTariffNumberPlaceholder = NSLocalizedString("Enter number (Optional)",
                                                                 comment: "Placeholder of HS Tariff Number row in Package" +
                                                                    " Content section in Customs screen of Shipping Label flow")
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
