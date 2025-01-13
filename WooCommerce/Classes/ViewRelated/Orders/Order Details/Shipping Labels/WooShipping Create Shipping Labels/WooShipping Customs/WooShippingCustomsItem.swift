import SwiftUI
import WooFoundation

struct WooShippingCustomsItem: View {
    @Environment(\.colorScheme) var colorScheme
    /// Whether the item list is collapsed
    @State private var isCollapsed: Bool = true
    @ObservedObject var viewModel: WooShippingCustomsItemViewModel
    @State private var isShowingHSTarrifInfoWebView = false
    @State private var isShowingCountries = false
    @State private var isShowingDescriptionInfoDialog = false
    @State private var isShowingOriginCountryInfoDialog = false


    @Environment(\.shippingWeightUnit) var weightUnit: String

    var body: some View {
        CollapsibleView(isCollapsed: $isCollapsed,
                        shouldShowDividers: false,
                        backgroundColor: .clear,
                        label: {
            VStack(alignment: .leading, spacing: Layout.collapsibleViewVerticalSpacing) {
                HStack {
                    Text(viewModel.title)
                        .headlineStyle()
                    Spacer()
                    Image(systemName: "exclamationmark.circle")
                        .foregroundColor(warningRedColor)
                        .renderedIf(viewModel.requiredInformationIsMissing)
                }

                VStack(alignment: .leading, spacing: Layout.collapsibleViewBottomLabelVerticalSpacing) {
                    HStack {

                        if viewModel.description.isEmpty {
                            emptyValuePlaceholder
                        } else {
                            Text(viewModel.description)
                        }

                        Spacer()
                        Text(viewModel.hsTariffNumber)
                            .renderedIf(viewModel.hsTariffNumber.isNotEmpty)
                    }
                    HStack(spacing: Layout.collapsedUnitsHorizontalSpacing) {
                        Text(viewModel.originCountry.name)
                        Spacer()

                        if viewModel.valuePerUnit.isEmpty {
                            emptyValuePlaceholder
                        } else {
                            Text(viewModel.valuePerUnit)
                        }

                        Text("•")
                            .renderedIf(viewModel.weightPerUnit.isNotEmpty || viewModel.valuePerUnit.isNotEmpty)

                        if viewModel.weightPerUnit.isEmpty {
                            emptyValuePlaceholder
                        } else {
                            Text("\(viewModel.weightPerUnit) \(weightUnit)")
                        }
                    }
                }.renderedIf(isCollapsed)
                    .foregroundColor(.primary)
                    .padding(.trailing, Layout.collapsibleViewBottomContentTrailingPadding)
            }
            .padding(.top, Layout.collapsibleViewTopPadding)
        }, content: {
            VStack(alignment: .leading, spacing: Layout.collapsibleViewVerticalSpacing) {
                Divider()
                HStack {
                    Text(Localization.descriptionTitle)
                        .foregroundColor(.primary)
                        .subheadlineStyle()
                    Spacer()
                    Button {
                        isShowingDescriptionInfoDialog = true
                    } label: {
                        Image(systemName: "info.circle")
                            .foregroundColor(Color(.wooCommercePurple(.shade60)))

                    }
                }
                .padding(.top, Layout.descriptionTopPadding)
                TextField("", text: $viewModel.description)
                    .padding(Layout.extraPadding)
                    .roundedBorder(cornerRadius: Layout.borderCornerRadius,
                                   lineColor: viewModel.description.isEmpty ? warningRedColor : Color(.separator),
                                   lineWidth: Layout.borderLineWidth)


                Text(Localization.valueRequiredWarningText)
                    .foregroundColor(warningRedColor)
                    .footnoteStyle()
                    .renderedIf(viewModel.description.isEmpty)

                Text(Localization.HSTariffNumber)
                    .foregroundColor(.primary)
                    .subheadlineStyle()
                    .padding(.top, Layout.collapsibleViewVerticalSpacing)

                TextField(Localization.HSTariffNumberPlaceholder, text: $viewModel.hsTariffNumber)
                    .keyboardType(.numberPad)
                    .padding(Layout.extraPadding)
                    .roundedBorder(cornerRadius: Layout.borderCornerRadius, lineColor: Color(.separator), lineWidth: Layout.borderLineWidth)

                Text(Localization.tariffNumberRulesWarningText)
                    .foregroundColor(warningRedColor)
                    .footnoteStyle()
                    .renderedIf(!viewModel.isValidTariffNumber)

                Button {
                    isShowingHSTarrifInfoWebView = true
                } label: {
                    HStack(alignment: .top, spacing: Layout.hsTariffNumberMoreInfoVerticalSpacing) {
                        Image(systemName: "info.circle")
                        Text(Localization.HSTariffNumberMoreInfo)
                    }
                    .foregroundColor(Color(.wooCommercePurple(.shade60)))
                    .footnoteStyle()
                    .padding(.bottom, Layout.collapsibleViewVerticalSpacing)
                }

                HStack(alignment: .top) {
                    VStack(alignment: .leading) {
                        Text(Localization.valuePerUnitTitle)
                            .foregroundColor(.primary)
                            .subheadlineStyle()
                        TextField("$ 0", text: $viewModel.valuePerUnit)
                            .keyboardType(.decimalPad)
                            .padding(Layout.extraPadding)
                            .roundedBorder(cornerRadius: Layout.borderCornerRadius,
                                           lineColor: viewModel.valuePerUnit.isEmpty ? warningRedColor : Color(.separator),
                                           lineWidth: Layout.borderLineWidth)
                        Text(Localization.valueRequiredWarningText)
                            .foregroundColor(warningRedColor)
                            .footnoteStyle()
                            .renderedIf(viewModel.valuePerUnit.isEmpty)
                    }

                    VStack(alignment: .leading) {
                        Text(Localization.weightPerUnitTitle)
                            .foregroundColor(.primary)
                            .subheadlineStyle()
                        HStack {
                            TextField("0", text: $viewModel.weightPerUnit)
                                .keyboardType(.decimalPad)
                                .padding(Layout.extraPadding)
                            Text(weightUnit)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .padding(.trailing, Layout.unitsHorizontalSpacing)
                        }
                        .roundedBorder(cornerRadius: Layout.borderCornerRadius,
                                       lineColor: viewModel.weightPerUnit.isEmpty ? warningRedColor : Color(.separator),
                                       lineWidth: Layout.borderLineWidth)
                        Text(Localization.valueRequiredWarningText)
                            .foregroundColor(warningRedColor)
                            .footnoteStyle()
                            .renderedIf(viewModel.weightPerUnit.isEmpty)
                    }
                }
                .padding(.bottom, Layout.collapsibleViewVerticalSpacing)

                HStack {
                    Text(Localization.originCountryTitle)
                        .foregroundColor(.primary)
                    Spacer()
                    Button {
                        isShowingOriginCountryInfoDialog = true
                    } label: {
                        Image(systemName: "info.circle")
                            .foregroundColor(Color(.wooCommercePurple(.shade60)))

                    }
                }
                    .subheadlineStyle()

                Button {
                    isShowingCountries = true
                } label: {
                    HStack {
                        Text(viewModel.originCountry.name)
                            .bodyStyle()
                        Spacer()
                        Image(systemName: "chevron.up.chevron.down")
                    }
                    .padding()
                }
                .roundedBorder(cornerRadius: Layout.borderCornerRadius, lineColor: Color(.separator), lineWidth: Layout.borderLineWidth)
            }
            .padding(.leading, Layout.extraPadding)
            .padding(.trailing, Layout.extraPadding)
            .padding(.bottom, Layout.extraPadding)
        })
        .roundedBorder(cornerRadius: Layout.borderCornerRadius, lineColor: productCardBorderColor(), lineWidth: Layout.borderLineWidth)
        .safariSheet(isPresented: $isShowingHSTarrifInfoWebView, url: viewModel.hsTariffURL)
        .sheet(isPresented: $isShowingCountries, content: {
            NavigationStack {
                SingleSelectionList(title: Localization.originCountryTitle,
                                    items: viewModel.countries,
                                    contentKeyPath: \.name,
                                    selected: $viewModel.originCountry)
            }
            .wooNavigationBarStyle()
        })
        .fullScreenCover(isPresented: $isShowingDescriptionInfoDialog) {
            WooShippingCustomsItemDescriptionInfoDialog()
                .background(FullScreenCoverClearBackgroundView())
        }
        .fullScreenCover(isPresented: $isShowingOriginCountryInfoDialog) {
            WooShippingCustomsItemOriginCountryInfoDialog()
                .background(FullScreenCoverClearBackgroundView())
        }
    }

    var emptyValuePlaceholder: some View {
        RoundedRectangle(cornerRadius: Layout.emptyValuePlaceholderCornerRadius)
                            .fill(Color.withColorStudio(name: .red, shade: .shade0))
                            .frame(width: Layout.emptyValuePlaceholderWidth, height: Layout.emptyValuePlaceholderHeight)
    }

    private var warningRedColor: Color {
        let shade: ColorStudioShade = colorScheme == .dark ? .shade40 : .shade60

        return .withColorStudio(name: .red, shade: shade)
    }
}

extension WooShippingCustomsItem {
    func productCardBorderColor() -> Color {
        if isCollapsed {
            if viewModel.requiredInformationIsMissing {
                return warningRedColor
            } else {
                return Color(.separator)
            }
        } else {
            return .withColorStudio(name: .purple, shade: .shade60)
        }
    }
}

extension WooShippingCustomsItem {
    enum Localization {
        static let descriptionTitle = NSLocalizedString("wooShipping.customsItems.description",
                                              value: "Description",
                                              comment: "Title for the customs items description text field for customs items")
        static let HSTariffNumber = NSLocalizedString("wooShipping.customsItems.hsTariffNumber",
                                                       value: "HS tariff number",
                                                       comment: "Title for the HS Tariff Number text field for customs items")
        static let HSTariffNumberPlaceholder = NSLocalizedString("wooShipping.customsItems.hsTariffNumber.placeholder",
                                                       value: "Optional",
                                                       comment: "Placeholder for the HS Tariff Number text field for customs items")
        static let HSTariffNumberMoreInfo = NSLocalizedString("wooShipping.customsItems.hsTariffNumber.moreInfoText",
                                                       value: "More info about HS tariff",
                                                       comment: "Information text about the HS Tariff")
        static let valuePerUnitTitle = NSLocalizedString("wooShipping.customsItems.valuePerUnit",
                                              value: "Value per unit",
                                              comment: "Title for the customs items value per unit text field for customs items")
        static let weightPerUnitTitle = NSLocalizedString("wooShipping.customsItems.weightPerUnit",
                                              value: "Weight per unit",
                                              comment: "Title for the customs items weight per unit text field for customs items")
        static let valueRequiredWarningText = NSLocalizedString("wooShipping.customsItems.valueRequired",
                                              value: "Value required",
                                              comment: "Warning text when some required value is missing")
        static let tariffNumberRulesWarningText = NSLocalizedString("wooShipping.customsItems.tariffNumberRulesWarning",
                                              value: "The tariff number must be between 6 and 12 digits long",
                                              comment: "Warning text when the shipping customs tariff number is not valid")
        static let originCountryTitle = NSLocalizedString("wooShipping.customsItems.originCountry",
                                              value: "Origin Country",
                                              comment: "Title for the origin country text field")
    }

    enum Layout {
        static let collapsibleViewTopPadding: CGFloat = 4.0
        static let collapsedUnitsHorizontalSpacing: CGFloat = 4.0
        static let collapsibleViewBottomContentTrailingPadding: CGFloat = -30.0
        static let collapsibleViewVerticalSpacing: CGFloat = 8.0
        static let collapsibleViewBottomLabelVerticalSpacing: CGFloat = 4.0
        static let descriptionTopPadding: CGFloat = 4.0
        static let borderCornerRadius: CGFloat = 8.0
        static let borderLineWidth: CGFloat = 1.0
        static let extraPadding: CGFloat = 16.0
        static let hsTariffNumberMoreInfoVerticalSpacing: CGFloat = 8.0
        static let unitsHorizontalSpacing: CGFloat = 8.0
        static let emptyValuePlaceholderCornerRadius: CGFloat = 2.0
        static let emptyValuePlaceholderWidth: CGFloat = 48.0
        static let emptyValuePlaceholderHeight: CGFloat = 16.0
    }
}
