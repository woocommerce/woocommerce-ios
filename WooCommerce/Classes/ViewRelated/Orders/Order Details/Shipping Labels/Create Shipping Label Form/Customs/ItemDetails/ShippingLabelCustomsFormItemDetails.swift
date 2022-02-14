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
                    .bodyStyle()
                Spacer()
                Image(uiImage: .noticeImage)
                    .foregroundColor(Color(.error))
                    .renderedIf(viewModel.validatedItem == nil)
            }
        }, content: {
            // Item Description
            VStack(spacing: 0) {
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
                    ValidationErrorRow(errorMessage: Localization.descriptionError)
                    Divider()
                        .padding(.leading, Constants.horizontalSpacing)
                }
                .padding(.horizontal, insets: safeAreaInsets)
                .renderedIf(!viewModel.hasValidDescription)
            }

            // HS Tariff Number, validation & learn more
            VStack(spacing: 0) {
                VStack(spacing: 0) {
                    TitleAndTextFieldRow(title: Localization.hsTariffNumberTitle,
                                         placeholder: Localization.hsTariffNumberPlaceholder,
                                         text: $viewModel.hsTariffNumber,
                                         keyboardType: .numberPad)
                    Divider()
                        .padding(.leading, Constants.horizontalSpacing)
                }
                .padding(.horizontal, insets: safeAreaInsets)
                .background(Color(.listForeground))

                VStack(spacing: 0) {
                    ValidationErrorRow(errorMessage: Localization.hsTariffNumberError)
                    Divider()
                        .padding(.leading, Constants.horizontalSpacing)
                }
                .padding(.horizontal, insets: safeAreaInsets)
                .renderedIf(!viewModel.hasValidHSTariffNumber)

                VStack(spacing: 0) {
                    LearnMoreRow(content: Localization.learnMoreHSTariffText, contentURL: Constants.hsTariffURL)
                    Divider()
                        .padding(.leading, Constants.horizontalSpacing)
                }
                .padding(.horizontal, insets: safeAreaInsets)
                .background(Color(.listForeground))
            }

            // Weight row and validation
            VStack(spacing: 0) {
                VStack(spacing: 0) {
                    TitleAndTextFieldRow(title: String(format: Localization.weightTitle, viewModel.weightUnit),
                                         placeholder: "0",
                                         text: $viewModel.weight,
                                         keyboardType: .decimalPad)
                    Divider()
                        .padding(.leading, Constants.horizontalSpacing)
                }
                .padding(.horizontal, insets: safeAreaInsets)
                .background(Color(.listForeground))

                VStack(spacing: 0) {
                    ValidationErrorRow(errorMessage: Localization.weightError)
                    Divider()
                        .padding(.leading, Constants.horizontalSpacing)
                }
                .padding(.horizontal, insets: safeAreaInsets)
                .renderedIf(viewModel.validatedWeight == nil)
            }

            // Value row & validation
            VStack(spacing: 0) {
                VStack(spacing: 0) {
                    TitleAndTextFieldRow(title: String(format: Localization.valueTitle, viewModel.currency),
                                         placeholder: "0",
                                         text: $viewModel.value,
                                         keyboardType: .decimalPad)
                    Divider()
                        .padding(.leading, Constants.horizontalSpacing)
                }
                .padding(.horizontal, insets: safeAreaInsets)
                .background(Color(.listForeground))

                VStack(spacing: 0) {
                    ValidationErrorRow(errorMessage: Localization.valueError)
                    Divider()
                        .padding(.leading, Constants.horizontalSpacing)
                }
                .padding(.horizontal, insets: safeAreaInsets)
                .renderedIf(viewModel.validatedValue == nil)
            }

            // Origin country
            VStack(spacing: 0) {
                VStack(spacing: 0) {
                    TitleAndValueRow(title: Localization.originTitle, value: .placeholder(viewModel.originCountry.name), selectionStyle: .disclosure) {
                        isShowingCountries.toggle()
                    }
                    .sheet(isPresented: $isShowingCountries, content: {
                        SelectionList(title: Localization.originTitle,
                                      items: viewModel.allCountries,
                                      contentKeyPath: \.name,
                                      selected: $viewModel.originCountry)
                    })
                    Divider()
                        .padding(.leading, Constants.horizontalSpacing)
                }
                .padding(.horizontal, insets: safeAreaInsets)
                .background(Color(.listForeground))

                VStack(spacing: 0) {
                    ValidationErrorRow(errorMessage: Localization.originError)
                    Divider()
                        .padding(.leading, Constants.horizontalSpacing)
                }
                .padding(.horizontal, insets: safeAreaInsets)
                .renderedIf(!viewModel.hasValidOriginCountry)

                Text(Localization.originDescription)
                    .footnoteStyle()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, Constants.horizontalSpacing)
                    .padding(.vertical, Constants.verticalSpacing)
                    .padding(.bottom, Constants.verticalSpacing)
                    .padding(.horizontal, insets: safeAreaInsets)
            }
        })
    }
}

private extension ShippingLabelCustomsFormItemDetails {
    enum Constants {
        static let horizontalSpacing: CGFloat = 16
        static let verticalSpacing: CGFloat = 8
        static let hsTariffURL: URL? = .init(string: "https://docs.woocommerce.com/document/woocommerce-shipping-and-tax/woocommerce-shipping/#section-29")
    }

    enum Localization {
        static let customLineTitle = NSLocalizedString("Custom Line %1$d", comment: "Custom line index in Customs Form of Shipping Label flow")
        static let descriptionTitle = NSLocalizedString("Description",
                                                        comment: "Title of Description row of item details in Customs screen of Shipping Label flow")
        static let descriptionPlaceholder = NSLocalizedString("Enter description",
                                                              comment: "Placeholder of Description row of item details in " +
                                                                "Customs screen of Shipping Label flow")
        static let descriptionError = NSLocalizedString("Item description is required",
                                                        comment: "Error message for missing value in Description row in Customs screen of Shipping Label flow")
        static let hsTariffNumberTitle = NSLocalizedString("HS Tariff Number",
                                                           comment: "Title of HS Tariff Number row in Package Content" +
                                                                " section in Customs screen of Shipping Label flow")
        static let hsTariffNumberPlaceholder = NSLocalizedString("Enter number (Optional)",
                                                                 comment: "Placeholder of HS Tariff Number row in Package" +
                                                                    " Content section in Customs screen of Shipping Label flow")
        static let hsTariffNumberError = NSLocalizedString("HS Tariff Number must be 6 digits long",
                                                           comment: "Validation error for HS Tariff Number row in Customs screen of Shipping Label flow")
        static let learnMoreHSTariffText = NSLocalizedString(
            "Learn more about HS Tariff Number",
            comment: "A label prompting users to learn more about HS Tariff Number in Customs screen of Shipping Label flow")
        static let weightTitle = NSLocalizedString("Weight (%1$@ per unit)",
                                                   comment: "Title for the Weight row in item details in Customs screen of Shipping Label flow")
        static let weightError = NSLocalizedString("Item weight must be larger than 0",
                                                   comment: "Error message for missing value in Weight row in Customs screen of Shipping Label flow")
        static let valueTitle = NSLocalizedString("Value (%1$@ per unit)",
                                                  comment: "Title for the Value row in item details in Customs screen of Shipping Label flow")
        static let valueError = NSLocalizedString("Item value must be larger than 0",
                                                  comment: "Error message for missing value in Value row in Customs screen of Shipping Label flow")
        static let originTitle = NSLocalizedString("Origin Country",
                                                   comment: "Title for the Origin Country row in Customs screen of Shipping Label flow")
        static let originDescription = NSLocalizedString("Country where the product was manufactured or assembled",
                                                         comment: "Description for the Origin Country row in Customs screen of Shipping Label flow")
        static let originError = NSLocalizedString("Origin Country is required",
                                                   comment: "Error message for missing value in Origin Country row in Customs screen of Shipping Label flow")
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

    static let sampleViewModel = ShippingLabelCustomsFormItemDetailsViewModel(item: sampleDetails, countries: [], currency: "$")

    static var previews: some View {
        ShippingLabelCustomsFormItemDetails(itemNumber: 1, viewModel: sampleViewModel, safeAreaInsets: .zero)
    }
}
