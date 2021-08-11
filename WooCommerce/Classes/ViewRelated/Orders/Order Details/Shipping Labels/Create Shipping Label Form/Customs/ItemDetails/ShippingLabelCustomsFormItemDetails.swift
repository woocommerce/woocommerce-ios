import SwiftUI
import Yosemite

struct ShippingLabelCustomsFormItemDetails: View {
    private let itemNumber: Int
    private let safeAreaInsets: EdgeInsets

    @State private var isCollapsed: Bool = true
    @State private var isShowingCountries: Bool = false
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
                                     placeholder: Localization.descriptionPlaceholder,
                                     text: $viewModel.description)
                Divider()
                    .padding(.leading, Constants.horizontalSpacing)
            }
            .padding(.horizontal, insets: safeAreaInsets)
            .background(Color(.listForeground))

            VStack(spacing: 0) {
                TitleAndTextFieldRow(title: Localization.hsTariffNumberTitle,
                                     placeholder: Localization.hsTariffNumberPlaceholder,
                                     text: $viewModel.hsTariffNumber)
                Divider()
                    .padding(.leading, Constants.horizontalSpacing)
            }
            .padding(.horizontal, insets: safeAreaInsets)
            .background(Color(.listForeground))

            VStack(spacing: 0) {
                LearnMoreRow(localizedStringWithHyperlink: Localization.learnMoreHSTariffText)
                Divider()
                    .padding(.leading, Constants.horizontalSpacing)
            }
            .padding(.horizontal, insets: safeAreaInsets)
            .background(Color(.listForeground))

            VStack(spacing: 0) {
                // TODO: get weight unit for item ⚖️
                TitleAndTextFieldRow(title: String(format: Localization.weightTitle, "oz"),
                                     placeholder: Localization.weightPlaceholder,
                                     text: $viewModel.weight)
                Divider()
                    .padding(.leading, Constants.horizontalSpacing)
            }
            .padding(.horizontal, insets: safeAreaInsets)
            .background(Color(.listForeground))

            VStack(spacing: 0) {
                // TODO: get value unit for item 💵
                TitleAndTextFieldRow(title: String(format: Localization.valueTitle, "$"),
                                     placeholder: Localization.valuePlaceholder,
                                     text: $viewModel.value)
                Divider()
                    .padding(.leading, Constants.horizontalSpacing)
            }
            .padding(.horizontal, insets: safeAreaInsets)
            .background(Color(.listForeground))

            VStack(spacing: 0) {
                TitleAndValueRow(title: Localization.originTitle, value: viewModel.originCountry, selectable: true) {
                    isShowingCountries.toggle()
                }
                .sheet(isPresented: $isShowingCountries, content: {
                    // TODO: fetch countries 🌏
                    SelectionList(title: Localization.originTitle,
                                  items: viewModel.allCountries,
                                  contentKeyPath: \.name,
                                  selectionKeyPath: \.code,
                                  selected: $viewModel.originCountry)
                })
                Divider()
                    .padding(.leading, Constants.horizontalSpacing)
            }
            .padding(.horizontal, insets: safeAreaInsets)
            .background(Color(.listForeground))

            Text(Localization.originDescription)
                .footnoteStyle()
                .padding(.horizontal, Constants.horizontalSpacing)
                .padding(.horizontal, insets: safeAreaInsets)
                .padding(.vertical, Constants.verticalSpacing)
                .padding(.bottom, Constants.verticalSpacing)
        })
    }
}

private extension ShippingLabelCustomsFormItemDetails {
    enum Constants {
        static let horizontalSpacing: CGFloat = 16
        static let verticalSpacing: CGFloat = 8
    }

    enum Localization {
        static let customLineTitle = NSLocalizedString("Custom Line %1$d", comment: "Custom line index in Customs Form of Shipping Label flow")
        static let descriptionTitle = NSLocalizedString("Description",
                                                        comment: "Title of Description row of item details in Customs screen of Shipping Label flow")
        static let descriptionPlaceholder = NSLocalizedString("Enter description",
                                                              comment: "Placeholder of Description row of item details in " +
                                                                "Customs screen of Shipping Label flow")
        static let hsTariffNumberTitle = NSLocalizedString("HS Tariff Number",
                                                           comment: "Title of HS Tariff Number row in Package Content" +
                                                                " section in Customs screen of Shipping Label flow")
        static let hsTariffNumberPlaceholder = NSLocalizedString("Enter number (Optional)",
                                                                 comment: "Placeholder of HS Tariff Number row in Package" +
                                                                    " Content section in Customs screen of Shipping Label flow")
        static let learnMoreHSTariffText = NSLocalizedString(
            "<a href=\"https://docs.woocommerce.com/document/woocommerce-shipping-and-tax/woocommerce-shipping/#section-29\">Learn more</a> " +
                "about HS Tariff Number",
            comment: "A label prompting users to learn more about HS Tariff Number with an embedded hyperlink in Customs screen of Shipping Label flow")
        static let weightTitle = NSLocalizedString("Weight (%1$@ per unit)",
                                                   comment: "Title for the Weight row in item details in Customs screen of Shipping Label flow")
        static let weightPlaceholder = NSLocalizedString("Enter weight",
                                                         comment: "Placeholder for the Weight row in item details in Customs screen of Shipping Label flow")
        static let valueTitle = NSLocalizedString("Value (%1$@ per unit)",
                                                  comment: "Title for the Value row in item details in Customs screen of Shipping Label flow")
        static let valuePlaceholder = NSLocalizedString("Enter value",
                                                        comment: "Title for the Value row in item details in Customs screen of Shipping Label flow")
        static let originTitle = NSLocalizedString("Origin Country",
                                                   comment: "Title for the Origin Country row in Customs screen of Shipping Label flow")
        static let originDescription = NSLocalizedString("Country where the product was manufactured or assembled",
                                                         comment: "Description for the Origin Country row in Customs screen of Shipping Label flow")
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
