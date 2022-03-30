import SwiftUI

struct ShippingLabelServicePackageList: View {
    @Environment(\.presentationMode) var presentation
    @ObservedObject var viewModel: ShippingLabelServicePackageListViewModel
    let geometry: GeometryProxy

    var body: some View {
        servicePackageListView
            .background(Color(.listBackground))
    }

    @ViewBuilder
    private var servicePackageListView: some View {
        if viewModel.shouldShowEmptyState {
            emptyList
        } else {
            populatedList
        }
    }

    private var emptyList: some View {
        VStack(alignment: .center) {
            EmptyState(title: Localization.emptyStateMessage, image: .waitingForCustomersImage)
                .frame(idealHeight: geometry.size.height)
        }
    }

    private var populatedList: some View {
        LazyVStack(spacing: 0) {
            ListHeaderView(text: Localization.servicePackageHeader, alignment: .left)
                .padding(.horizontal, insets: geometry.safeAreaInsets)

            /// Packages
            ///
            ForEach(viewModel.predefinedOptions, id: \.title) { option in

                ListHeaderView(text: option.title.uppercased(), alignment: .left)
                    .padding(.horizontal, insets: geometry.safeAreaInsets)
                Divider()
                ForEach(option.predefinedPackages) { package in
                    let selected = package == viewModel.selectedPackage
                    SelectableItemRow(title: package.title,
                                      subtitle: package.dimensions + " \(viewModel.dimensionUnit)",
                                      selected: selected)
                        .onTapGesture {
                            viewModel.selectedPackage = package
                        }
                        .padding(.horizontal, insets: geometry.safeAreaInsets)
                        .background(Color(.systemBackground))
                    Divider()
                        .padding(.horizontal, insets: geometry.safeAreaInsets)
                        .padding(.leading, Constants.dividerPadding)
                }
            }
        }
        .ignoresSafeArea(.container, edges: .horizontal)
    }
}

private extension ShippingLabelServicePackageList {
    enum Localization {
        static let servicePackageHeader = NSLocalizedString(
            "Set up the package you'll be using to ship your products. We'll save it for future orders.",
            comment: "Header text on Add New Service Package screen in Shipping Label flow")
        static let emptyStateMessage = NSLocalizedString(
            "All available packages have been activated",
            comment: "Message displayed when there are no packages to display in the Add New Service Package screen in Shipping Label flow")
    }

    enum Constants {
        static let dividerPadding: CGFloat = 48
        static let verticalSpacing: CGFloat = 16
    }
}

#if DEBUG
struct ShippingLabelServicePackageList_Previews: PreviewProvider {
    static var previews: some View {
        let packagesResponse = ShippingLabelSampleData.samplePackageDetails()
        let populatedViewModel = ShippingLabelServicePackageListViewModel(packagesResponse: packagesResponse)
        let emptyViewModel = ShippingLabelServicePackageListViewModel(packagesResponse: nil)

        GeometryReader { geometry in
            ShippingLabelServicePackageList(viewModel: populatedViewModel, geometry: geometry)
        }

        GeometryReader { geometry in
            ShippingLabelServicePackageList(viewModel: emptyViewModel, geometry: geometry)
                .previewDisplayName("Empty State")
        }
    }
}
#endif
