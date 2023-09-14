import SwiftUI

/// Hosting controller for `AddProductWithAIActionSheet`.
///
final class AddProductWithAIActionSheetHostingController: UIHostingController<AddProductWithAIActionSheet> {
    init(onAIOption: @escaping () -> Void,
         onManualOption: @escaping () -> Void) {
        let rootView = AddProductWithAIActionSheet(onAIOption: onAIOption, onManualOption: onManualOption)
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
    @Environment(\.customOpenURL) private var customOpenURL
    @State private var legalURL: URL?

    private let onAIOption: () -> Void
    private let onManualOption: () -> Void

    init(onAIOption: @escaping () -> Void,
         onManualOption: @escaping () -> Void) {
        self.onAIOption = onAIOption
        self.onManualOption = onManualOption
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Constants.margin) {
            Text(Localization.title)
                .subheadlineStyle()
                .padding(.vertical, Constants.margin)

            // AI option
            HStack(alignment: .top, spacing: Constants.margin) {
                Image(uiImage: .sparklesImage)
                    .renderingMode(.template)
                    .foregroundColor(.accentColor)
                VStack(alignment: .leading, spacing: Constants.verticalSpacing) {
                    Text(Localization.aiTitle)
                        .bodyStyle()
                    Text(Localization.aiDescription)
                        .subheadlineStyle()
                    Text(.init(Localization.legalText))
                        .font(.caption)
                        .foregroundColor(Color(.secondaryLabel))
                        .padding(.top, Constants.margin)
                        .environment(\.customOpenURL) { url in
                            legalURL = url
                        }
                        .safariSheet(url: $legalURL)
                }
                Spacer()
            }
            .onTapGesture {
                onAIOption()
            }

            Divider()

            // Manual option
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
            .onTapGesture {
                onManualOption()
            }
        }
        .padding(.horizontal, Constants.margin)
    }
}

private extension AddProductWithAIActionSheet {
    enum Constants {
        static let verticalSpacing: CGFloat = 8
        static let margin: CGFloat = 16
        static let legalURL = "https://automattic.com/ai-guidelines/"
    }

    enum Localization {
        static let title = NSLocalizedString(
            "Add a product",
            comment: "Title on the action sheet to select an option for adding new product"
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
            "Powered by AI. [Learn more.](https://automattic.com/ai-guidelines/)",
            comment: "Markdown content for the label to indicate AI-generated content on the product creation action sheet. " +
            "Please translate the words while keeping the markdown format and URL"
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
        AddProductWithAIActionSheet(onAIOption: {}, onManualOption: {})
    }
}
