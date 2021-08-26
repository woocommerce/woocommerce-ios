import SwiftUI

struct ShippingLabelServicePackageList: View {
    private let safeAreaInsets: EdgeInsets

    @Environment(\.presentationMode) var presentation
    @ObservedObject var viewModel: ShippingLabelServicePackageListViewModel

    init(viewModel: ShippingLabelServicePackageListViewModel,
         safeAreaInsets: EdgeInsets) {
        self.viewModel = viewModel
        self.safeAreaInsets = safeAreaInsets
    }

    var body: some View {
        LazyVStack(spacing: 0) {
            ListHeaderView(text: Localization.servicePackageHeader, alignment: .left)
                .padding(.horizontal, insets: safeAreaInsets)

            /// Packages
            ///
            ForEach(viewModel.predefinedOptions, id: \.title) { option in

                ListHeaderView(text: option.title.uppercased(), alignment: .left)
                    .padding(.horizontal, insets: safeAreaInsets)
                ForEach(option.predefinedPackages) { package in
                    let selected = package == viewModel.selectedPackage
                    SelectableItemRow(title: package.title,
                                      subtitle: package.dimensions + " \(viewModel.dimensionUnit)",
                                      selected: selected)
                        .onTapGesture {
                            viewModel.selectedPackage = package
                        }
                        .padding(.horizontal, insets: safeAreaInsets)
                        .background(Color(.systemBackground))
                    Divider().padding(.leading, Constants.horizontalPadding)
                }
            }
        }
        .background(Color(.listBackground))
        .ignoresSafeArea(.container, edges: .horizontal)
        .minimalNavigationBarBackButton()
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing, content: {
                Button(Localization.doneButton, action: {
                    // TODO-4744: Add selected service package and go back to package list
                    presentation.wrappedValue.dismiss()
                })
            })
        }
    }
}

private extension ShippingLabelServicePackageList {
    enum Localization {
        static let servicePackageHeader = NSLocalizedString(
            "Set up the package you'll be using to ship your products. We'll save it for future orders.",
            comment: "Header text on Add New Custom Package screen in Shipping Label flow")
        static let doneButton = NSLocalizedString("Done", comment: "Done navigation button in the Custom Package screen in Shipping Label flow")
    }

    enum Constants {
        static let horizontalPadding: CGFloat = 16
        static let verticalSpacing: CGFloat = 16
    }
}

struct ShippingLabelServicePackageList_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = ShippingLabelServicePackageListViewModel(packagesResponse: ShippingLabelPackageDetailsViewModel.samplePackageDetails())

        ShippingLabelServicePackageList(viewModel: viewModel, safeAreaInsets: .zero)
            .previewLayout(.sizeThatFits)
    }
}
