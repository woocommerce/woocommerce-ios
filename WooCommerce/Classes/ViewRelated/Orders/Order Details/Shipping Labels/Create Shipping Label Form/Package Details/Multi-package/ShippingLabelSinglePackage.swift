import SwiftUI

struct ShippingLabelSinglePackage: View {

    @ObservedObject private var viewModel: ShippingLabelSinglePackageViewModel
    @State private var isShowingPackageSelection = false
    @State private var isCollapsed: Bool = false

    private let isCollapsible: Bool
    private let safeAreaInsets: EdgeInsets

    init(isCollapsible: Bool,
         safeAreaInsets: EdgeInsets,
         viewModel: ShippingLabelSinglePackageViewModel) {
        self.isCollapsible = isCollapsible
        self.safeAreaInsets = safeAreaInsets
        self.viewModel = viewModel
    }

    var body: some View {
        CollapsibleView(isCollapsible: isCollapsible, isCollapsed: $isCollapsed, safeAreaInsets: safeAreaInsets) {
            ShippingLabelPackageNumberRow(packageNumber: viewModel.packageNumber, numberOfItems: viewModel.itemsRows.count, isValid: viewModel.isValidPackage)
        } content: {
            ListHeaderView(text: Localization.itemsToFulfillHeader, alignment: .left)
                .padding(.horizontal, insets: safeAreaInsets)

            Divider()

            ForEach(viewModel.itemsRows) { productItemRow in
                productItemRow
                    .padding(.horizontal, insets: safeAreaInsets)
                    .background(Color(.listForeground(modal: false)))
                Divider()
                    .padding(.horizontal, insets: safeAreaInsets)
                    .padding(.leading, Constants.horizontalPadding)
            }

            ListHeaderView(text: Localization.packageDetailsHeader, alignment: .left)
                .padding(.horizontal, insets: safeAreaInsets)

            VStack(spacing: 0) {
                VStack(spacing: 0) {
                    Divider()

                    TitleAndValueRow(title: Localization.packageSelected, value: .placeholder(viewModel.selectedPackageName), selectionStyle: .disclosure) {
                        isShowingPackageSelection.toggle()
                    }
                    .padding(.horizontal, insets: safeAreaInsets)
                    .sheet(isPresented: $isShowingPackageSelection, content: {
                        ShippingLabelPackageSelection(viewModel: viewModel.packageListViewModel)
                    })
                }
                .background(Color(.listForeground(modal: false)))
                .renderedIf(!viewModel.isOriginalPackaging)

                VStack(spacing: 0) {
                    Divider()
                        .padding(.horizontal, insets: safeAreaInsets)
                        .padding(.leading, Constants.horizontalPadding)

                    ValidationErrorRow(errorMessage: Localization.selectPackage)
                        .padding(.horizontal, insets: safeAreaInsets)
                }
                .renderedIf(!viewModel.isOriginalPackaging && viewModel.selectedPackageID.isEmpty)
            }

            VStack(spacing: 0) {
                Divider()
                TitleAndSubtitleRow(title: Localization.originalPackaging,
                                    subtitle: Localization.individuallyShipped)
                    .padding(.horizontal, insets: safeAreaInsets)
            }
            .background(Color(.listForeground(modal: false)))
            .renderedIf(viewModel.isOriginalPackaging)

            VStack(spacing: 0) {
                Divider()
                    .padding(.horizontal, insets: safeAreaInsets)
                    .padding(.leading, Constants.horizontalPadding)
                TitleAndSubtitleRow(title: Localization.itemDimensions,
                                    subtitle: viewModel.originalPackageDimensions,
                                    isError: !viewModel.hasValidPackageDimensions)
                    .padding(.horizontal, insets: safeAreaInsets)
            }
            .background(Color(.listForeground(modal: false)))
            .renderedIf(viewModel.isOriginalPackaging)

            ValidationErrorRow(errorMessage: Localization.invalidDimensions)
                .padding(.horizontal, insets: safeAreaInsets)
                .renderedIf(viewModel.isOriginalPackaging && !viewModel.hasValidPackageDimensions)

            VStack(spacing: 0) {
                VStack {
                    Divider()
                        .padding(.horizontal, insets: safeAreaInsets)
                        .padding(.leading, Constants.horizontalPadding)

                    TitleAndTextFieldRow(title: Localization.totalPackageWeight,
                                         placeholder: "0",
                                         text: $viewModel.totalWeight,
                                         symbol: viewModel.weightUnit,
                                         keyboardType: .decimalPad)
                        .padding(.horizontal, insets: safeAreaInsets)

                    Divider()
                }
                .background(Color(.listForeground(modal: false)))

                if viewModel.isValidTotalWeight {
                    Text(Localization.footer)
                        .footnoteStyle()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, insets: safeAreaInsets)
                        .padding(.horizontal, Constants.horizontalPadding)
                        .padding(.vertical, Constants.verticalSpacing)
                } else {
                    ValidationErrorRow(errorMessage: Localization.invalidWeight)
                        .padding(.horizontal, insets: safeAreaInsets)
                }
            }

            SinglePackageHazmatDeclaration(safeAreaInsets: safeAreaInsets, viewModel: viewModel)
        }
    }
}

private extension ShippingLabelSinglePackage {
    enum Localization {
        static let itemsToFulfillHeader = NSLocalizedString("ITEMS TO FULFILL", comment: "Header section items to fulfill in Shipping Label Package Detail")
        static let packageDetailsHeader = NSLocalizedString("PACKAGE DETAILS", comment: "Header section package details in Shipping Label Package Detail")
        static let packageSelected = NSLocalizedString("Package Selected",
                                                       comment: "Title of the row for selecting a package in Shipping Label Package Detail screen")
        static let selectPackage = NSLocalizedString("Please select a package",
                                                     comment: "Error message when no package is selected on Shipping Label Package Details screen")
        static let totalPackageWeight = NSLocalizedString("Total package weight",
                                                          comment: "Title of the row for adding the package weight in Shipping Label Package Detail screen")
        static let footer = NSLocalizedString("Sum of products and package weight",
                                              comment: "Title of the footer in Shipping Label Package Detail screen")
        static let invalidWeight = NSLocalizedString("Invalid weight", comment: "Error message when total weight is invalid in Package Detail screen")
        static let originalPackaging = NSLocalizedString("Original packaging",
                                                         comment: "Row title for detail of package shipped in original " +
                                                         "packaging on Package Details screen in Shipping Labels flow.")
        static let individuallyShipped = NSLocalizedString("Individually shipped item",
                                                           comment: "Description for detail of package shipped in original " +
                                                           "packaging on Package Details screen in Shipping Labels flow.")
        static let itemDimensions = NSLocalizedString("Item dimensions",
                                                      comment: "Row title for dimensions of package shipped in original " +
                                                      "packaging Package Details screen in Shipping Labels flow.")
        static let invalidDimensions = NSLocalizedString("Package dimensions must be greater than zero. Please update your item’s dimensions in " +
                                                         "the Shipping section of your product page to continue.",
                                                         comment: "Validation error for original package without dimensions " +
                                                         "on Package Details screen in Shipping Labels flow.")
    }

    enum Constants {
        static let horizontalPadding: CGFloat = 16
        static let verticalSpacing: CGFloat = 8
    }
}

#if DEBUG
struct ShippingLabelSinglePackage_Previews: PreviewProvider {
    static var previews: some View {
        let order = ShippingLabelSampleData.sampleOrder()
        let packageResponse = ShippingLabelSampleData.samplePackageDetails()
        let viewModel = ShippingLabelSinglePackageViewModel(order: order,
                                                            orderItems: [],
                                                            packagesResponse: packageResponse,
                                                            selectedPackageID: "Box 1",
                                                            totalWeight: "",
                                                            isOriginalPackaging: false,
                                                            hazmatCategory: .none,
                                                            onItemMoveRequest: {},
                                                            onPackageSwitch: { _ in },
                                                            onPackagesSync: { _ in })
        ShippingLabelSinglePackage(isCollapsible: true,
                                   safeAreaInsets: .zero,
                                   viewModel: viewModel)
    }
}
#endif
