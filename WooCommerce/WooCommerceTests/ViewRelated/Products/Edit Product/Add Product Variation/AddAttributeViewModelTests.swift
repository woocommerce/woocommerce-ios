import XCTest
import Experiments

@testable import WooCommerce
@testable import Yosemite
@testable import Networking


/// Tests for `AddAttributeViewModel`.
///
final class AddAttributeViewModelTests: XCTestCase {

    private var storesManager: MockProductAttributeStoresManager!

    override func setUp() {
        super.setUp()
        storesManager = MockProductAttributeStoresManager()
    }

    override func tearDown() {
        super.tearDown()
        storesManager = nil
    }

    func test_it_transitions_to_synced_state_after_synchronizing_attributes() throws {
        // Given
        let product = Product.fake()
        let viewModel = AddAttributeViewModel(storesManager: storesManager, product: product, featureFlagService: MockFeatureFlagService())
        storesManager.productAttributeResponse = .success([])

        // When
        viewModel.performFetch()
        let result: Bool = waitFor { promise in
            viewModel.observeProductAttributesListStateChanges { state in
                if state == .synced {
                    promise(true)
                }
            }
        }

        // Then
        XCTAssertTrue(result)
        XCTAssertEqual(storesManager.numberOfResponsesConsumed, 1)
    }

    func test_it_transitions_to_failed_state_after_synchronizing_attributes_errors() throws {
        // Given
        let product = Product.fake()
        let viewModel = AddAttributeViewModel(storesManager: storesManager, product: product, featureFlagService: MockFeatureFlagService())
        storesManager.productAttributeResponse = .success([])

        let rawError = NSError(domain: "Attribute Error", code: 1, userInfo: nil)
        storesManager.productAttributeResponse = .failure(rawError)

        // When
        viewModel.performFetch()
        let result: Bool = waitFor { promise in
            viewModel.observeProductAttributesListStateChanges { state in
                if state == .failed {
                    promise(true)
                }
            }
        }

        // Then
        XCTAssertTrue(result)
        XCTAssertEqual(storesManager.numberOfResponsesConsumed, 1)
    }

    func test_handle_valid_new_attribute_name() {
        // Given
        let product = Product.fake()
        let viewModel = AddAttributeViewModel(storesManager: storesManager, product: product, featureFlagService: MockFeatureFlagService())


        // When
        viewModel.handleNewAttributeNameChange("Color")


        // Then
        XCTAssertEqual(viewModel.newAttributeName, "Color")
    }

    func test_handle_invalid_new_attribute_name() {
        // Given
        let product = Product.fake()
        let viewModel = AddAttributeViewModel(storesManager: storesManager, product: product, featureFlagService: MockFeatureFlagService())


        // When
        viewModel.handleNewAttributeNameChange(nil)
            // Then
            XCTAssertNil(viewModel.newAttributeName)

        // When
        viewModel.handleNewAttributeNameChange("")
            // Then
            XCTAssertNil(viewModel.newAttributeName)
    }
}

extension AddAttributeViewModelTests {
    func test_when_feature_is_on_outside_variations_flow_then_product_attributes_not_used_for_variations_are_listed() {
        // Given
        let material = ProductAttribute.fake().copy(attributeID: 0, name: "Material", variation: false, options: ["Cotton"])
        let viewModel = AddAttributeViewModel(storesManager: storesManager,
                                              product: Product.fake().copy(attributes: [material]),
                                              featureFlagService: featureFlagService(isNonVariationAttributesEnabled: true))
        storesManager.productAttributeResponse = .success([])

        // When
        viewModel.performFetch()

        // Then
        XCTAssertEqual(viewModel.localAndGlobalAttributes, [material])
        XCTAssertNil(viewModel.sections.first?.footer)
    }

    func test_when_feature_is_on_in_variations_flow_then_product_attributes_not_used_for_variations_are_not_listed() {
        // Given
        let material = ProductAttribute.fake().copy(attributeID: 0, name: "Material", variation: false, options: ["Cotton"])
        let viewModel = AddAttributeViewModel(storesManager: storesManager,
                                              product: Product.fake().copy(attributes: [material]),
                                              isVariationsFlow: true,
                                              featureFlagService: featureFlagService(isNonVariationAttributesEnabled: true))
        storesManager.productAttributeResponse = .success([])

        // When
        viewModel.performFetch()

        // Then
        XCTAssertEqual(viewModel.localAndGlobalAttributes, [])
        XCTAssertNotNil(viewModel.sections.first?.footer)
    }

    private func featureFlagService(isNonVariationAttributesEnabled: Bool) -> MockFeatureFlagService {
        let service = MockFeatureFlagService()
        service.isFeatureFlagEnabledReturnValue[.nonVariationProductAttributes] = isNonVariationAttributesEnabled
        return service
    }
}

/// Mock Product Attribute Store Manager
///
private final class MockProductAttributeStoresManager: DefaultStoresManager {

    /// Set mock responses to be dispatched upon Product Attribute Actions.
    ///
    var productAttributeResponse: Result<[ProductAttribute], Error> = .success([])

    /// Indicates how many times responses where consumed
    ///
   private(set) var numberOfResponsesConsumed = 0

    init() {
        super.init(sessionManager: SessionManager.testingInstance)
    }

    override func dispatch(_ action: Action) {
        if let productAttributeAction = action as? ProductAttributeAction {
            handleProductAttributeAction(productAttributeAction)
        }
    }

    private func handleProductAttributeAction(_ action: ProductAttributeAction) {
        switch action {
        case let .synchronizeProductAttributes(_, onCompletion):
            numberOfResponsesConsumed = numberOfResponsesConsumed + 1
            onCompletion(productAttributeResponse)
        default:
            return
        }
    }
}
