import Combine
import XCTest
import Yosemite
@testable import WooCommerce

@MainActor
final class ProductDescriptionGenerationViewModelTests: XCTestCase {
    private var stores: MockStoresManager!
    private var subscriptions: Set<AnyCancellable> = []

    override func setUp() {
        super.setUp()

        stores = MockStoresManager(sessionManager: .testingInstance)
    }

    override func tearDown() {
        stores = nil

        super.tearDown()
    }

    // MARK: - `suggestedText`

    func test_suggestedText_is_set_after_generateDescription_success() throws {
        // Given
        mockGeneratedDescription(result: .success("Must buy"))

        let viewModel = ProductDescriptionGenerationViewModel(siteID: 6, name: "", description: "", stores: stores, onApply: { _ in })
        XCTAssertNil(viewModel.suggestedText)

        // When
        viewModel.generateDescription()

        // Then
        waitUntil {
            viewModel.suggestedText == "Must buy"
        }
    }

    // MARK: - `errorMessage`

    func test_errorMessage_is_set_after_generateDescription_failure() throws {
        // Given
        mockGeneratedDescription(result: .failure(TestError.generationFailure))

        let viewModel = ProductDescriptionGenerationViewModel(siteID: 6, name: "", description: "", stores: stores, onApply: { _ in })

        // When
        viewModel.generateDescription()

        // Then
        waitUntil {
            viewModel.errorMessage == "Generation error"
        }
    }

    // MARK: - `onApply`

    func test_applyToProductonApply_invokes_onApply_with_generated_description_and_updated_product_name() throws {
        // Given
        mockGeneratedDescription(result: .success("Must buy"))

        var productContent: ProductDescriptionGenerationOutput?
        let viewModel = ProductDescriptionGenerationViewModel(siteID: 6,
                                                              name: "",
                                                              description: "Durable",
                                                              stores: stores,
                                                              onApply: { content in
            productContent = content
        })

        // When
        viewModel.name = "Fun"
        viewModel.generateDescription()
        waitUntil {
            viewModel.isGenerationInProgress == false
        }
        viewModel.applyToProduct()

        // Then
        XCTAssertEqual(productContent, .init(name: "Fun", description: "Must buy"))
    }

    // MARK: - `isGenerationInProgress`

    func test_isGenerationInProgress_becomes_true_when_generating_description() throws {
        // Given
        let viewModel = ProductDescriptionGenerationViewModel(siteID: 6, name: "", description: "", onApply: { _ in })
        XCTAssertFalse(viewModel.isGenerationInProgress)

        // When
        viewModel.generateDescription()

        // Then
        XCTAssertTrue(viewModel.isGenerationInProgress)
    }

    func test_isGenerationInProgress_becomes_true_then_false_when_toggling_description_twice() throws {
        // Given
        let viewModel = ProductDescriptionGenerationViewModel(siteID: 6, name: "", description: "", onApply: { _ in })

        // When toggling generation
        viewModel.toggleDescriptionGeneration()

        // Then `isGenerationInProgress` becomes `true`
        XCTAssertTrue(viewModel.isGenerationInProgress)

        // When toggling generation again
        viewModel.toggleDescriptionGeneration()

        // Then `isGenerationInProgress` becomes `true`
        XCTAssertFalse(viewModel.isGenerationInProgress)
    }

    func test_isGenerationInProgress_becomes_false_when_toggling_description_completes() throws {
        // Given
        let viewModel = ProductDescriptionGenerationViewModel(siteID: 6, name: "", description: "", stores: stores, onApply: { _ in })
        mockGeneratedDescription(result: .success(""))

        var isGenerationInProgressValues: [Bool] = []
        viewModel.$isGenerationInProgress.sink { value in
            isGenerationInProgressValues.append(value)
        }.store(in: &subscriptions)

        XCTAssertEqual(isGenerationInProgressValues, [false])

        // When
        viewModel.toggleDescriptionGeneration()

        // Then
        waitUntil {
            isGenerationInProgressValues == [false, true, false]
        }
    }

    // MARK: - `isGenerationEnabled`

    func test_isGenerationEnabled_is_false_when_product_name_is_empty() throws {
        // Given
        let viewModel = ProductDescriptionGenerationViewModel(siteID: 6, name: "", description: "a product", onApply: { _ in })

        // Then
        XCTAssertFalse(viewModel.isGenerationEnabled)
    }

    func test_isGenerationEnabled_is_false_when_product_description_is_empty() throws {
        // Given
        let viewModel = ProductDescriptionGenerationViewModel(siteID: 6, name: "Woo plate", description: "", onApply: { _ in })

        // Then
        XCTAssertFalse(viewModel.isGenerationEnabled)
    }

    func test_isGenerationEnabled_is_true_when_product_name_and_description_are_not_empty() throws {
        // Given
        let viewModel = ProductDescriptionGenerationViewModel(siteID: 6, name: "Woo", description: "a product", onApply: { _ in })

        // Then
        XCTAssertTrue(viewModel.isGenerationEnabled)
    }
}

private extension ProductDescriptionGenerationViewModelTests {
    func mockGeneratedDescription(result: Result<String, Error>) {
        stores.whenReceivingAction(ofType: ProductAction.self) { action in
            guard case let .generateProductDescription(_, _, _, _, completion) = action else {
                return XCTFail("Unexpected action: \(action)")
            }
            completion(result)
        }
    }
}

private enum TestError: LocalizedError {
    case generationFailure

    var errorDescription: String? {
        switch self {
        case .generationFailure:
            return "Generation error"
        }
    }
}
