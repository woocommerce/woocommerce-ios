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

    /// Whether to display images for component options
    ///
    /// Used to disable images when component options are categories.
    ///
    let shouldShowOptionImages: Bool

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

    init(title: String,
         description: String,
         imageURL: URL?,
         optionsType: String,
         options: [ComponentOption],
         defaultOptionTitle: String = Localization.noDefaultOption,
         shouldShowOptionImages: Bool = true) {
        self.componentTitle = title
        self.description = description
        self.imageURL = imageURL
        self.optionsType = optionsType
        self.options = options
        self.defaultOptionTitle = defaultOptionTitle
        self.shouldShowOptionImages = shouldShowOptionImages
    }
}

// MARK: Initializers
extension ComponentSettingsViewModel {
    /// Initializes the view model using a `Component` from the `ComponentsListViewModel`.
    /// Used when navigating to `ComponentSettings` from `ComponentsList`.
    ///
    convenience init(siteID: Int64,
                     component: ComponentsListViewModel.Component,
                     stores: StoresManager = ServiceLocator.stores,
                     storageManager: StorageManagerType = ServiceLocator.storageManager) {
        // Initialize the view model with the available component settings and placeholders for the component options.
        self.init(title: component.title,
                  description: component.description.removedHTMLTags.trimmingCharacters(in: .whitespacesAndNewlines),
                  imageURL: component.imageURL,
                  optionsType: component.optionType.description,
                  options: ComponentSettingsViewModel.optionsLoadingPlaceholder,
                  shouldShowOptionImages: component.optionType != .categoryIDs)

        // Then load details about the component options.
        loadComponentOptions(siteID: siteID,
                             optionIDs: component.optionIDs,
                             defaultOptionID: Int64(component.defaultOptionID),
                             type: component.optionType,
                             stores: stores,
                             storageManager: storageManager)
    }
}

// MARK: Private helpers
private extension ComponentSettingsViewModel {
    /// Load the component options (products or categories) if needed.
    ///
    /// Products are synced from remote, while categories are fetched from storage because they are already fully synced.
    ///
    func loadComponentOptions(siteID: Int64,
                              optionIDs: [Int64],
                              defaultOptionID: Int64?,
                              type: CompositeComponentOptionType,
                              stores: StoresManager,
                              storageManager: StorageManagerType) {
        syncProducts(siteID: siteID, optionIDs: optionIDs, defaultOptionID: defaultOptionID, type: type, stores: stores)
        fetchCategoriesIfNeeded(siteID: siteID, optionIDs: optionIDs, type: type, storageManager: storageManager)
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
                // TODO-8956: Display notice about loading error
            }
        }

        productsState = .loading
        stores.dispatch(productAction)
    }

    /// Fetches the categories from storage if the component options are categories.
    ///
    func fetchCategoriesIfNeeded(siteID: Int64, optionIDs: [Int64], type: CompositeComponentOptionType, storageManager: StorageManagerType) {
        guard type == .categoryIDs && categoriesState == .notLoaded else { return }

        categoriesState = .loading

        let predicate = NSPredicate(format: "siteID = %lld AND categoryID IN %@", siteID, optionIDs)
        let descriptor = NSSortDescriptor(keyPath: \StorageProductCategory.name, ascending: true)
        let resultsController = ResultsController<StorageProductCategory>(storageManager: storageManager, matching: predicate, sortedBy: [descriptor])

        do {
            try resultsController.performFetch()
            self.options = resultsController.fetchedObjects.map { category in
                // We don't show images for categories in the app, so the image URL is always nil.
                ComponentOption(id: category.categoryID, title: category.name, imageURL: nil)
            }
            self.categoriesState = .loaded
        } catch {
            self.options = []
            self.categoriesState = .notLoaded
            DDLogError("⛔️ Unable to fetch categories for the composite component settings: \(error)")
            // TODO-8956: Display notice about loading error
        }
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

    /// Placeholder for the list of component options.
    ///
    /// Used in the redacted loading view.
    ///
    static let optionsLoadingPlaceholder: [ComponentOption] = [ComponentOption(id: 1, title: "Component Option", imageURL: nil)]
}
