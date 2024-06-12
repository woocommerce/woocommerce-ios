import SwiftUI

// MARK: Hosting Controller

/// Hosting controller that wraps a `QuantityRules` view.
///
final class QuantityRulesViewController: UIHostingController<QuantityRules> {
    init(viewModel: QuantityRulesViewModel) {
        super.init(rootView: QuantityRules(viewModel: viewModel))
    }

    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

struct QuantityRules: View {

    /// View model that directs the view content.
    ///
    @ObservedObject var viewModel: QuantityRulesViewModel

    /// Environment safe areas
    ///
    @Environment(\.safeAreaInsets) private var safeAreaInsets: EdgeInsets

    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                TitleAndTextFieldRow(title: Localization.minQuantity,
                                     placeholder: Localization.noMinQuantity,
                                     text: $viewModel.minQuantity,
                                     keyboardType: .asciiCapableNumberPad)
                Divider()
                    .padding(.leading)
                    .padding(.trailing, insets: -safeAreaInsets)

                // Maximum quantity
                TitleAndTextFieldRow(title: Localization.maxQuantity,
                                     placeholder: Localization.noMaxQuantity,
                                     text: $viewModel.maxQuantity,
                                     keyboardType: .asciiCapableNumberPad)
                Divider()
                    .padding(.leading)
                    .padding(.trailing, insets: -safeAreaInsets)

                // Group of
                TitleAndTextFieldRow(title: Localization.groupOf,
                                     placeholder: Localization.noGroupOfQuantity,
                                     text: $viewModel.groupOf,
                                     keyboardType: .asciiCapableNumberPad)
            }
            .padding(.horizontal, insets: safeAreaInsets)
            .addingTopAndBottomDividers()
            .background(Color(.listForeground(modal: false)))
        }
        .navigationBarTitle(Localization.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button(Localization.done) {
                    viewModel.onDoneButtonPressed()
                }
            }
        }
        .ignoresSafeArea(edges: .horizontal)
        .background(
            Color(.listBackground).edgesIgnoringSafeArea(.all)
        )
    }
}

private extension QuantityRules {
    enum Localization {
        static let title = NSLocalizedString("Quantity Rules", comment: "Title for the quantity rules in a product.")
        static let minQuantity = NSLocalizedString("Minimum quantity", comment: "Title for the minimum quantity setting in the quantity rules screen.")
        static let maxQuantity = NSLocalizedString("Maximum quantity", comment: "Title for the maximum quantity setting in the quantity rules screen.")
        static let groupOf = NSLocalizedString("Group of", comment: "Title for the 'group of' setting in the quantity rules screen.")

        static let noMinQuantity = NSLocalizedString("No minimum", comment: "Description when no minimum quantity is set in quantity rules.")
        static let noMaxQuantity = NSLocalizedString("No maximum", comment: "Description when no maximum quantity is set in quantity rules.")
        static let noGroupOfQuantity = NSLocalizedString("Not grouped", comment: "Description when no 'group of' quantity is set in quantity rules.")
        static let done = NSLocalizedString(
            "quantityRulesView.done",
            value: "Done",
            comment: "Button to dismiss the product quantity rules view screen."
        )
    }
}

struct QuantityRules_Previews: PreviewProvider {

    static let viewModel = QuantityRulesViewModel(minQuantity: "4", maxQuantity: "200", groupOf: "2", onCompletion: { rules, hasUnsavedChanges in })
    static let noQuantityRules = QuantityRulesViewModel(minQuantity: "", maxQuantity: "", groupOf: "", onCompletion: { rules, hasUnsavedChanges in })

    static var previews: some View {
        QuantityRules(viewModel: viewModel)

        QuantityRules(viewModel: noQuantityRules)
            .previewDisplayName("No Quantity Rules")
    }
}
