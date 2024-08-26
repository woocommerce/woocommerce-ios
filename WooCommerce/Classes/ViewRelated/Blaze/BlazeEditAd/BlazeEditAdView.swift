import SwiftUI

/// View to edit Blaze Ad
///
struct BlazeEditAdView: View {
    private enum Field: Hashable {
        case tagline
        case description
    }

    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var viewModel: BlazeEditAdViewModel
    @State private var isShowingMediaPickerSheet: Bool = false
    @FocusState private var focusedField: Field?

    /// Scale of the view based on accessibility changes
    @ScaledMetric private var scale: CGFloat = 1.0

    init(viewModel: BlazeEditAdViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: Layout.parentVerticalSpacing) {
                    imageBlock
                        .padding(insets: Layout.imageBlockInsets)
                        .frame(maxWidth: Layout.imageBlockMaxWidth)

                    Divider()
                        .frame(height: Layout.strokeWidth)
                        .foregroundColor(Color(uiColor: .separator))

                    VStack(alignment: .leading, spacing: Layout.childVerticalSpacing) {
                        tagline

                        description

                        suggestedByAI
                    }
                    .padding(insets: Layout.textBlockInsets)
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(Localization.cancel) {
                        viewModel.didTapCancel()
                        dismiss()
                    }
                    .buttonStyle(TextButtonStyle())
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(Localization.save) {
                        viewModel.didTapSave()
                        dismiss()
                    }
                    .buttonStyle(TextButtonStyle())
                    .disabled(!viewModel.isSaveButtonEnabled)
                }
            }
            .navigationTitle(Localization.title)
            .wooNavigationBarStyle()
            .navigationBarTitleDisplayMode(.inline)
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .alert(Text(Localization.Image.imageSizeErrorMessage), isPresented: $viewModel.shouldDisplayImageSizeErrorAlert) {
            Button(Localization.Image.ok, role: .cancel) { }
        }
    }
}

private extension BlazeEditAdView {
    var imageBlock: some View {
        VStack(alignment: .center, spacing: Layout.childVerticalSpacing) {
            EditableImageView(imageState: viewModel.imageState,
                              aspectRatio: .fit,
                              emptyContent: {
                Image(uiImage: .blazeProductPlaceholder)
            })
            .cornerRadius(Layout.Image.cornerRadius)
            .mediaSourceActionSheet(showsActionSheet: $isShowingMediaPickerSheet,
                                    sourceOptions: [.camera, .photoLibrary, .productMedia(productID: viewModel.productID), .siteMediaLibrary],
                                    selectMedia: { source in
                viewModel.addImage(from: source)
            })

            Button(Localization.Image.changeImage) {
                isShowingMediaPickerSheet = true
            }
            .buttonStyle(TextButtonStyle())
        }
    }

    var tagline: some View {
        VStack(alignment: .leading, spacing: Layout.textBlockVerticalSpacing) {
            Text(Localization.Tagline.title)
                .foregroundColor(Color(.label))
                .subheadlineStyle()

            ZStack(alignment: .topLeading) {
                TextEditor(text: $viewModel.tagline)
                    .bodyStyle()
                    .foregroundColor(.secondary)
                    .padding(insets: Layout.textFieldContentInsets)
                    .frame(minHeight: Layout.Tagline.minimumEditorHeight * scale, maxHeight: .infinity)
                    .focused($focusedField, equals: .tagline)

                // Placeholder text
                Text(Localization.Tagline.placeholder)
                    .foregroundColor(Color(.placeholderText))
                    .bodyStyle()
                    .padding(insets: Layout.placeholderInsets)
                    // Allows gestures to pass through to the `TextEditor`.
                    .allowsHitTesting(false)
                    .renderedIf(viewModel.tagline.isEmpty)
            }
            .overlay(
                RoundedRectangle(cornerRadius: Layout.cornerRadius)
                    .stroke(focusedField == .tagline ? Color(.brand) : Color(.separator), lineWidth: Layout.strokeWidth)
            )

            Text(viewModel.taglineFooterText)
                .foregroundStyle(viewModel.isTaglineValidated ? .secondary : Color(.error))
                .footnoteStyle()
        }
    }

    var description: some View {
        VStack(alignment: .leading, spacing: Layout.textBlockVerticalSpacing) {
            Text(Localization.Description.title)
                .foregroundColor(Color(.label))
                .subheadlineStyle()

            ZStack(alignment: .topLeading) {
                TextEditor(text: $viewModel.description)
                    .bodyStyle()
                    .foregroundColor(.secondary)
                    .padding(insets: Layout.textFieldContentInsets)
                    .frame(minHeight: Layout.Description.minimumEditorHeight * scale, maxHeight: .infinity)
                    .focused($focusedField, equals: .description)

                // Placeholder text
                Text(Localization.Description.placeholder)
                    .foregroundColor(Color(.placeholderText))
                    .bodyStyle()
                    .padding(insets: Layout.placeholderInsets)
                    // Allows gestures to pass through to the `TextEditor`.
                    .allowsHitTesting(false)
                    .renderedIf(viewModel.description.isEmpty)
            }
            .overlay(
                RoundedRectangle(cornerRadius: Layout.cornerRadius)
                    .stroke(focusedField == .description ? Color(.brand) : Color(.separator), lineWidth: Layout.strokeWidth)
            )

            Text(viewModel.descriptionFooterText)
                .foregroundStyle(viewModel.isDescriptionValidated ? .secondary : Color(.error))
                .footnoteStyle()
        }
    }

    var suggestedByAI: some View {
        HStack {
            HStack(spacing: 0) {
                Image(uiImage: .sparklesImage)
                    .renderingMode(.template)
                    .resizable()
                    .foregroundColor(Color(uiColor: .label))
                    .frame(width: Layout.sparkleIconSize * scale, height: Layout.sparkleIconSize * scale)

                Text(Localization.suggestedByAI)
                    .fontWeight(.semibold)
                    .foregroundColor(Color(uiColor: .label))
                    .bodyStyle()
            }

            Spacer()

            HStack(spacing: Layout.SuggestedByAI.hSpacing) {
                SwitchSuggestionButton(type: .previous,
                                       isEnabled: viewModel.canSelectPreviousSuggestion) {
                    viewModel.didTapPrevious()
                }

                SwitchSuggestionButton(type: .next,
                                       isEnabled: viewModel.canSelectNextSuggestion) {
                    viewModel.didTapNext()
                }
            }
        }
    }
}

private extension BlazeEditAdView {
    struct SwitchSuggestionButton: View {
        enum ButtonType {
            case previous
            case next
        }

        let type: ButtonType
        let isEnabled: Bool
        let action: () -> Void

        private var image: Image {
            switch type {
            case .previous:
                return Image(systemName: "chevron.backward")
            case .next:
                return Image(systemName: "chevron.forward")
            }
        }

        var body: some View {
            Button(action: {
                action()
            }, label: {
                image
                    .font(.body.weight(.semibold))
                    .foregroundColor(isEnabled ? Color(.primary) : Color(.textTertiary))
                    .padding(Layout.SuggestedByAI.SwitchButton.padding)
                    .background(
                        RoundedRectangle(cornerRadius: Layout.SuggestedByAI.SwitchButton.cornerRadius)
                            .strokeBorder(
                                Color(uiColor: .separator),
                                lineWidth: Layout.SuggestedByAI.SwitchButton.strokeWidth
                            )
                    )
            })
            .disabled(!isEnabled)
        }
    }
}

private extension BlazeEditAdView {
    enum Localization {
        static let title = NSLocalizedString(
            "blazeEditAdView.title",
            value: "Edit Ad",
            comment: "Title for the Blaze Edit Ad screen."
        )
        static let cancel = NSLocalizedString(
            "blazeEditAdView.cancel",
            value: "Cancel",
            comment: "Cancel button in the Blaze Edit Ad screen."
        )
        static let save = NSLocalizedString(
            "blazeEditAdView.save",
            value: "Save",
            comment: "Save button in the Blaze Edit Ad screen."
        )
        enum Image {
            static let changeImage = NSLocalizedString(
                "blazeEditAdView.image.changeImage",
                value: "Change image",
                comment: "Change image button title in the Blaze Edit Ad screen."
            )
            static let imageSizeErrorMessage = NSLocalizedString(
                "blazeEditAdView.image.imageSizeErrorMessage",
                value: "Please select an image with minimum dimensions of 400 × 400 px.",
                comment: "Error message displayed when selected campaign image is not large enough."
            )
            static let ok = NSLocalizedString(
                "blazeEditAdView.image.ok",
                value: "OK",
                comment: "Button to dismiss the image view alert."
            )
        }
        enum Tagline {
            static let title = NSLocalizedString(
                "blazeEditAdView.tagline.title",
                value: "Tagline",
                comment: "Tagline title text in the Blaze Edit Ad screen."
            )
            static let placeholder = NSLocalizedString(
                "blazeEditAdView.tagline.placeholder",
                value: "Title for the Blaze Ad",
                comment: "Placeholder for Tagline text field in the Blaze Edit Ad screen."
            )
        }
        enum Description {
            static let title = NSLocalizedString(
                "blazeEditAdView.description.title",
                value: "Description",
                comment: "Description title text in the Blaze Edit Ad screen."
            )
            static let placeholder = NSLocalizedString(
                "blazeEditAdView.description.placeholder",
                value: "Description text for the Blaze Ad",
                comment: "Placeholder for Description text field in the Blaze Edit Ad screen."
            )
        }
        static let suggestedByAI = NSLocalizedString(
            "blazeEditAdView.suggestedByAI",
            value: "Suggested by AI",
            comment: "Suggested by AI title in the Blaze Edit Ad screen."
        )
    }
}

private enum Layout {
    static let imageBlockInsets: EdgeInsets = .init(top: 24, leading: 16, bottom: 0, trailing: 16)
    static let imageBlockMaxWidth: CGFloat = 430
    static let textBlockInsets: EdgeInsets = .init(top: 0, leading: 16, bottom: 16, trailing: 16)

    static let parentVerticalSpacing: CGFloat = 24
    static let childVerticalSpacing: CGFloat = 16
    static let textBlockVerticalSpacing: CGFloat = 8

    static let cornerRadius: CGFloat = 8
    static let strokeWidth: CGFloat = 1
    static let textFieldContentInsets: EdgeInsets = .init(top: 10, leading: 10, bottom: 10, trailing: 10)
    static let placeholderInsets: EdgeInsets = .init(top: 18, leading: 16, bottom: 18, trailing: 16)

    enum Image {
        static let cornerRadius: CGFloat = 8
    }

    enum Tagline {
        static let minimumEditorHeight: CGFloat = 54
    }

    enum Description {
        static let minimumEditorHeight: CGFloat = 140
    }

    enum SuggestedByAI {
        static let hSpacing: CGFloat = 16

        enum SwitchButton {
            static let padding: CGFloat = 8
            static let cornerRadius: CGFloat = 8
            static let strokeWidth: CGFloat = 1
        }
    }

    static let sparkleIconSize: CGFloat = 24
}

struct BlazeEditAdView_Previews: PreviewProvider {
    static var previews: some View {
        BlazeEditAdView(viewModel: .init(siteID: 123,
                                         productID: 34,
                                         adData: .init(image: .init(image: .init(), source: .asset(asset: .init())),
                                                       tagline: "Tagline",
                                                       description: "Description"),
                                         suggestions: [],
                                         onSave: { _ in })
        )
    }
}
