import SwiftUI
import Yosemite

struct ShippingLabelPackageList: View {
    @ObservedObject private var viewModel: ShippingLabelPackageListViewModel

    private var onPackageSelected: ((ShippingLabelCustomPackage?, ShippingLabelPredefinedPackage?) -> Void)?

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {

                /// Custom Packages
                ///
                if viewModel.customPackages.count > 0 {
                    ListHeaderView(text: Localization.customPackageHeader.uppercased(), alignment: .left)
                        .background(Color(.listBackground))
                }
                ForEach(viewModel.customPackages, id: \.title) { package in
                    let selected = package == viewModel.selectedCustomPackage
                    SelectableItemRow(title: package.title, subtitle: package.dimensions + " \(viewModel.dimensionUnit)", selected: selected).onTapGesture {
                        viewModel.didSelectCustomPackage(package)
                    }
                    Divider().padding(.leading, Constants.dividerPadding)
                }

                /// Predefined Packages
                ///
                ForEach(viewModel.predefinedOptions, id: \.title) { option in

                    ListHeaderView(text: option.title.uppercased(), alignment: .left)
                        .background(Color(.listBackground))
                    ForEach(option.predefinedPackages, id: \.id) { package in
                        let selected = package == viewModel.selectedPredefinedPackage
                        SelectableItemRow(title: package.title, subtitle: package.dimensions + " \(viewModel.dimensionUnit)", selected: selected).onTapGesture {
                            viewModel.didSelectPredefinedPackage(package)
                        }
                        Divider().padding(.leading, Constants.dividerPadding)
                    }
                }
            }
            .background(Color(.systemBackground))
        }
        .background(Color(.listBackground))
        .navigationBarTitle(Text(Localization.title), displayMode: .inline)
        .navigationBarItems(trailing: Button(action: {
            onPackageSelected?(viewModel.selectedCustomPackage, viewModel.selectedPredefinedPackage)
        }, label: {
            Text(Localization.doneButton)
        }))
    }

    init(viewModel: ShippingLabelPackageListViewModel, onPackageSelected: @escaping (ShippingLabelCustomPackage?, ShippingLabelPredefinedPackage?) -> Void) {
        self.viewModel = viewModel
        self.onPackageSelected = onPackageSelected
    }
}

private extension ShippingLabelPackageList {
    enum Localization {
        static let title = NSLocalizedString("Package Selected", comment: "Package Selected screen title in Shipping Label flow")
        static let doneButton = NSLocalizedString("Done", comment: "Done navigation button under the Package Selected screen in Shipping Label flow")
        static let customPackageHeader = NSLocalizedString("CUSTOM PACKAGES",
                                                           comment: "Header for the Custom Packages section in Shipping Label Package listing")
    }

    enum Constants {
        static let dividerPadding: CGFloat = 48
    }
}

struct ShippingLabelPackageList_Previews: PreviewProvider {
    static var previews: some View {
        let storeOptions = ShippingLabelStoreOptions(currencySymbol: "$",
                                                     dimensionUnit: "in",
                                                     weightUnit: "oz",
                                                     originCountry: "US")

        let customPackages = [
            ShippingLabelCustomPackage(isUserDefined: true,
                                       title: "Box",
                                       isLetter: true,
                                       dimensions: "3 x 10 x 4",
                                       boxWeight: 10,
                                       maxWeight: 11),
            ShippingLabelCustomPackage(isUserDefined: true,
                                       title: "Box n°2",
                                       isLetter: true,
                                       dimensions: "30 x 1 x 20",
                                       boxWeight: 2,
                                       maxWeight: 4),
            ShippingLabelCustomPackage(isUserDefined: true,
                                       title: "Box n°3",
                                       isLetter: true,
                                       dimensions: "10 x 40 x 3",
                                       boxWeight: 7,
                                       maxWeight: 10)]


        let predefinedOptions = [ShippingLabelPredefinedOption(title: "USPS", predefinedPackages: [ShippingLabelPredefinedPackage(id: "package-1",
                                                                                                                                  title: "Small",
                                                                                                                                  isLetter: true,
                                                                                                                                  dimensions: "3 x 4 x 5"),
                                                                                                   ShippingLabelPredefinedPackage(id: "package-2",
                                                                                                                                  title: "Big",
                                                                                                                                  isLetter: true,
                                                                                                                                  dimensions: "5 x 7 x 9")])]

        let packagesResponse = ShippingLabelPackagesResponse(storeOptions: storeOptions, customPackages: customPackages, predefinedOptions: predefinedOptions)

        let viewModel = ShippingLabelPackageListViewModel(packagesResponse: packagesResponse)

        ShippingLabelPackageList(viewModel: viewModel) { (customPackage, predefinedPackage) in
        }
    }
}
