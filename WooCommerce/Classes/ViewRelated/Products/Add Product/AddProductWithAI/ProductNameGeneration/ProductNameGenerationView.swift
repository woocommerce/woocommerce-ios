import SwiftUI

/// View for generating product name with AI.
///
struct ProductNameGenerationView: View {
    @ObservedObject private var viewModel: ProductNameGenerationViewModel
    @FocusState private var isDetailInFocus: Bool
    @State private var copyTextNotice: Notice?

    private let onCompletion: (String) -> Void

    init(viewModel: ProductNameGenerationViewModel, onCompletion: @escaping (String) -> Void) {
        self.viewModel = viewModel
        self.onCompletion = onCompletion
    }

    var body: some View {
        ScrollableVStack(alignment: .leading, spacing: Constants.defaultSpacing) {

            // View title and subtitle
            VStack(alignment: .leading, spacing: Constants.textVerticalSpacing) {
                Label {
                    Text(Localization.title)
                        .headlineStyle()
                } icon: {
                    Image(uiImage: .sparklesImage)
                        .renderingMode(.template)
                        .foregroundColor(.accentColor)
                }

                Text(Localization.subtitle)
                    .subheadlineStyle()
            }

            Divider()

            VStack(alignment: .leading, spacing: Constants.textVerticalSpacing) {
                // Product keyword text field
                ZStack(alignment: .topLeading) {
                    TextEditor(text: $viewModel.keywords)
                        .bodyStyle()
                        .disabled(viewModel.generationInProgress)
                        .padding(insets: Constants.messageContentInsets)
                        .focused($isDetailInFocus)
                        .overlay(
                            RoundedRectangle(cornerRadius: Constants.cornerRadius).stroke(Color(uiColor: isDetailInFocus ? .accent : .separator))
                        )

                    // Placeholder text
                    Text(Localization.placeholder)
                        .foregroundColor(Color(.placeholderText))
                        .bodyStyle()
                        .padding(insets: Constants.placeholderInsets)
                    // Allows gestures to pass through to the `TextEditor`.
                        .allowsHitTesting(false)
                        .renderedIf(viewModel.keywords.isEmpty &&
                                    viewModel.generationInProgress == false)
                }

                Text(Localization.detailDescription)
                    .footnoteStyle()
                    .multilineTextAlignment(.leading)
            }

            /// Suggested name
            if let suggestedText = viewModel.suggestedText {
                VStack(alignment: .leading, spacing: Constants.defaultSpacing) {
                    Text(suggestedText)
                        .fixedSize(horizontal: false, vertical: true)
                        .textSelection(.enabled)

                    HStack {
                        Spacer()
                        // CTA to copy the generated text.
                        Button {
                            viewModel.didTapCopy()
                            UIPasteboard.general.string = suggestedText
                            copyTextNotice = .init(title: Localization.textCopiedNotice)
                        } label: {
                            Label(Localization.copy, systemImage: "doc.on.doc")
                                .secondaryBodyStyle()
                        }
                        .buttonStyle(PlainButtonStyle())
                        .fixedSize(horizontal: true, vertical: false)
                        .renderedIf(viewModel.generationInProgress == false)
                    }
                }
                .padding(Constants.defaultSpacing)
                .redacted(reason: viewModel.generationInProgress ? .placeholder : [])
                .shimmering(active: viewModel.generationInProgress)
                .background(
                    Color(uiColor: .secondarySystemBackground)
                        .cornerRadius(Constants.cornerRadius)
                )
            }

            // Error message
            viewModel.errorMessage.map { message in
                Text(message).errorStyle()
            }

            Spacer()

            if let suggestedText = viewModel.suggestedText,
               viewModel.generationInProgress == false {

                Divider()

                HStack(spacing: Constants.horizontalSpacing) {
                    // Action button to regenerate product name
                    Button(action: {
                        Task {
                            await viewModel.generateProductName()
                        }
                    }, label: {
                        Label {
                            Text(viewModel.generateButtonTitle)
                        } icon: {
                            Image(uiImage: viewModel.generateButtonImage)
                                .renderingMode(.template)
                        }
                    })
                    .buttonStyle(.plain)

                    Spacer()

                    // Action button to apply product name
                    Button(Localization.apply) {
                        viewModel.didTapApply()
                        onCompletion(suggestedText)
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .fixedSize(horizontal: true, vertical: false)
                }
            }

            // Action button to generate product name - displayed initially.
            Button(action: {
                Task {
                    await viewModel.generateProductName()
                }
            }, label: {
                Label {
                    Text(viewModel.generateButtonTitle)
                } icon: {
                    Image(uiImage: viewModel.generateButtonImage)
                        .renderingMode(.template)
                }
            })
            .buttonStyle(PrimaryLoadingButtonStyle(isLoading: viewModel.generationInProgress))
            .disabled(viewModel.keywords.isEmpty)
            .renderedIf(viewModel.hasGeneratedMessage == false)
        }
        .notice($copyTextNotice, autoDismiss: true)
    }
}

private extension ProductNameGenerationView {
    enum Constants {
        static let defaultSpacing: CGFloat = 16
        static let textVerticalSpacing: CGFloat = 8
        static let cornerRadius: CGFloat = 8
        static let insets: EdgeInsets = .init(top: 24, leading: 16, bottom: 16, trailing: 16)
        static let messageContentInsets: EdgeInsets = .init(top: 10, leading: 10, bottom: 10, trailing: 10)
        static let placeholderInsets: EdgeInsets = .init(top: 18, leading: 16, bottom: 18, trailing: 16)
        static let horizontalSpacing: CGFloat = 8
    }
    enum Localization {
        static let title = NSLocalizedString(
            "Product name",
            comment: "Title on the product name generation screen"
        )
        static let subtitle = NSLocalizedString(
            "Let AI generate captivating titles for you.",
            comment: "Subtitle on the product name generation screen"
        )
        static let generateInProgress = NSLocalizedString(
            "Generating...",
            comment: "Text to show the loading state on the product name generation screen"
        )
        static let copy = NSLocalizedString(
            "Copy",
            comment: "Action button to copy the generated name for the new product"
        )
        static let textCopiedNotice = NSLocalizedString(
            "Copied!",
            comment: "Text in the notice after copying the generated text on the product name generation screen."
        )
        static let apply = NSLocalizedString(
            "Apply",
            comment: "Action button to apply the generated name for the new product"
        )
        static let detailDescription = NSLocalizedString(
            "Tell us what your product is and what makes it unique!",
            comment: "Description text on the product name generation screen"
        )
        static let placeholder = NSLocalizedString(
            "For example, Soft fabric, durable stitching, unique design",
            comment: "Placeholder text on the product name generation screen"
        )
    }
}

struct ProductNameAIBottomSheet_Previews: PreviewProvider {
    static var previews: some View {
        ProductNameGenerationView(viewModel: .init(siteID: 123, keywords: "Thai essential oil")) { _ in }
    }
}
