import SwiftUI
import Yosemite

struct ShippingLabelPackageList: View {
    @EnvironmentObject private var viewModel: ShippingLabelPackageDetailsViewModel

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
                        viewModel.didSelectPackage(package.title)
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
                            viewModel.didSelectPackage(package.id)
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
            viewModel.confirmPackageSelection()
        }, label: {
            Text(Localization.doneButton)
        }))
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
        let viewModel = ShippingLabelPackageDetailsViewModel(order: ShippingLabelPackageDetailsViewModel.sampleOrder())

        ShippingLabelPackageList().environmentObject(viewModel)
    }
}
