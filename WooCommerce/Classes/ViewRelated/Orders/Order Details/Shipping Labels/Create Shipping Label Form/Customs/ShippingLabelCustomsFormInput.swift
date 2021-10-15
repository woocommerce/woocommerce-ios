import SwiftUI
import Yosemite

struct ShippingLabelCustomsFormInput: View {
    private let isCollapsible: Bool
    private let packageNumber: Int
    private let safeAreaInsets: EdgeInsets

    @ObservedObject private var viewModel: ShippingLabelCustomsFormInputViewModel
    @State private var showingContentTypes = false
    @State private var showingRestrictionTypes = false
    @State private var isCollapsed: Bool = false

    init(isCollapsible: Bool, packageNumber: Int, safeAreaInsets: EdgeInsets, viewModel: ShippingLabelCustomsFormInputViewModel) {
        self.isCollapsible = isCollapsible
        self.packageNumber = packageNumber
        self.safeAreaInsets = safeAreaInsets
        self.viewModel = viewModel
        self.isCollapsed = packageNumber > 1
    }

    var body: some View {
        CollapsibleView(isCollapsible: isCollapsible, isCollapsed: $isCollapsed, safeAreaInsets: safeAreaInsets, label: {
            headerView
        }, content: {
            VStack(spacing: 0) {
                TitleAndToggleRow(title: Localization.returnPolicyTitle, isSubheadline: true, isOn: $viewModel.returnOnNonDelivery)
                    .padding(.bottom, Constants.verticalPadding)
                    .padding(.horizontal, Constants.horizontalPadding)
                contentRows
                restrictionRows
                itnRows
            }
            .padding(.horizontal, insets: safeAreaInsets)
            .padding(.top, Constants.verticalPadding)
            .background(Color(.listForeground))

            VStack(spacing: 0) {
                ListHeaderView(text: Localization.packageContentSection.uppercased(), alignment: .left)
                    .padding(.horizontal, insets: safeAreaInsets)

                ForEach(Array(viewModel.items.enumerated()), id: \.element) { (index, item) in
                    viewModel.itemViewModels.first(where: { $0.productID == item.productID })
                        .map { inputModel in
                            ShippingLabelCustomsFormItemDetails(itemNumber: index + 1, viewModel: inputModel, safeAreaInsets: safeAreaInsets)
                        }
                }
            }
        })
    }

    private var headerView: some View {
        HStack {
            Text(String(format: Localization.packageNumber, packageNumber))
                .font(.headline)
            Text("-")
                .font(.body)
            Text(viewModel.packageName)
                .font(.body)
            Spacer()
            Image(uiImage: .noticeImage)
                .foregroundColor(Color(.error))
                .renderedIf(!viewModel.validForm)
        }
    }

    private var contentRows: some View {
        VStack(spacing: 0) {
            TitleAndValueRow(title: Localization.contentTypeTitle, value: .placeholder(viewModel.contentsType.localizedName), selectable: true) {
                showingContentTypes.toggle()
            }
            .sheet(isPresented: $showingContentTypes, content: {
                SelectionList(title: Localization.contentTypeTitle,
                              items: ShippingLabelCustomsForm.ContentsType.allCases,
                              contentKeyPath: \.localizedName,
                              selected: $viewModel.contentsType)
            })
            Divider()
                .padding(.leading, Constants.horizontalPadding)

            VStack(spacing: 0) {
                TitleAndTextFieldRow(title: Localization.contentExplanationTitle,
                                     placeholder: Localization.contentExplanationPlaceholder,
                                     text: $viewModel.contentExplanation)
                Divider()
                    .padding(.leading, Constants.horizontalPadding)

                VStack(spacing: 0) {
                    ValidationErrorRow(errorMessage: Localization.contentExplanationMissing)
                        .background(Color(.listBackground))
                    Divider()
                        .padding(.leading, Constants.horizontalPadding)
                }
                .renderedIf(viewModel.missingContentExplanation)
            }
            .renderedIf(viewModel.contentsType == .other)
        }
    }

    private var restrictionRows: some View {
        VStack(spacing: 0) {
            TitleAndValueRow(title: Localization.restrictionTypeTitle, value: .placeholder(viewModel.restrictionType.localizedName), selectable: true) {
                showingRestrictionTypes.toggle()
            }
            .sheet(isPresented: $showingRestrictionTypes, content: {
                SelectionList(title: Localization.restrictionTypeTitle,
                              items: ShippingLabelCustomsForm.RestrictionType.allCases,
                              contentKeyPath: \.localizedName,
                              selected: $viewModel.restrictionType)
            })
            Divider()
                .padding(.leading, Constants.horizontalPadding)

            VStack(spacing: 0) {
                TitleAndTextFieldRow(title: Localization.restrictionCommentTitle,
                                     placeholder: Localization.restrictionCommentPlaceholder,
                                     text: $viewModel.restrictionComments)
                Divider()
                    .padding(.leading, Constants.horizontalPadding)

                VStack(spacing: 0) {
                    ValidationErrorRow(errorMessage: Localization.restrictionCommentMissing)
                        .background(Color(.listBackground))
                    Divider()
                        .padding(.leading, Constants.horizontalPadding)
                }
                .renderedIf(viewModel.missingRestrictionComments)
            }
            .renderedIf(viewModel.restrictionType == .other)
        }
    }

    private var itnRows: some View {
        VStack(spacing: 0) {
            TitleAndTextFieldRow(title: Localization.itnTitle,
                                 placeholder: viewModel.missingITNForDestination ? Localization.itnRequiredPlaceholder : Localization.itnPlaceholder,
                                 text: $viewModel.itn)
            Divider()
                .padding(.leading, Constants.horizontalPadding)

            VStack(spacing: 0) {
                ValidationErrorRow(errorMessage: validationErrorMessageForITNRow)
                    .background(Color(.listBackground))
                Divider()
                    .padding(.leading, Constants.horizontalPadding)
            }
            .renderedIf(validationErrorMessageForITNRow.isNotEmpty)

            LearnMoreRow(content: Localization.learnMoreITNText, contentURL: Constants.itnInfoURL)
        }
    }

    private var validationErrorMessageForITNRow: String {
        if viewModel.invalidITN {
            return Localization.itnInvalidFormat
        } else if viewModel.missingITNForDestination {
            return String(format: Localization.itnMissingForDestination, viewModel.destinationCountry.name)
        } else if viewModel.missingITNForClassesAbove2500usd {
            return Localization.itnMissingForClassAbove2500usd
        }
        return ""
    }
}

private extension ShippingLabelCustomsFormInput {
    enum Constants {
        static let horizontalPadding: CGFloat = 16
        static let verticalPadding: CGFloat = 8
        static let itnInfoURL = URL(string: "https://pe.usps.com/text/imm/immc5_010.htm")
    }
    enum Localization {
        static let packageNumber = NSLocalizedString("Package %1$d", comment: "Package index in Customs screen of Shipping Label flow")
        static let returnPolicyTitle = NSLocalizedString("Return to sender if package is unable to be delivered",
                                                         comment: "Title for the return policy in Customs screen of Shipping Label flow")
        static let contentTypeTitle = NSLocalizedString("Content Type",
                                                        comment: "Title for the Content Type row in Customs screen of Shipping Label flow")
        static let contentExplanationTitle = NSLocalizedString("Content Details",
                                                               comment: "Title for the Content Details row in Customs screen of Shipping Label flow")
        static let contentExplanationPlaceholder = NSLocalizedString("Type of contents",
                                                                     comment: "Placeholder for the Content Details row " +
                                                                        "in Customs screen of Shipping Label flow")
        static let contentExplanationMissing = NSLocalizedString("Please describe what kind of goods this package contains",
                                                                 comment: "Error message for missing explanation when Content Type" +
                                                                    "is Other in Customs screen of Shipping Label flow")
        static let restrictionTypeTitle = NSLocalizedString("Restriction Type",
                                                            comment: "Title for the Restriction Type row in Customs screen of Shipping Label flow")
        static let restrictionCommentTitle = NSLocalizedString("Restriction Details",
                                                               comment: "Title for the Restriction Details row in Customs screen of Shipping Label flow")
        static let restrictionCommentPlaceholder = NSLocalizedString("Type of restriction",
                                                                     comment: "Placeholder for the Restriction Details row in " +
                                                                        "Customs screen of Shipping Label flow")
        static let restrictionCommentMissing = NSLocalizedString("Please describe what kind of restrictions this package must have",
                                                                 comment: "Error message for missing comments when Restriction Type" +
                                                                    "is Other in Customs screen of Shipping Label flow")
        static let itnTitle = NSLocalizedString("ITN",
                                                comment: "Title for the ITN row in Customs screen of Shipping Label flow")
        static let itnPlaceholder = NSLocalizedString("Enter ITN (Optional)",
                                                      comment: "Placeholder for the ITN row in Customs screen of Shippling Label flow")
        static let itnRequiredPlaceholder = NSLocalizedString("Enter ITN",
                                                              comment: "Placeholder for the required ITN row in Customs screen of Shipping Label flow")
        static let itnMissingForDestination = NSLocalizedString("ITN is required for shipments to %1$@",
                                                                comment: "Error message for missing ITN for destination country in" +
                                                                    "Customs screen of Shipping Label flow. The placeholder is the destination country.")
        static let itnMissingForClassAbove2500usd = NSLocalizedString("ITN is required for shipping items valued over $2,500 per tariff number",
                                                                      comment: "Error message for missing ITN for tariff number valued over $2,500 in" +
                                                                        "Customs screen of Shipping Label flow")
        static let itnInvalidFormat = NSLocalizedString("Invalid ITN format",
                                                        comment: "Error message for invalid format of ITN in Customs screen of Shipping Label flow")
        static let learnMoreITNText = NSLocalizedString("Learn more about Internal Transaction Number",
                                                        comment: "A label prompting users to learn more about internal transaction number")
        static let packageContentSection = NSLocalizedString("Package Content",
                                                             comment: "Title of Package Content section in Customs screen of Shipping Label flow")
    }
}

struct ShippingLabelCustomsFormInput_Previews: PreviewProvider {
    static let sampleViewModel: ShippingLabelCustomsFormInputViewModel = {
        let sampleOrder = ShippingLabelPackageDetailsViewModel.sampleOrder()
        let sampleForm = ShippingLabelCustomsForm(packageID: "Food Package", packageName: "Food Package", items: [])
        return .init(customsForm: sampleForm, destinationCountry: Country(code: "VN", name: "Vietnam", states: []), countries: [], currency: "$")
    }()

    static var previews: some View {
        ShippingLabelCustomsFormInput(isCollapsible: true, packageNumber: 1, safeAreaInsets: .zero, viewModel: sampleViewModel)
    }
}
