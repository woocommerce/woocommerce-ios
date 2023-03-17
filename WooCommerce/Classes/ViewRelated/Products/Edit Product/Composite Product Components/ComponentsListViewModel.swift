import Foundation
import Yosemite

/// ViewModel for `ComponentsList`
///
final class ComponentsListViewModel {

    /// Represents a component
    ///
    struct Component: Identifiable {
        /// Component ID
        let id: String

        /// Title of the component
        let title: String

        /// Default image for the component
        let imageURL: URL?
    }

    /// View title
    ///
    let title = Localization.title

    /// View info notice
    ///
    let infoNotice = Localization.infoNotice

    /// Components
    ///
    let components: [Component]

    init(components: [Component]) {
        self.components = components
    }
}

// MARK: Initializers
extension ComponentsListViewModel {
    convenience init(components: [ProductCompositeComponent]) {
        let viewModels = components.map { component in
            Component(id: component.componentID, title: component.title, imageURL: URL(string: component.imageURL))
        }
        self.init(components: viewModels)
    }
}

// MARK: Constants
private extension ComponentsListViewModel {
    enum Localization {
        static let title = NSLocalizedString("Components", comment: "Title for the list of components in a composite product")
        static let infoNotice = NSLocalizedString("You can edit components in the web dashboard.",
                                                  comment: "Info notice at the bottom of the components screen")
    }
}
