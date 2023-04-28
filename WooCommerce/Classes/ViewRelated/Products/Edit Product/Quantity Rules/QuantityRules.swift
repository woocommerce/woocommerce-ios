import SwiftUI

// MARK: Hosting Controller

/// Hosting controller that wraps a `QuantityRules` view.
///
final class QuantityRulesViewController: UIHostingController<QuantityRules> {
    init() {
        super.init(rootView: QuantityRules())
    }

    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

struct QuantityRules: View {

    /// Environment safe areas
    ///
    @Environment(\.safeAreaInsets) private var safeAreaInsets: EdgeInsets

    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                // Minimum quantity
                TitleAndSubtitleRow(title: Localization.minQuantity, subtitle: "4")
                Divider()
                    .padding(.leading)
                    .padding(.trailing, insets: -safeAreaInsets)

                // Maximum quantity
                TitleAndSubtitleRow(title: Localization.maxQuantity, subtitle: "400")
                Divider()
                    .padding(.leading)
                    .padding(.trailing, insets: -safeAreaInsets)

                // Group of
                TitleAndSubtitleRow(title: Localization.groupOf, subtitle: "2")
            }
            .padding(.horizontal, insets: safeAreaInsets)
            .addingTopAndBottomDividers()
            .background(Color(.listForeground(modal: false)))

            FooterNotice(infoText: Localization.infoNotice)
                .padding(.horizontal, insets: safeAreaInsets)
        }
        .navigationBarTitle(Localization.title)
        .navigationBarTitleDisplayMode(.inline)
        .ignoresSafeArea(edges: .horizontal)
        .background(
            Color(.listBackground).edgesIgnoringSafeArea(.all)
        )
    }
}

private extension QuantityRules {
    enum Localization {
        static let title = NSLocalizedString("Quantity Rules", comment: "Title for the quantity rules in a product.")
        static let infoNotice = NSLocalizedString("You can edit quantity rules in the web dashboard",
                                                  comment: "Info notice at the bottom of the quantity rules screen.")
        static let minQuantity = NSLocalizedString("Minimum quantity", comment: "Title for the minimum quantity setting in the quantity rules screen.")
        static let maxQuantity = NSLocalizedString("Maximum quantity", comment: "Title for the maximum quantity setting in the quantity rules screen.")
        static let groupOf = NSLocalizedString("Group of", comment: "Title for the 'group of' setting in the quantity rules screen.")
    }
}

struct QuantityRules_Previews: PreviewProvider {
    static var previews: some View {
        QuantityRules()
    }
}
