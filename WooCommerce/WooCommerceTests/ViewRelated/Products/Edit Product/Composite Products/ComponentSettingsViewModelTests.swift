import XCTest
@testable import WooCommerce
@testable import Yosemite
@testable import Storage

final class ComponentSettingsViewModelTests: XCTestCase {

    private let sampleSiteID: Int64 = 12345
    private var storageManager: MockStorageManager!
    private var storage: StorageType {
        storageManager.viewStorage
    }
    private let stores = MockStoresManager(sessionManager: .testingInstance)

    override func setUp() {
        super.setUp()
        storageManager = MockStorageManager()
        stores.reset()
    }

    override func tearDown() {
        storageManager = nil
        super.tearDown()
    }

    func test_component_image_and_description_visible_when_set() throws {
        // Given
        let imageURL = try XCTUnwrap(URL(string: "https://woocommerce.com/woo.jpg"))
        let viewModel = ComponentSettingsViewModel(title: "",
                                                   description: "Description",
                                                   imageURL: imageURL,
                                                   optionsType: "",
                                                   options: [],
                                                   defaultOptionTitle: "")

        // Then
        XCTAssertTrue(viewModel.shouldShowDescription)
        XCTAssertTrue(viewModel.shouldShowImage)
    }

    func test_component_image_and_description_hidden_when_not_set() {
        // Given
        let viewModel = ComponentSettingsViewModel(title: "", description: "", imageURL: nil, optionsType: "", options: [], defaultOptionTitle: "")

        // Then
        XCTAssertFalse(viewModel.shouldShowDescription)
        XCTAssertFalse(viewModel.shouldShowImage)
    }

    func test_view_model_prefills_expected_data_from_component_list() {
        // Given
        let component = sampleComponent(id: "1",
                                        title: "Camera Body",
                                        imageURL: URL(string: "https://woocommerce.com/woo.jpg"),
                                        description: "Choose between the Nikon D600 or the powerful Canon EOS 5D Mark IV.",
                                        optionType: .productIDs,
                                        optionIDs: [],
                                        defaultOptionID: "")

        // When
        let viewModel = ComponentSettingsViewModel(siteID: sampleSiteID, component: component)

        // Then
        XCTAssertEqual(viewModel.componentTitle, component.title)
        XCTAssertEqual(viewModel.description, component.description)
        XCTAssertEqual(viewModel.imageURL, component.imageURL)
        XCTAssertEqual(viewModel.optionsType, component.optionType.description)
        XCTAssertEqual(viewModel.options, [])
        XCTAssertEqual(viewModel.defaultOptionTitle,
                       NSLocalizedString("None", comment: "Label when there is no default option for a component in a composite product"))
    }

    func test_view_model_loads_category_component_options() {
        // Given
        let component = sampleComponent(optionType: .categoryIDs,
                                        optionIDs: [1],
                                        defaultOptionID: "10")
        let defaultProduct = Product.fake().copy(siteID: sampleSiteID, productID: 10, name: "Canon EF 70-200MM F:2.8 L USM")
        let expectedCategory = ProductCategory(categoryID: 1, siteID: sampleSiteID, parentID: 0, name: "Camera Lenses", slug: "camera-lenses")
        stores.whenReceivingAction(ofType: ProductAction.self) { action in
            switch action {
            case let .retrieveProducts(_, _, _, _, onCompletion):
                let products = [defaultProduct]
                onCompletion(.success((products: products, hasNextPage: false)))
            default:
                XCTFail("Received unsupported action: \(action)")
            }
        }
        stores.whenReceivingAction(ofType: ProductCategoryAction.self) { action in
            switch action {
            case let .synchronizeProductCategory(_, _, onCompletion):
                onCompletion(.success(expectedCategory))
            default:
                XCTFail("Received unsupported action: \(action)")
            }
        }

        // When
        let viewModel = ComponentSettingsViewModel(siteID: self.sampleSiteID, component: component, stores: self.stores)

        // Then
        XCTAssertEqual(viewModel.options.count, 1)
        XCTAssertEqual(viewModel.options.first?.id, expectedCategory.categoryID)
        XCTAssertEqual(viewModel.options.first?.title, expectedCategory.name)
        XCTAssertEqual(viewModel.options.first?.imageURL, nil)
        XCTAssertEqual(viewModel.defaultOptionTitle, defaultProduct.name)
    }

    func test_view_model_loads_product_component_options() {
        // Given
        let component = sampleComponent(optionType: .productIDs,
                                        optionIDs: [11],
                                        defaultOptionID: "11")
        let expectedProduct = Product.fake().copy(siteID: sampleSiteID,
                                                  productID: 11,
                                                  name: "Nikon D600 Digital SLR Camera Body",
                                                  images: [.fake().copy(src: "https://woocommerce.com/woo.jpg")])
        self.stores.whenReceivingAction(ofType: ProductAction.self) { action in
            switch action {
            case let .retrieveProducts(_, _, _, _, onCompletion):
                let products = [expectedProduct]
                onCompletion(.success((products: products, hasNextPage: false)))
            default:
                XCTFail("Received unsupported action: \(action)")
            }
        }

        // When
        let viewModel = ComponentSettingsViewModel(siteID: self.sampleSiteID, component: component, stores: self.stores)

        // Then
        XCTAssertEqual(viewModel.options.count, 1)
        XCTAssertEqual(viewModel.options.first?.id, expectedProduct.productID)
        XCTAssertEqual(viewModel.options.first?.title, expectedProduct.name)
        XCTAssertEqual(viewModel.options.first?.imageURL, expectedProduct.imageURL)
        XCTAssertEqual(viewModel.defaultOptionTitle, expectedProduct.name)
    }

    func test_view_model_has_expected_values_after_loading_error_for_product_options() {
        // Given
        stores.whenReceivingAction(ofType: ProductAction.self) { action in
            switch action {
            case let .retrieveProducts(_, _, _, _, onCompletion):
                let error = NSError(domain: "", code: 0)
                onCompletion(.failure(error))
            default:
                XCTFail("Received unsupported action: \(action)")
            }
        }

        // When
        let viewModel = ComponentSettingsViewModel(siteID: self.sampleSiteID,
                                                   component: self.sampleComponent(optionIDs: [1], defaultOptionID: "1"),
                                                   stores: self.stores)

        // Then
        XCTAssertEqual(viewModel.options.count, 0, "Loading placeholder was not removed after loading error.")
        XCTAssertEqual(viewModel.defaultOptionTitle,
                       NSLocalizedString("None", comment: "Label when there is no default option for a component in a composite product"))
        XCTAssertFalse(viewModel.showOptionsLoadingIndicator)
        XCTAssertFalse(viewModel.showDefaultOptionLoadingIndicator)
    }

    func test_view_model_has_expected_values_after_loading_errors_for_category_options() {
        // Given
        stores.whenReceivingAction(ofType: ProductAction.self) { action in
            switch action {
            case let .retrieveProducts(_, _, _, _, onCompletion):
                let error = NSError(domain: "", code: 0)
                onCompletion(.failure(error))
            default:
                XCTFail("Received unsupported action: \(action)")
            }
        }
        stores.whenReceivingAction(ofType: ProductCategoryAction.self) { action in
            switch action {
            case let .synchronizeProductCategory(_, _, onCompletion):
                let error = NSError(domain: "", code: 0)
                onCompletion(.failure(error))
            default:
                XCTFail("Received unsupported action: \(action)")
            }
        }

        // When
        let viewModel = ComponentSettingsViewModel(siteID: self.sampleSiteID,
                                                   component: self.sampleComponent(optionType: .categoryIDs, optionIDs: [1], defaultOptionID: "1"),
                                                   stores: self.stores)

        // Then
        XCTAssertEqual(viewModel.options.count, 0, "Loading placeholder was not removed after loading error.")
        XCTAssertEqual(viewModel.defaultOptionTitle,
                       NSLocalizedString("None", comment: "Label when there is no default option for a component in a composite product"))
        XCTAssertFalse(viewModel.showOptionsLoadingIndicator)
        XCTAssertFalse(viewModel.showDefaultOptionLoadingIndicator)
    }
}

private extension ComponentSettingsViewModelTests {
    func sampleComponent(id: String = "",
                         title: String = "",
                         imageURL: URL? = nil,
                         description: String = "",
                         optionType: CompositeComponentOptionType = .productIDs,
                         optionIDs: [Int64] = [],
                         defaultOptionID: String = "") -> ComponentsListViewModel.Component {
        ComponentsListViewModel.Component(id: id,
                                          title: title,
                                          imageURL: imageURL,
                                          description: description,
                                          optionType: optionType,
                                          optionIDs: optionIDs,
                                          defaultOptionID: defaultOptionID)
    }
}
