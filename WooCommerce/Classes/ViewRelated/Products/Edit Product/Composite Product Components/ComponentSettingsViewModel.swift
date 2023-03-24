import Foundation
import Yosemite
import protocol Storage.StorageManagerType

/// ViewModel for `ComponentSettings`
///
final class ComponentSettingsViewModel: ObservableObject {

    /// Represents a component option
    ///
    struct ComponentOption: Identifiable, Equatable {
        /// Component option ID
        let id: Int64

        /// Title of the component option
        let title: String

        /// Default image for the component
        let imageURL: URL?
    }

    /// View title
    ///
    let viewTitle = Localization.title

    /// View info notice
    ///
    let infoNotice = Localization.infoNotice

    // MARK: Basic Component Settings

    /// Component title
    ///
    let componentTitle: String

    /// Component description
    ///
    let description: String

    /// Component image
    ///
    let imageURL: URL?

    // MARK: Component Options

    /// Label for type of component options
    ///
    let optionsType: String

    /// Component options
    ///
    let options: [ComponentOption]

    /// Title of the default (pre-selected) component option
    ///
    let defaultOptionTitle: String

    // MARK: Section Visibility

    /// Whether to display the component image
    ///
    var shouldShowImage: Bool {
        imageURL != nil
    }

    /// Whether to display the component description
    ///
    var shouldShowDescription: Bool {
        description.isNotEmpty
    }

    init(title: String,
         description: String,
         imageURL: URL?,
         optionsType: String,
         options: [ComponentOption],
         defaultOptionTitle: String = Localization.noDefaultOption) {
        self.componentTitle = title
        self.description = description
        self.imageURL = imageURL
        self.optionsType = optionsType
        self.options = options
        self.defaultOptionTitle = defaultOptionTitle
    }
}

// MARK: Initializers
extension ComponentSettingsViewModel {
    convenience init(component: ComponentsListViewModel.Component) {
        // Initialize the view model with the available component settings and placeholders for the component options.
        self.init(title: component.title,
                  description: component.description.removedHTMLTags.trimmingCharacters(in: .whitespacesAndNewlines),
                  imageURL: component.imageURL,
                  optionsType: component.optionType.description,
                  options: [])
    }
}

// MARK: Constants
private extension ComponentSettingsViewModel {
    enum Localization {
        static let title = NSLocalizedString("Component Settings", comment: "Title for the settings of a component in a composite product")
        static let infoNotice = NSLocalizedString("You can edit component settings in the web dashboard.",
                                                  comment: "Info notice at the bottom of the component settings screen")
        static let noDefaultOption = NSLocalizedString("None", comment: "Label when there is no default option for a component in a composite product")
    }
}
