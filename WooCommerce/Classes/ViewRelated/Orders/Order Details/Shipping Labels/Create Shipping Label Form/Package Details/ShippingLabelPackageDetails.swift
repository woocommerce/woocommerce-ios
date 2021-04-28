import SwiftUI
import Yosemite

struct ShippingLabelPackageDetails: View {
    @ObservedObject private var viewModel: ShippingLabelPackageDetailsViewModel
    @State private var showingAddPackage = false

    init(viewModel: ShippingLabelPackageDetailsViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                ShippingLabelPackageNumberRow(packageNumber: 1, numberOfItems: viewModel.itemsRows.count)

                ListHeaderView(text: Localization.itemsToFulfillHeader, alignment: .left)
                    .background(Color(.listBackground))

                ForEach(viewModel.itemsRows) { productItemRow in
                    Divider().padding(.leading, Constants.dividerPadding)
                    productItemRow
                }

                ListHeaderView(text: Localization.packageDetailsHeader, alignment: .left)
                    .background(Color(.listBackground))

                TitleAndValueRow(title: Localization.packageSelected, value: viewModel.selectedPackageID ?? "", selectable: true) {
                    showingAddPackage.toggle()
                }

                NavigationLink(
                    destination:
                        ShippingLabelPackageList(viewModel: viewModel),
                    isActive: $showingAddPackage) { EmptyView()
                }
                Divider()

                TitleAndTextFieldRow(title: Localization.totalPackageWeight,
                                     placeholder: "0",
                                     text: .constant(""),
                                     symbol: viewModel.weightUnit,
                                     keyboardType: .decimalPad)
                Divider()

                ListHeaderView(text: Localization.footer, alignment: .left)
                    .background(Color(.listBackground))
            }
            .background(Color(.systemBackground))
        }
        .background(Color(.listBackground))
    }
}

private extension ShippingLabelPackageDetails {
    enum Localization {
        static let itemsToFulfillHeader = NSLocalizedString("ITEMS TO FULFILL", comment: "Header section items to fulfill in Shipping Label Package Detail")
        static let packageDetailsHeader = NSLocalizedString("PACKAGE DETAILS", comment: "Header section package details in Shipping Label Package Detail")
        static let packageSelected = NSLocalizedString("Package Selected",
                                                       comment: "Title of the row for selecting a package in Shipping Label Package Detail screen")
        static let totalPackageWeight = NSLocalizedString("Total package weight",
                                                          comment: "Title of the row for adding the package weight in Shipping Label Package Detail screen")
        static let footer = NSLocalizedString("Sum of products and package weight",
                                              comment: "Title of the footer in Shipping Label Package Detail screen")
    }

    enum Constants {
        static let dividerPadding: CGFloat = 16
    }
}

struct ShippingLabelPackageDetails_Previews: PreviewProvider {

    static var previews: some View {

        let viewModel = ShippingLabelPackageDetailsViewModel(order: ShippingLabelPackageDetailsViewModel.sampleOrder())

        ShippingLabelPackageDetails(viewModel: viewModel)
            .environment(\.colorScheme, .light)
            .previewDisplayName("Light")

        ShippingLabelPackageDetails(viewModel: viewModel)
            .environment(\.colorScheme, .dark)
            .previewDisplayName("Dark")
    }
}
