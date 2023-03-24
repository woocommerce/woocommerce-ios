import SwiftUI
import Kingfisher

/// Renders the settings for a component in a composite product
///
struct ComponentSettings: View {

    /// View model that directs the view content.
    ///
    let viewModel: ComponentSettingsViewModel

    /// Dynamic image width for the component image, also used for its height.
    ///
    @ScaledMetric private var componentImageWidth = Layout.componentImageWidth

    /// Dynamic image width for the component option image, also used for its height.
    ///
    @ScaledMetric private var optionImageWidth = Layout.optionImageWidth

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Layout.sectionSpacing) {
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

                Text(viewModel.componentTitle)
                    .headlineStyle()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()

                Group {
                    Divider().padding(.leading)

                    TitleAndSubtitleRow(title: Localization.description, subtitle: viewModel.description)
                }
                .renderedIf(viewModel.shouldShowDescription)
            }
            .addingTopAndBottomDividers()
            .background(Color(.listForeground(modal: false)))

            ListHeaderView(text: Localization.componentOptions.uppercased(), alignment: .left)
            LazyVStack(alignment: .leading, spacing: Layout.sectionSpacing) {
                Text(viewModel.optionsType)
                    .headlineStyle()
                    .padding()

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
                    Divider().padding(.leading)
                        .renderedIf(option != viewModel.options.last)
                }
            }
            .addingTopAndBottomDividers()
            .background(Color(.listForeground(modal: false)))

            TitleAndValueRow(title: Localization.defaultOption, value: .placeholder(viewModel.defaultOptionTitle))
                .addingTopAndBottomDividers()
                .background(Color(.listForeground(modal: false)))

            FooterNotice(infoText: viewModel.infoNotice)
        }
        .navigationTitle(viewModel.viewTitle)
        .background(
            Color(.listBackground).edgesIgnoringSafeArea(.all)
        )
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

    static var previews: some View {
        ComponentSettings(viewModel: viewModel)
            .environment(\.colorScheme, .light)
            .previewDisplayName("Light")

        ComponentSettings(viewModel: viewModel)
            .environment(\.colorScheme, .dark)
            .previewDisplayName("Dark")

        ComponentSettings(viewModel: viewModel)
            .environment(\.sizeCategory, .accessibilityExtraExtraExtraLarge)
            .previewDisplayName("Large Font")
    }
}
