import SwiftUI
import Yosemite

struct ShippingLabelPackageList: View {
    @ObservedObject var viewModel: ShippingLabelPackageDetailsViewModel
    @Environment(\.presentationMode) var presentation
    @State private var isShowingNewPackageCreation = false

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        /// Custom Packages
                        ///
                        if viewModel.showCustomPackagesHeader {
                            ListHeaderView(text: Localization.customPackageHeader.uppercased(), alignment: .left)
                                .padding(.horizontal, insets: geometry.safeAreaInsets)
                        }
                        ForEach(viewModel.customPackages, id: \.title) { package in
                            let selected = package == viewModel.selectedCustomPackage
                            SelectableItemRow(title: package.title, subtitle: package.dimensions + " \(viewModel.dimensionUnit)", selected: selected)
                                .onTapGesture {
                                    viewModel.didSelectPackage(package.title)
                                    ServiceLocator.analytics.track(.shippingLabelPurchaseFlow, withProperties: ["state": "packages_selected"])
                                }
                                .padding(.horizontal, insets: geometry.safeAreaInsets)
                                .background(Color(.systemBackground))
                            Divider().padding(.leading, Constants.dividerPadding)
                        }

                        /// Predefined Packages
                        ///
                        ForEach(viewModel.predefinedOptions, id: \.title) { option in

                            ListHeaderView(text: option.title.uppercased(), alignment: .left)
                                .padding(.horizontal, insets: geometry.safeAreaInsets)
                            ForEach(option.predefinedPackages) { package in
                                let selected = package == viewModel.selectedPredefinedPackage
                                SelectableItemRow(title: package.title,
                                                  subtitle: package.dimensions + " \(viewModel.dimensionUnit)",
                                                  selected: selected).onTapGesture {
                                                    viewModel.didSelectPackage(package.id)
                                                    ServiceLocator.analytics.track(.shippingLabelPurchaseFlow,
                                                                                   withProperties: ["state": "packages_selected"])
                                                  }
                                    .padding(.horizontal, insets: geometry.safeAreaInsets)
                                    .background(Color(.systemBackground))
                                Divider().padding(.leading, Constants.dividerPadding)
                            }
                        }
                    }
                }
                .background(Color(.listBackground))
                .ignoresSafeArea(.container, edges: .horizontal)
                .dynamicNavigationTitle(hidden: $isShowingNewPackageCreation, title: Localization.title)
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarItems(trailing: Button(action: {
                    viewModel.confirmPackageSelection()
                    presentation.wrappedValue.dismiss()
                }, label: {
                    Text(Localization.doneButton)
                }))

                if ServiceLocator.featureFlagService.isFeatureFlagEnabled(.shippingLabelsAddCustomPackages) {
                    NavigationLink(destination: ShippingLabelAddNewPackage(), isActive: $isShowingNewPackageCreation) {
                        EmptyView()
                    }
                    BottomButtonView(style: LinkButtonStyle(),
                                     title: Localization.createPackageButton,
                                     image: .plusImage,
                                     onButtonTapped: {
                                        self.isShowingNewPackageCreation = true
                                     })
                }
            }
        }
    }
}

private extension ShippingLabelPackageList {
    enum Localization {
        static let title = NSLocalizedString("Package Selected", comment: "Package Selected screen title in Shipping Label flow")
        static let doneButton = NSLocalizedString("Done", comment: "Done navigation button under the Package Selected screen in Shipping Label flow")
        static let customPackageHeader = NSLocalizedString("CUSTOM PACKAGES",
                                                           comment: "Header for the Custom Packages section in Shipping Label Package listing")
        static let createPackageButton = NSLocalizedString("Create new package", comment: "Button to create a new package in Shipping Label Package screen")
    }

    enum Constants {
        static let dividerPadding: CGFloat = 48
    }
}

struct ShippingLabelPackageList_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = ShippingLabelPackageDetailsViewModel(order: ShippingLabelPackageDetailsViewModel.sampleOrder(),
                                                             packagesResponse: ShippingLabelPackageDetailsViewModel.samplePackageDetails(),
                                                             selectedPackageID: nil,
                                                             totalWeight: nil)

        ShippingLabelPackageList(viewModel: viewModel)
    }
}
