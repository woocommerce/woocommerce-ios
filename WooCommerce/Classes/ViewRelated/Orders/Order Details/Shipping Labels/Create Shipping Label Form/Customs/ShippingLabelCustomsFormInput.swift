import SwiftUI
import Yosemite

struct ShippingLabelCustomsFormInput: View {
    private let isCollapsible: Bool
    private let packageNumber: Int
    private let safeAreaInsets: EdgeInsets

    @ObservedObject private var viewModel: ShippingLabelCustomsFormInputViewModel
    @State private var showingContentTypes = false

    init(isCollapsible: Bool, packageNumber: Int, safeAreaInsets: EdgeInsets, viewModel: ShippingLabelCustomsFormInputViewModel) {
        self.isCollapsible = isCollapsible
        self.packageNumber = packageNumber
        self.safeAreaInsets = safeAreaInsets
        self.viewModel = viewModel
    }

    var body: some View {
        CollapsibleView(isCollapsible: isCollapsible, safeAreaInsets: safeAreaInsets, label: {
            headerView
        }, content: {
            VStack {
                TitleAndToggleRow(title: Localization.returnPolicyTitle, isSubheadline: true, isOn: $viewModel.returnOnNonDelivery)
                    .padding(.bottom, Constants.verticalPadding)
                    .padding(.horizontal, Constants.horizontalPadding)
                    .padding(.horizontal, insets: safeAreaInsets)

                TitleAndValueRow(title: Localization.contentTypeTitle, value: viewModel.contentsType.localizedName, selectable: true) {
                    showingContentTypes.toggle()
                }
                .padding(.horizontal, insets: safeAreaInsets)
                .sheet(isPresented: $showingContentTypes, content: {
                    SelectionList(title: Localization.contentTypeTitle,
                                  items: ShippingLabelCustomsForm.ContentsType.allCases,
                                  contentKeyPath: \.localizedName,
                                  selected: $viewModel.contentsType)
                })

                Divider()
                    .padding(.leading, Constants.horizontalPadding)
            }
        })
    }

    private var headerView: some View {
        HStack {
            Text(String(format: Localization.packageNumber, packageNumber))
                .font(.headline)
            Text("-")
                .font(.body)
            Text(viewModel.customsForm.packageName)
                .font(.body)
        }
    }
}

private extension ShippingLabelCustomsFormInput {
    enum Constants {
        static let horizontalPadding: CGFloat = 16
        static let verticalPadding: CGFloat = 8
    }
    enum Localization {
        static let packageNumber = NSLocalizedString("Package %1$d", comment: "Package index in Customs screen of Shipping Label flow")
        static let returnPolicyTitle = NSLocalizedString("Return to sender if package is unable to be delivered",
                                                         comment: "Title for the return policy in Customs screen of Shipping Label flow")
        static let contentTypeTitle = NSLocalizedString("Content Type",
                                                        comment: "Title for the Content Type row in Customs screen of Shipping Label flow")
        static let restrictionTypeTitle = NSLocalizedString("Restriction Type",
                                                            comment: "Title for the Restriction Type row in Customs screen of Shipping Label flow")
        static let itnTitle = NSLocalizedString("ITN",
                                                comment: "Title for the ITN row in Customs screen of Shipping Label flow")
        static let itnPlaceholder = NSLocalizedString("Enter ITN (optional)",
                                                      comment: "Placeholder for the ITN row in Customs screen of Shippling Label flow")
    }
}

struct ShippingLabelCustomsFormInput_Previews: PreviewProvider {
    static let sampleViewModel: ShippingLabelCustomsFormInputViewModel = {
        let sampleOrder = ShippingLabelPackageDetailsViewModel.sampleOrder()
        let sampleForm = ShippingLabelCustomsForm(packageID: "Food Package", packageName: "Food Package", productIDs: sampleOrder.items.map { $0.productID })
        return .init(customsForm: sampleForm)
    }()

    static var previews: some View {
        ShippingLabelCustomsFormInput(isCollapsible: true, packageNumber: 1, safeAreaInsets: .zero, viewModel: sampleViewModel)
    }
}
