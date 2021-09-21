import SwiftUI

struct ShippingLabelSinglePackage: View {

    @ObservedObject private var viewModel: ShippingLabelSinglePackageViewModel
    @State private var isCollapsed: Bool = false
    @State private var isShowingPackageSelection = false

    private let isCollapsible: Bool
    private let packageNumber: Int
    private let safeAreaInsets: EdgeInsets

    init(packageNumber: Int,
         isCollapsible: Bool,
         safeAreaInsets: EdgeInsets,
         viewModel: ShippingLabelSinglePackageViewModel) {
        self.packageNumber = packageNumber
        self.isCollapsible = isCollapsible
        self.safeAreaInsets = safeAreaInsets
        self.viewModel = viewModel
        self.isCollapsed = packageNumber > 1
    }

    var body: some View {
        CollapsibleView(isCollapsible: isCollapsible, isCollapsed: $isCollapsed, safeAreaInsets: safeAreaInsets) {
            ShippingLabelPackageNumberRow(packageNumber: packageNumber, numberOfItems: viewModel.itemsRows.count, isValid: viewModel.isValidTotalWeight)
        } content: {
            ListHeaderView(text: Localization.itemsToFulfillHeader, alignment: .left)
                .padding(.horizontal, insets: safeAreaInsets)

            Divider()

            ForEach(viewModel.itemsRows) { productItemRow in
                productItemRow
                    .onTapGesture {
                        viewModel.requestMovingItem(id: productItemRow.id)
                    }
                    .padding(.horizontal, insets: safeAreaInsets)
                    .background(Color(.systemBackground))
                Divider()
                    .padding(.horizontal, insets: safeAreaInsets)
                    .padding(.leading, Constants.dividerPadding)
            }

            ListHeaderView(text: Localization.packageDetailsHeader, alignment: .left)
                .padding(.horizontal, insets: safeAreaInsets)

            VStack(spacing: 0) {
                Divider()

                TitleAndValueRow(title: Localization.packageSelected, value: viewModel.selectedPackageName, selectable: true) {
                    isShowingPackageSelection.toggle()
                }
                .padding(.horizontal, insets: safeAreaInsets)
                .sheet(isPresented: $isShowingPackageSelection, content: {
                    ShippingLabelPackageSelection(viewModel: viewModel.packageListViewModel)
                })

                Divider()

                TitleAndTextFieldRow(title: Localization.totalPackageWeight,
                                     placeholder: "0",
                                     text: $viewModel.totalWeight,
                                     symbol: viewModel.weightUnit,
                                     keyboardType: .decimalPad)
                    .padding(.horizontal, insets: safeAreaInsets)

                Divider()
            }
            .background(Color(.systemBackground))

            if viewModel.isValidTotalWeight {
                ListHeaderView(text: Localization.footer, alignment: .left)
                    .padding(.horizontal, insets: safeAreaInsets)
            } else {
                ValidationErrorRow(errorMessage: Localization.invalidWeight)
                    .padding(.horizontal, insets: safeAreaInsets)
            }
        }
    }
}

private extension ShippingLabelSinglePackage {
    enum Localization {
        static let itemsToFulfillHeader = NSLocalizedString("ITEMS TO FULFILL", comment: "Header section items to fulfill in Shipping Label Package Detail")
        static let packageDetailsHeader = NSLocalizedString("PACKAGE DETAILS", comment: "Header section package details in Shipping Label Package Detail")
        static let packageSelected = NSLocalizedString("Package Selected",
                                                       comment: "Title of the row for selecting a package in Shipping Label Package Detail screen")
        static let totalPackageWeight = NSLocalizedString("Total package weight",
                                                          comment: "Title of the row for adding the package weight in Shipping Label Package Detail screen")
        static let footer = NSLocalizedString("Sum of products and package weight",
                                              comment: "Title of the footer in Shipping Label Package Detail screen")
        static let invalidWeight = NSLocalizedString("Invalid weight", comment: "Error message when total weight is invalid in Package Detail screen")
    }

    enum Constants {
        static let dividerPadding: CGFloat = 16
    }
}

struct ShippingLabelPackageItem_Previews: PreviewProvider {
    static var previews: some View {
        let order = ShippingLabelPackageDetailsViewModel.sampleOrder()
        let packageResponse = ShippingLabelPackageDetailsViewModel.samplePackageDetails()
        let viewModel = ShippingLabelSinglePackageViewModel(order: order,
                                                          orderItems: order.items,
                                                          packagesResponse: packageResponse,
                                                          selectedPackageID: "Box 1",
                                                          totalWeight: "",
                                                          products: [],
                                                          productVariations: [],
                                                          onItemMoveRequest: { _, _ in },
                                                          onPackageSwitch: { _ in },
                                                          onPackagesSync: { _ in })
        ShippingLabelSinglePackage(packageNumber: 1, isCollapsible: true, safeAreaInsets: .zero, viewModel: viewModel)
    }
}
