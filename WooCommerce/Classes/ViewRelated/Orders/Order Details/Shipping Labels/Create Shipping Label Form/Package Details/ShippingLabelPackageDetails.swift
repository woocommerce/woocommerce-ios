import SwiftUI
import Yosemite

struct ShippingLabelPackageDetails: View {
    @ObservedObject private var viewModel: ShippingLabelPackageDetailsViewModel
    @State private var showingPackageSelection = false
    @Environment(\.presentationMode) var presentation

    init(viewModel: ShippingLabelPackageDetailsViewModel) {
        self.viewModel = viewModel
        ServiceLocator.analytics.track(.shippingLabelPurchaseFlow, withProperties: ["state": "packages_started"])
    }

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                LazyVStack(spacing: 0) {
                    VStack(spacing: 0) {
                        ShippingLabelPackageNumberRow(packageNumber: 1, numberOfItems: viewModel.itemsRows.count)
                            .frame(height: Constants.packageNumberRowHeight)
                            .padding([.leading, .trailing], Constants.horizontalPadding)
                            .padding(.horizontal, insets: geometry.safeAreaInsets)

                        Divider()
                    }
                    .background(Color(.systemBackground))

                    ListHeaderView(text: Localization.itemsToFulfillHeader, alignment: .left)
                        .padding(.horizontal, insets: geometry.safeAreaInsets)

                    Divider()

                    ForEach(viewModel.itemsRows) { productItemRow in
                        productItemRow
                            .padding(.horizontal, insets: geometry.safeAreaInsets)
                            .background(Color(.systemBackground))
                        Divider()
                            .padding(.horizontal, insets: geometry.safeAreaInsets)
                            .padding(.leading, Constants.horizontalPadding)
                    }

                    ListHeaderView(text: Localization.packageDetailsHeader, alignment: .left)
                        .padding(.horizontal, insets: geometry.safeAreaInsets)

                    VStack(spacing: 0) {
                        Divider()

                        TitleAndValueRow(title: Localization.packageSelected, value: .placeholder(viewModel.selectedPackageName), selectionStyle: .disclosure) {
                            showingPackageSelection.toggle()
                        }
                        .padding(.horizontal, insets: geometry.safeAreaInsets)
                        .sheet(isPresented: $showingPackageSelection, content: {
                            ShippingLabelPackageSelection(viewModel: viewModel.packageListViewModel)
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
                .padding(.bottom, insets: geometry.safeAreaInsets)
            }
            .background(Color(.listBackground))
            .ignoresSafeArea(.container, edges: [.horizontal, .bottom])
        }
        .navigationTitle(Localization.title)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button(action: {
                    ServiceLocator.analytics.track(.shippingLabelPurchaseFlow,
                                                   withProperties: ["state": "packages_selected"])
                    viewModel.savePackageSelection()
                    presentation.wrappedValue.dismiss()
                }, label: {
                    Text(Localization.doneButton)
                })
                .disabled(!viewModel.isPackageDetailsDoneButtonEnabled())
            }
        }
        .wooNavigationBarStyle()
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
        static let packageNumberRowHeight: CGFloat = 44
        static let horizontalPadding: CGFloat = 16
    }
}

#if DEBUG
struct ShippingLabelPackageDetails_Previews: PreviewProvider {

    static var previews: some View {

        let viewModel = ShippingLabelPackageDetailsViewModel(order: ShippingLabelSampleData.sampleOrder(),
                                                             packagesResponse: ShippingLabelSampleData.samplePackageDetails(),
                                                             selectedPackages: [],
                                                             onPackageSyncCompletion: { _ in },
                                                             onPackageSaveCompletion: { _ in })

        ShippingLabelPackageDetails(viewModel: viewModel)
        .environment(\.colorScheme, .light)
        .previewDisplayName("Light")

        ShippingLabelPackageDetails(viewModel: viewModel)
        .environment(\.colorScheme, .dark)
        .previewDisplayName("Dark")
    }
}
#endif
