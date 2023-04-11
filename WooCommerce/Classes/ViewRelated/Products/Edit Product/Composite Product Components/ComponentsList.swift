import UIKit
import SwiftUI
import Kingfisher

// MARK: Hosting Controller

/// Hosting controller that wraps a `ComponentsList` view.
///
final class ComponentsListViewController: UIHostingController<ComponentsList> {
    init(viewModel: ComponentsListViewModel) {
        super.init(rootView: ComponentsList(viewModel: viewModel))
        title = viewModel.title
    }

    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: Views

/// Renders a list of components in a composite product
///
struct ComponentsList: View {

    /// View model that directs the view content.
    ///
    @StateObject var viewModel: ComponentsListViewModel

    /// Dynamic image width, also used for its height.
    ///
    @ScaledMetric private var imageWidth = Layout.standardImageWidth

    /// Environment safe areas
    ///
    @Environment(\.safeAreaInsets) private var safeAreaInsets: EdgeInsets

    var body: some View {
        ScrollView {
            LazyVStack(spacing: Layout.sectionSpacing) {
                ForEach(viewModel.components) { component in
                    LazyNavigationLink(destination: ComponentSettings(viewModel: viewModel.getSettingsViewModel(for: component))) {
                        HStack {
                            KFImage(component.imageURL)
                                .placeholder {
                                    Image(uiImage: .productPlaceholderImage)
                                        .foregroundColor(Color(.listIcon))
                                }
                                .resizable()
                                .frame(width: imageWidth, height: imageWidth)
                                .cornerRadius(Layout.imageCornerRadius)
                                .accessibilityHidden(true)
                                .padding()

                            Text(component.title)
                                .bodyStyle()
                                .frame(maxWidth: .infinity, alignment: .leading)

                            DisclosureIndicator()
                                .padding([.leading, .trailing])
                        }
                    }
                    Divider()
                        .padding(.leading)
                        .padding(.trailing, insets: -safeAreaInsets)
                        .renderedIf(component != viewModel.components.last)
                }
            }
            .padding(.horizontal, insets: safeAreaInsets)
            .addingTopAndBottomDividers()
            .background(Color(.listForeground(modal: false)))

            FooterNotice(infoText: viewModel.infoNotice)
                .padding(.horizontal, insets: safeAreaInsets)
        }
        .ignoresSafeArea(edges: .horizontal)
        .background(
            Color(.listBackground).edgesIgnoringSafeArea(.all)
        )
    }
}

private enum Layout {
    static let standardImageWidth: CGFloat = 48.0
    static let imageCornerRadius: CGFloat = 4.0
    static let sectionSpacing: CGFloat = 0
}


// MARK: Previews
struct ComponentsList_Previews: PreviewProvider {

    static let viewModel = ComponentsListViewModel(components: [
        .init(id: "1", title: "Camera Body", imageURL: nil, description: "", optionType: .productIDs),
        .init(id: "2", title: "Lens", imageURL: nil, description: "", optionType: .categoryIDs),
        .init(id: "3", title: "Memory Card", imageURL: nil, description: "", optionType: .categoryIDs)
    ])

    static var previews: some View {
        ComponentsList(viewModel: viewModel)
            .environment(\.colorScheme, .light)
            .previewDisplayName("Light")

        ComponentsList(viewModel: viewModel)
            .environment(\.colorScheme, .dark)
            .previewDisplayName("Dark")

        ComponentsList(viewModel: viewModel)
            .environment(\.sizeCategory, .accessibilityExtraExtraExtraLarge)
            .previewDisplayName("Large Font")
    }
}
