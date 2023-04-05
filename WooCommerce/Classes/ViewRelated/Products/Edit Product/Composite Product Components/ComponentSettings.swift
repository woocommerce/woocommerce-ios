import SwiftUI
import Kingfisher

/// Renders the settings for a component in a composite product
///
struct ComponentSettings: View {

    /// View model that directs the view content.
    ///
    @StateObject var viewModel: ComponentSettingsViewModel

    /// Dynamic image width for the component image, also used for its height.
    ///
    @ScaledMetric private var componentImageWidth = Layout.componentImageWidth

    /// Dynamic image width for the component option image, also used for its height.
    ///
    @ScaledMetric private var optionImageWidth = Layout.optionImageWidth

    /// Environment safe areas
    ///
    @Environment(\.safeAreaInsets) private var safeAreaInsets: EdgeInsets

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Layout.sectionSpacing) {
                // Component image
                KFImage(viewModel.imageURL)
                    .placeholder {
                        Image(uiImage: .productPlaceholderImage)
                            .foregroundColor(Color(.listIcon))
                    }
                    .resizable()
                    .frame(width: componentImageWidth, height: componentImageWidth)
                    .overlay(RoundedRectangle(cornerRadius: Layout.imageCornerRadius)
                        .stroke(Color(.systemGray4), lineWidth: Layout.imageBorderWidth))
                    .accessibilityHidden(true)
                    .padding()
                    .renderedIf(viewModel.shouldShowImage)

                // Component title
                Text(viewModel.componentTitle)
                    .headlineStyle()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()

                Group {
                    Divider()
                        .padding(.leading)
                        .padding(.trailing, insets: -safeAreaInsets)

                    // Component description
                    TitleAndSubtitleRow(title: Localization.description, subtitle: viewModel.description)
                }
                .renderedIf(viewModel.shouldShowDescription)
            }
            .padding(.horizontal, insets: safeAreaInsets)
            .addingTopAndBottomDividers()
            .background(Color(.listForeground(modal: false)))

            // Component options
            ListHeaderView(text: Localization.componentOptions.uppercased(), alignment: .left)
                .padding(.horizontal, insets: safeAreaInsets)
            LazyVStack(alignment: .leading, spacing: Layout.sectionSpacing) {
                Text(viewModel.optionsType)
                    .headlineStyle()
                    .padding()

                optionsList
                    .redacted(reason: viewModel.showOptionsLoadingIndicator ? .placeholder : [])
                    .shimmering(active: viewModel.showOptionsLoadingIndicator)
            }
            .padding(.horizontal, insets: safeAreaInsets)
            .addingTopAndBottomDividers()
            .background(Color(.listForeground(modal: false)))

            // Default component option
            TitleAndValueRow(title: Localization.defaultOption, value: .placeholder(viewModel.defaultOptionTitle))
                .padding(.horizontal, insets: safeAreaInsets)
                .addingTopAndBottomDividers()
                .redacted(reason: viewModel.showDefaultOptionLoadingIndicator ? .placeholder : [])
                .shimmering(active: viewModel.showDefaultOptionLoadingIndicator)
                .background(Color(.listForeground(modal: false)))

            FooterNotice(infoText: viewModel.infoNotice)
                .padding(.horizontal, insets: safeAreaInsets)
        }
        .notice($viewModel.errorNotice, autoDismiss: false)
        .navigationTitle(viewModel.viewTitle)
        .ignoresSafeArea(edges: .horizontal)
        .background(
            Color(.listBackground).edgesIgnoringSafeArea(.all)
        )
    }

    /// Displays a list of component options or a placeholder if the list is empty.
    ///
    @ViewBuilder private var optionsList: some View {
        if viewModel.options.isNotEmpty {
            ForEach(viewModel.options) { option in
                HStack {
                    KFImage(option.imageURL)
                        .placeholder {
                            Image(uiImage: .productPlaceholderImage)
                                .foregroundColor(Color(.listIcon))
                        }
                        .resizable()
                        .frame(width: optionImageWidth, height: optionImageWidth)
                        .cornerRadius(Layout.imageCornerRadius)
                        .accessibilityHidden(true)
                        .padding()

                    Text(option.title)
                        .bodyStyle()
                }
                Divider()
                    .padding(.leading)
                    .padding(.trailing, insets: -safeAreaInsets)
                    .renderedIf(option != viewModel.options.last)
            }
        } else {
            Text(Localization.noOptions)
                .secondaryBodyStyle()
                .padding()
        }
    }
}

private enum Layout {
    static let componentImageWidth: CGFloat = 96.0
    static let imageBorderWidth: CGFloat = 0.5
    static let optionImageWidth: CGFloat = 48.0
    static let imageCornerRadius: CGFloat = 4.0
    static let sectionSpacing: CGFloat = 0
}

// MARK: Localization
private extension ComponentSettings {
    enum Localization {
        static let description = NSLocalizedString("Description", comment: "Title for the component description field in the Component Settings view")
        static let componentOptions = NSLocalizedString("Component Options", comment: "Title for the list of component options in the Component Settings view")
        static let noOptions = NSLocalizedString("No options selected",
                                                 comment: "Placeholder when there are no component options to show in the Component Settings view")
        static let defaultOption = NSLocalizedString("Default Option", comment: "Title for the default component option field in the Component Settings view")
    }
}


// MARK: Previews
struct ComponentSettings_Previews: PreviewProvider {

    static let viewModel = ComponentSettingsViewModel(title: "Camera Body",
                                                      description: "Choose between the Nikon D600 or the powerful Canon EOS 5D Mark IV.",
                                                      imageURL: nil,
                                                      optionsType: "Products",
                                                      options: [
                                                        .init(id: 1, title: "Nikon D600 Digital SLR Camera Body", imageURL: nil),
                                                        .init(id: 2, title: "Canon EOS 5D Mark IV Camera Body", imageURL: nil)
                                                      ],
                                                      defaultOptionTitle: "Nikon D600 Digital SLR Camera Body")

    static let emptyViewModel = ComponentSettingsViewModel(title: "Camera Body",
                                                           description: "",
                                                           imageURL: nil,
                                                           optionsType: "Products",
                                                           options: [])

    static var previews: some View {
        ComponentSettings(viewModel: viewModel)
            .environment(\.colorScheme, .light)
            .previewDisplayName("Light")

        ComponentSettings(viewModel: emptyViewModel)
            .previewDisplayName("Empty Options")

        ComponentSettings(viewModel: viewModel)
            .environment(\.colorScheme, .dark)
            .previewDisplayName("Dark")

        ComponentSettings(viewModel: viewModel)
            .environment(\.sizeCategory, .accessibilityExtraExtraExtraLarge)
            .previewDisplayName("Large Font")
    }
}
