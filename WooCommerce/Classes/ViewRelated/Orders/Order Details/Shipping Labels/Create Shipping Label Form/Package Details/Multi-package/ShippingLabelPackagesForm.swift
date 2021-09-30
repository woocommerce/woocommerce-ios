import SwiftUI

struct ShippingLabelPackagesForm: View {
    @ObservedObject private var viewModel: ShippingLabelPackagesFormViewModel
    @Environment(\.presentationMode) var presentation
    @State private var showingMoveItemActionSheet: Bool = false

    init(viewModel: ShippingLabelPackagesFormViewModel) {
        self.viewModel = viewModel
        ServiceLocator.analytics.track(.shippingLabelPurchaseFlow, withProperties: ["state": "packages_started"])
    }

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                ForEach(Array(viewModel.itemViewModels.enumerated()), id: \.offset) { index, element in
                    ShippingLabelSinglePackage(packageNumber: index + 1,
                                             isCollapsible: viewModel.foundMultiplePackages,
                                             safeAreaInsets: geometry.safeAreaInsets,
                                             shouldShowMoveItemActionSheet: $showingMoveItemActionSheet,
                                             viewModel: element)
                }
                .padding(.bottom, insets: geometry.safeAreaInsets)
            }
            .background(Color(.listBackground))
            .ignoresSafeArea(.container, edges: [.horizontal, .bottom])
        }
        .actionSheet(isPresented: $showingMoveItemActionSheet, content: {
            ActionSheet(title: Text(viewModel.moveItemActionSheetMessage),
                        buttons: viewModel.moveItemActionSheetButtons)
        })
        .navigationTitle(Localization.title)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    ServiceLocator.analytics.track(.shippingLabelPurchaseFlow,
                                                   withProperties: ["state": "packages_selected"])
                    viewModel.confirmPackageSelection()
                    presentation.wrappedValue.dismiss()
                }, label: {
                    Text(Localization.doneButton)
                })
                .disabled(!viewModel.doneButtonEnabled)
            }
        }
    }
}

private extension ShippingLabelPackagesForm {
    enum Localization {
        static let title = NSLocalizedString("Package Details",
                                             comment: "Navigation bar title of shipping label package details screen")
        static let doneButton = NSLocalizedString("Done", comment: "Done navigation button in the Package Details screen in Shipping Label flow")
        static let moveItemTitle = NSLocalizedString("Move Item",
                                                     comment: "Title of the action sheet displayed when moving items in the" +
                                                        "Package Details screen in Shipping Label flow.")
    }

    enum Constants {
        static let dividerPadding: CGFloat = 16
    }
}

struct ShippingLabelPackagesForm_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = ShippingLabelPackagesFormViewModel(order: ShippingLabelPackagesFormViewModel.sampleOrder(),
                                                           packagesResponse: ShippingLabelPackagesFormViewModel.samplePackageDetails(),
                                                           selectedPackages: [],
                                                           onSelectionCompletion: { _ in },
                                                           onPackageSyncCompletion: { _ in })

        ShippingLabelPackagesForm(viewModel: viewModel)
        .environment(\.colorScheme, .light)
        .previewDisplayName("Light")

        ShippingLabelPackagesForm(viewModel: viewModel)
        .environment(\.colorScheme, .dark)
        .previewDisplayName("Dark")
    }
}
