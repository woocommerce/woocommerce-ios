import Foundation
import Yosemite

/// ViewModel for `ComponentsList`
///
final class ComponentsListViewModel: ObservableObject {

    /// Site ID
    ///
    private let siteID: Int64

    /// Represents a component
    ///
    struct Component: Identifiable, Equatable {
        /// Component ID
        let id: String

        /// Title of the component
        let title: String

        /// Default image for the component
        let imageURL: URL?

        /// Description of the component
        let description: String

        /// Type of component options (e.g. products or categories)
        let optionType: CompositeComponentOptionType

        /// Product IDs or category IDs to use for populating component options.
        let optionIDs: [Int64]

        /// The product ID of the default/pre-selected component option.
        let defaultOptionID: String
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

    init(siteID: Int64, components: [Component]) {
        self.siteID = siteID
        self.components = components
    }
}

// MARK: Initializers
extension ComponentsListViewModel {
    convenience init(siteID: Int64, components: [ProductCompositeComponent]) {
        let viewModels = components.map { component in
            return Component(id: component.componentID,
                             title: component.title,
                             imageURL: URL(string: component.imageURL),
                             description: component.description,
                             optionType: component.optionType,
                             optionIDs: component.optionIDs,
                             defaultOptionID: component.defaultOptionID)
        }
        self.init(siteID: siteID, components: viewModels)
    }
}

// MARK: Helpers
extension ComponentsListViewModel {
    /// Returns a `ComponentSettingsViewModel` for the provided component.
    ///
    func getSettingsViewModel(for component: Component) -> ComponentSettingsViewModel {
        ComponentSettingsViewModel(siteID: siteID, component: component)
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
