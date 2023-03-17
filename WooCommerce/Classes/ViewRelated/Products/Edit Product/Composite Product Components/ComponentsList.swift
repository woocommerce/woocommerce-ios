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
    let viewModel: ComponentsListViewModel

    /// Dynamic image width, also used for its height.
    ///
    @ScaledMetric private var imageWidth = Layout.standardImageWidth

    var body: some View {
        ScrollView {
            LazyVStack(spacing: Layout.sectionSpacing) {
                ForEach(viewModel.components) { component in
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
                            .padding(.leading)

                        Text(component.title)
                            .bodyStyle()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                    }
                    Divider().padding(.leading)
                }
            }
            .background(Color(.listForeground(modal: false)))

            FooterNotice(infoText: viewModel.infoNotice)
        }
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
        .init(id: "1", title: "Camera Body", imageURL: nil),
        .init(id: "2", title: "Lens", imageURL: nil),
        .init(id: "3", title: "Memory Card", imageURL: nil)
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
