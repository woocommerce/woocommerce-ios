import XCTest

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
        let product = MockProduct().product()
        let viewModel = AddAttributeViewModel(storesManager: storesManager, product: product)
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
        let product = MockProduct().product()
        let viewModel = AddAttributeViewModel(storesManager: storesManager, product: product)
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
        let product = MockProduct().product()
        let viewModel = AddAttributeViewModel(storesManager: storesManager, product: product)


        // When
        viewModel.handleNewAttributeNameChange("Color")


        // Then
        XCTAssertEqual(viewModel.newAttributeName, "Color")
    }

    func test_handle_invalid_new_attribute_name() {
        // Given
        let product = MockProduct().product()
        let viewModel = AddAttributeViewModel(storesManager: storesManager, product: product)


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
