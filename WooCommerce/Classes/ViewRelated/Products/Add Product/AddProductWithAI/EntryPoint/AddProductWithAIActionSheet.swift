import SwiftUI

/// Hosting controller for `AddProductWithAIActionSheet`.
///
final class AddProductWithAIActionSheetHostingController: UIHostingController<AddProductWithAIActionSheet> {
    init(productTypes: [BottomSheetProductType],
         onAIOption: @escaping () -> Void,
         onProductTypeOption: @escaping (BottomSheetProductType) -> Void) {

        let rootView = AddProductWithAIActionSheet(productTypes: productTypes,
                                                   onAIOption: onAIOption,
                                                   onProductTypeOption: onProductTypeOption)
        super.init(rootView: rootView)
    }

    @available(*, unavailable)
    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

/// View to show options for adding a new product including one with AI assistance.
///
struct AddProductWithAIActionSheet: View {
    /// Scale of the view based on accessibility changes
    @ScaledMetric private var scale: CGFloat = 1.0
    @State private var legalURL: URL?
    @State private var isShowingManualOptions: Bool = false

    private let productTypes: [BottomSheetProductType]
    private let onAIOption: () -> Void
    private let onProductTypeOption: (BottomSheetProductType) -> Void

    init(productTypes: [BottomSheetProductType],
         onAIOption: @escaping () -> Void,
         onProductTypeOption: @escaping (BottomSheetProductType) -> Void) {
        self.productTypes = productTypes
        self.onAIOption = onAIOption
        self.onProductTypeOption = onProductTypeOption
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Constants.margin) {
                Group {
                    Text(Localization.title)
                        .titleStyle()
                        .bold()
                        .padding(.top, Constants.titleTopSpacing)

                    Text(Localization.subtitle)
                        .subheadlineStyle()
                }
                .padding(.horizontal, Constants.horizontalSpacing)

                Divider()
                    .padding(.vertical, Constants.verticalSpacing)

                // AI option
                HStack(alignment: .top, spacing: Constants.margin) {
                    Image(uiImage: .sparklesImage)
                        .renderingMode(.template)
                        .resizable()
                        .foregroundColor(.accentColor)
                        .frame(width: Constants.sparkleIconSize * scale, height: Constants.sparkleIconSize * scale)
                    VStack(alignment: .leading, spacing: Constants.verticalSpacing) {
                        Text(Localization.aiTitle)
                            .bodyStyle()
                        Text(Localization.aiDescription)
                            .subheadlineStyle()
                        AdaptiveStack(horizontalAlignment: .leading) {
                            Text(Localization.legalText)
                            Text(.init(Localization.learnMore)).underline()
                        }
                        .environment(\.openURL, OpenURLAction { url in
                            legalURL = url
                            return .handled
                        })
                        .font(.caption)
                        .foregroundColor(Color(.secondaryLabel))
                        .padding(.top, Constants.margin)
                    }
                    Spacer()
                }
                .onTapGesture {
                    onAIOption()
                }
                .padding(.horizontal, Constants.horizontalSpacing)

                Divider()

                // Manual option
                if !isShowingManualOptions {
                    HStack(alignment: .top, spacing: Constants.margin) {
                        Image(systemName: "plus.circle")
                            .font(.title3)
                            .foregroundColor(.secondary)
                        VStack(alignment: .leading, spacing: Constants.verticalSpacing) {
                            Text(Localization.manualTitle)
                                .bodyStyle()
                            Text(Localization.manualDescription)
                                .subheadlineStyle()
                        }
                        Spacer()
                    }
                    .padding(.horizontal, Constants.horizontalSpacing)
                    .onTapGesture {
                        withAnimation {
                            isShowingManualOptions = true
                        }
                    }
                } else {
                    ManualProductTypeOptions(productTypes: productTypes, onOptionSelected: onProductTypeOption)
                }

                Spacer()
            }
            .padding(.vertical, Constants.margin)
            .safariSheet(url: $legalURL)
        }
    }
}

private extension AddProductWithAIActionSheet {
    enum Constants {
        static let sparkleIconSize: CGFloat = 24
        static let verticalSpacing: CGFloat = 4
        static let horizontalSpacing: CGFloat = 16
        static let titleTopSpacing: CGFloat = 16
        static let margin: CGFloat = 16
        static let legalURL = "https://automattic.com/ai-guidelines/"
    }

    enum Localization {
        static let title = NSLocalizedString(
            "addProductWithAIActionSheet.title",
            value: "Create Product",
            comment: "Title on the action sheet to select an option for adding new product"
        )
        static let subtitle = NSLocalizedString(
            "addProductWithAIActionSheet.subtitle",
            value: "Select a product type",
            comment: "Subitle on the action sheet to select an option for adding new product"
        )
        static let aiTitle = NSLocalizedString(
            "Create a product with AI",
            comment: "Title of the option to add new product with AI assistance"
        )
        static let aiDescription = NSLocalizedString(
            "Quickly generate details for you",
            comment: "Description of the option to add new product with AI assistance"
        )
        static let legalText = NSLocalizedString(
            "Powered by AI.",
            comment: "Label to indicate AI-generated content on the product creation action sheet."
        )
        static let learnMore = NSLocalizedString(
            "[Learn more.](https://automattic.com/ai-guidelines/)",
            comment: "Markdown content learn more link on the product creation action sheet. " +
            "Please translate the words while keeping the markdown format and URL."
        )
        static let manualTitle = NSLocalizedString(
            "Add manually",
            comment: "Title of the option to add new product manually"
        )
        static let manualDescription = NSLocalizedString(
            "Add a product and the details manually",
            comment: "Description of the option to add new product manually"
        )
    }
}

struct AddProductWithAIActionSheet_Previews: PreviewProvider {
    static var previews: some View {
        AddProductWithAIActionSheet(
            productTypes: [
                .simple(isVirtual: false),
                .simple(isVirtual: true),
                .subscription,
                .variable,
                .variableSubscription,
                .grouped,
                .affiliate
            ],
            onAIOption: {},
            onProductTypeOption: {_ in }
        )
    }
}
