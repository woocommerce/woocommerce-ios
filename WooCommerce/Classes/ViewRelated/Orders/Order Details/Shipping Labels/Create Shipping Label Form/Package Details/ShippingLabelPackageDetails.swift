import SwiftUI
import Yosemite

struct ShippingLabelPackageDetails: View {
    @ObservedObject private var viewModel: ShippingLabelPackageDetailsViewModel
    @State private var showingAddPackage = false
    @Environment(\.presentationMode) var presentation

    /// Completion callback
    ///
    typealias Completion = (_ selectedPackageID: String?, _ totalPackageWeight: String?) -> Void
    private let onCompletion: Completion

    init(viewModel: ShippingLabelPackageDetailsViewModel, completion: @escaping Completion) {
        self.viewModel = viewModel
        onCompletion = completion
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

                TitleAndValueRow(title: Localization.packageSelected, value: viewModel.selectedPackageName, selectable: true) {
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
                                     text: $viewModel.totalWeight,
                                     symbol: viewModel.weightUnit,
                                     keyboardType: .decimalPad)
                Divider()

                ListHeaderView(text: Localization.footer, alignment: .left)
                    .background(Color(.listBackground))
            }
            .background(Color(.systemBackground))
        }
        .background(Color(.listBackground))
        .navigationBarItems(trailing: Button(action: {
            onCompletion(viewModel.selectedPackageID, viewModel.totalWeight)
            presentation.wrappedValue.dismiss()
        }, label: {
            Text(Localization.doneButton)
        }))
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
        static let doneButton = NSLocalizedString("Done", comment: "Done navigation button in the Package Details screen in Shipping Label flow")
    }

    enum Constants {
        static let dividerPadding: CGFloat = 16
    }
}

struct ShippingLabelPackageDetails_Previews: PreviewProvider {

    static var previews: some View {

        let viewModel = ShippingLabelPackageDetailsViewModel(order: ShippingLabelPackageDetailsViewModel.sampleOrder(),
                                                             packagesResponse: ShippingLabelPackageDetailsViewModel.samplePackageDetails())

        ShippingLabelPackageDetails(viewModel: viewModel, completion: { (selectedPackageID, totalPackageWeight) in
        })
        .environment(\.colorScheme, .light)
        .previewDisplayName("Light")

        ShippingLabelPackageDetails(viewModel: viewModel, completion: { (selectedPackageID, totalPackageWeight) in
        })
        .environment(\.colorScheme, .dark)
        .previewDisplayName("Dark")
    }
}
