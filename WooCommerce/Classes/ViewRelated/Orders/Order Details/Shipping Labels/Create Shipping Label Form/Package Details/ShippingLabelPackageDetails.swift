import SwiftUI
import Yosemite

struct ShippingLabelPackageDetails: View {
    @ObservedObject private var viewModel: ShippingLabelPackageDetailsViewModel
    @State private var showingPackageList = false
    @State private var showingAddPackage = false
    @Environment(\.presentationMode) var presentation

    /// Completion callback
    ///
    typealias Completion = (_ selectedPackageID: String?, _ totalPackageWeight: String?) -> Void
    private let onCompletion: Completion

    init(viewModel: ShippingLabelPackageDetailsViewModel, completion: @escaping Completion) {
        self.viewModel = viewModel
        onCompletion = completion
        ServiceLocator.analytics.track(.shippingLabelPurchaseFlow, withProperties: ["state": "packages_started"])
    }

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                LazyVStack(spacing: 0) {
                    VStack(spacing: 0) {
                        ShippingLabelPackageNumberRow(packageNumber: 1, numberOfItems: viewModel.itemsRows.count)
                            .padding(.horizontal, insets: geometry.safeAreaInsets)

                        Divider()
                    }
                    .background(Color(.systemBackground))

                    ListHeaderView(text: Localization.itemsToFulfillHeader, alignment: .left)
                        .padding(.horizontal, insets: geometry.safeAreaInsets)

                    ForEach(viewModel.itemsRows) { productItemRow in
                        productItemRow
                            .padding(.horizontal, insets: geometry.safeAreaInsets)
                            .background(Color(.systemBackground))
                        Divider()
                            .padding(.horizontal, insets: geometry.safeAreaInsets)
                            .padding(.leading, Constants.dividerPadding)
                    }

                    ListHeaderView(text: Localization.packageDetailsHeader, alignment: .left)
                        .padding(.horizontal, insets: geometry.safeAreaInsets)

                    VStack(spacing: 0) {
                        Divider()

                        TitleAndValueRow(title: Localization.packageSelected, value: viewModel.selectedPackageName, selectable: true) {
                            if viewModel.hasCustomOrPredefinedPackages() {
                                showingPackageList.toggle()
                            } else {
                                showingAddPackage.toggle()
                            }
                        }
                        .padding(.horizontal, insets: geometry.safeAreaInsets)
                        .sheet(isPresented: $showingPackageList, content: {
                            ShippingLabelPackageList(viewModel: viewModel)
                        })
                        .sheet(isPresented: $showingAddPackage, content: {
                            ShippingLabelAddNewPackage()
                        })

                        Divider()

                        TitleAndTextFieldRow(title: Localization.totalPackageWeight,
                                             placeholder: "0",
                                             text: $viewModel.totalWeight,
                                             symbol: viewModel.weightUnit,
                                             keyboardType: .decimalPad)
                            .padding(.horizontal, insets: geometry.safeAreaInsets)

                        Divider()
                    }
                    .background(Color(.systemBackground))

                    ListHeaderView(text: Localization.footer, alignment: .left)
                        .padding(.horizontal, insets: geometry.safeAreaInsets)
                }
            }
            .background(Color(.listBackground))
            .ignoresSafeArea(.container, edges: .horizontal)
        }
        .navigationTitle(Localization.title)
        .navigationBarItems(trailing: Button(action: {
            onCompletion(viewModel.selectedPackageID, viewModel.totalWeight)
            presentation.wrappedValue.dismiss()
        }, label: {
            Text(Localization.doneButton)
        })
        .disabled(!viewModel.isPackageDetailsDoneButtonEnabled()))
    }
}

private extension ShippingLabelPackageDetails {
    enum Localization {
        static let title = NSLocalizedString("Package Details",
                                             comment: "Navigation bar title of shipping label package details screen")
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
                                                             packagesResponse: ShippingLabelPackageDetailsViewModel.samplePackageDetails(),
                                                             selectedPackageID: nil,
                                                             totalWeight: nil)

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
