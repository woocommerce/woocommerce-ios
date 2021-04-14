import SwiftUI
import Yosemite

struct ShippingLabelServicePackages: View {
    private let viewModel = ShippingLabelServicePackagesViewModel()

    private let state: ShippingLabelAddNewPackageViewModel.State
    private let customPackages: [ShippingLabelCustomPackage]
    private let predefinedOptions: [ShippingLabelPredefinedOption]

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {

                /// Custom Packages
                ///
                if customPackages.count > 0 {
                    ListHeaderView(text: Localization.customPackageHeader, alignment: .left)
                        .background(Color(.listBackground))
                }
                ForEach(customPackages, id: \.title) { package in
                    SelectableItemRow(title: package.title, subtitle: package.dimensions, selected: false)
                    Divider().padding(.leading, 48)
                }

                /// Predefined Packages
                ///
                ForEach(predefinedOptions, id: \.title) { option in

                    ListHeaderView(text: option.title.uppercased(), alignment: .left)
                        .background(Color(.listBackground))
                    ForEach(option.predefinedPackages, id: \.id) { package in
                        SelectableItemRow(title: package.title, subtitle: package.dimensions, selected: false)
                        Divider().padding(.leading, Constants.dividerPadding)
                    }
                }
            }
        }
    }

    init(state: ShippingLabelAddNewPackageViewModel.State,
         customPackages: [ShippingLabelCustomPackage],
         predefinedOptions: [ShippingLabelPredefinedOption]) {
        self.state = state
        self.customPackages = customPackages
        self.predefinedOptions = predefinedOptions
    }
}

private extension ShippingLabelServicePackages {
    enum Localization {
        static let customPackageHeader = NSLocalizedString("CUSTOM PACKAGES",
                                                           comment: "Header for the Custom Packages section in Shipping Label Package listing")
    }
    
    enum Constants {
        static let dividerPadding: CGFloat = 48
    }
}

struct ShippingLabelServicePackages_Previews: PreviewProvider {
    static var previews: some View {
        let customPackages = [
            ShippingLabelCustomPackage(isUserDefined: true, title: "Box", isLetter: true, dimensions: "3 x 10 x 4", boxWeight: 10, maxWeight: 11),
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


        let predefinedOptions = ShippingLabelPredefinedOption(title: "UPS", predefinedPackages: [ShippingLabelPredefinedPackage(id: "package-1",
                                                                                                                                title: "Small",
                                                                                                                                isLetter: true,
                                                                                                                                dimensions: "3 x 4 x 5"),
                                                                                                 ShippingLabelPredefinedPackage(id: "package-2",
                                                                                                                                title: "Big",
                                                                                                                                isLetter: true,
                                                                                                                                dimensions: "5 x 7 x 9")])

        ShippingLabelServicePackages(state: .results,
                                     customPackages: customPackages,
                                     predefinedOptions: [predefinedOptions])
    }
}
