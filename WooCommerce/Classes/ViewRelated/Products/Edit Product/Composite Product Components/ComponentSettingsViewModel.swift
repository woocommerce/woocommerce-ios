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
    @Published var options: [ComponentOption]

    /// Title of the default (pre-selected) component option
    ///
    @Published var defaultOptionTitle: String

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

    // MARK: Loading State

    /// Dependency state.
    ///
    enum LoadState {
        case notLoaded
        case loading
        case loaded
    }

    /// Current product dependency state.
    ///
    @Published private var productsState: LoadState = .notLoaded

    /// Current category dependency state.
    ///
    @Published private var categoriesState: LoadState = .notLoaded

    /// Current component options dependency state.
    ///
    /// This state reflects either the `productsState` or `categoriesState`, depending on the component option type.
    ///
    private var componentOptionsState: LoadState {
        optionsType == CompositeComponentOptionType.productIDs.description ? productsState : categoriesState
    }

    /// Indicates if the Component Options section should should show a redacted state.
    ///
    var showOptionsLoadingIndicator: Bool {
        componentOptionsState == .loading
    }

    /// Indicates if the Default Option section should should show a redacted state.
    ///
    var showDefaultOptionLoadingIndicator: Bool {
        productsState == .loading
    }

    /// Indicates if the view should show an error notice.
    ///
    var errorNotice: Notice? = nil

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
    /// Initializes the view model using a `Component` from the `ComponentsListViewModel`.
    /// Used when navigating to `ComponentSettings` from `ComponentsList`.
    ///
    convenience init(siteID: Int64,
                     component: ComponentsListViewModel.Component,
                     stores: StoresManager = ServiceLocator.stores) {
        // Initialize the view model with the available component settings and placeholders for the component options.
        self.init(title: component.title,
                  description: component.description.removedHTMLTags.trimmingCharacters(in: .whitespacesAndNewlines),
                  imageURL: component.imageURL,
                  optionsType: component.optionType.description,
                  options: ComponentSettingsViewModel.optionsLoadingPlaceholder)

        // Then load details about the component options.
        loadComponentOptions(siteID: siteID,
                             optionIDs: component.optionIDs,
                             defaultOptionID: Int64(component.defaultOptionID),
                             type: component.optionType,
                             stores: stores)
    }
}

// MARK: Private helpers
private extension ComponentSettingsViewModel {
    /// Load the component options (products or categories) if needed.
    ///
    func loadComponentOptions(siteID: Int64,
                              optionIDs: [Int64],
                              defaultOptionID: Int64?,
                              type: CompositeComponentOptionType,
                              stores: StoresManager) {
        syncProducts(siteID: siteID, optionIDs: optionIDs, defaultOptionID: defaultOptionID, type: type, stores: stores)
        syncCategoriesIfNeeded(siteID: siteID, optionIDs: optionIDs, type: type, stores: stores)
    }

    /// Syncs products and sets the default option and (if the component options are products) the options list.
    ///
    func syncProducts(siteID: Int64, optionIDs: [Int64], defaultOptionID: Int64?, type: CompositeComponentOptionType, stores: StoresManager) {
        guard productsState == .notLoaded else { return }

        // If the component options are products, sync the products matching the list of option IDs.
        // Otherwise, the component options are categories, so we only need to sync the default option (a product).
        let productsToSync = type == .productIDs ? optionIDs : [defaultOptionID].compactMap { $0 }
        let productAction = ProductAction.retrieveProducts(siteID: siteID, productIDs: productsToSync) { [weak self] result in
            guard let self else { return }

            switch result {
            case .success((let products, _)):
                self.errorNotice = nil
                self.defaultOptionTitle = products.first(where: { $0.productID == defaultOptionID })?.name ?? Localization.noDefaultOption
                if type == .productIDs {
                    self.options = products.map { product in
                        ComponentOption(id: product.productID, title: product.name, imageURL: product.imageURL)
                    }
                }
                self.productsState = .loaded
            case .failure(let error):
                if type == .productIDs {
                    self.options = []
                }
                self.productsState = .notLoaded
                DDLogError("⛔️ Unable to fetch products for composite component settings: \(error)")
                self.errorNotice = self.createErrorNotice() { [weak self] in
                    self?.syncProducts(siteID: siteID, optionIDs: optionIDs, defaultOptionID: defaultOptionID, type: type, stores: stores)
                }
            }
        }

        productsState = .loading
        stores.dispatch(productAction)
    }

    /// Syncs the provided categories if the component options are categories.
    ///
    func syncCategoriesIfNeeded(siteID: Int64, optionIDs: [Int64], type: CompositeComponentOptionType, stores: StoresManager) {
        guard type == .categoryIDs && categoriesState == .notLoaded else { return }

        categoriesState = .loading

        // Sync each category individually because we only need the provided categories, which we expect is a small list.
        // Our other option is a full category sync each time this view loads, which could be very large.
        var categoryOptions: [ComponentOption] = []
        for categoryID in optionIDs {
            let categoryAction = ProductCategoryAction.synchronizeProductCategory(siteID: siteID, categoryID: categoryID) { [weak self] result in
                switch result {
                case .success(let category):
                    // TODO-8965: Either add support for category images or hide the placeholder in the UI
                    // We currently don't parse category images from the API response
                    let option = ComponentOption(id: category.categoryID, title: category.name, imageURL: nil)
                    categoryOptions.append(option)

                    if categoryID == optionIDs.last { // Replace loading placeholder with synced category options.
                        self?.options = categoryOptions
                        self?.categoriesState = .loaded
                    }
                case .failure(let error):
                    // If syncing any of the categories fails, bail and display an error instead of an incomplete list.
                    self?.options = []
                    self?.categoriesState = .notLoaded
                    self?.errorNotice = self?.createErrorNotice() { [weak self] in
                        self?.syncCategoriesIfNeeded(siteID: siteID, optionIDs: optionIDs, type: type, stores: stores)
                    }
                    DDLogError("⛔️ Unable to fetch category \(categoryID) for the composite component settings: \(error)")
                    break
                }
            }
            stores.dispatch(categoryAction)
        }
    }

    /// Creates an error notice with the provided retry action
    ///
    func createErrorNotice(retryAction: @escaping (() -> Void)) -> Notice {
        .init(title: Localization.optionsLoadingError, feedbackType: .error, actionTitle: Localization.retry, actionHandler: retryAction)
    }
}

// MARK: Constants
private extension ComponentSettingsViewModel {
    enum Localization {
        static let title = NSLocalizedString("Component Settings", comment: "Title for the settings of a component in a composite product")
        static let infoNotice = NSLocalizedString("You can edit component settings in the web dashboard.",
                                                  comment: "Info notice at the bottom of the component settings screen")
        static let noDefaultOption = NSLocalizedString("None", comment: "Label when there is no default option for a component in a composite product")
        static let optionsLoadingError = NSLocalizedString("Unable to load all component options",
                                                            comment: "Error message when component options are not loaded on the component settings screen")
        static let retry = NSLocalizedString("Retry", comment: "Retry action title")
    }

    /// Placeholder for the list of component options.
    ///
    /// Used in the redacted loading view.
    ///
    static let optionsLoadingPlaceholder: [ComponentOption] = [ComponentOption(id: 1, title: "Component Option", imageURL: nil)]
}
