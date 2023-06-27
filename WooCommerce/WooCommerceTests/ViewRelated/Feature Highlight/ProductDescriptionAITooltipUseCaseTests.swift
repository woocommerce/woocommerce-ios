import XCTest
import Yosemite
@testable import WooCommerce

final class ProductDescriptionAITooltipUseCaseTests: XCTestCase {
    // MARK: isDescriptionAIEnabled

    func test_shouldShowTooltip_is_true_only_when_isDescriptionAIEnabled_is_true() {
        let featureFlagService = MockFeatureFlagService(isProductDescriptionAIFromStoreOnboardingEnabled: true)
        var sut = ProductDescriptionAITooltipUseCase(userDefaults: MockUserDefaults(),
                                                     featureFlagService: featureFlagService,
                                                     isDescriptionAIEnabled: true)
        sut.hasDismissedWriteWithAITooltip = false
        sut.numberOfTimesWriteWithAITooltipIsShown = 2

        let product = Product.fake().copy(fullDescription: "")
        let model = EditableProductModel(product: product)
        XCTAssertTrue(sut.shouldShowTooltip(for: model))
    }

    func test_shouldShowTooltip_is_false_when_isDescriptionAIEnabled_is_false() {
        let featureFlagService = MockFeatureFlagService(isProductDescriptionAIFromStoreOnboardingEnabled: true)
        var sut = ProductDescriptionAITooltipUseCase(userDefaults: MockUserDefaults(),
                                                     featureFlagService: featureFlagService,
                                                     isDescriptionAIEnabled: false)
        sut.hasDismissedWriteWithAITooltip = false
        sut.numberOfTimesWriteWithAITooltipIsShown = 2

        let product = Product.fake().copy(fullDescription: "")
        let model = EditableProductModel(product: product)
        XCTAssertFalse(sut.shouldShowTooltip(for: model))
    }

    // MARK: Feature flag

    func test_shouldShowTooltip_is_true_only_when_isProductDescriptionAIFromStoreOnboardingEnabled_is_true() {
        let featureFlagService = MockFeatureFlagService(isProductDescriptionAIFromStoreOnboardingEnabled: true)
        var sut = ProductDescriptionAITooltipUseCase(userDefaults: MockUserDefaults(),
                                                     featureFlagService: featureFlagService,
                                                     isDescriptionAIEnabled: true)
        sut.hasDismissedWriteWithAITooltip = false
        sut.numberOfTimesWriteWithAITooltipIsShown = 2

        let product = Product.fake().copy(fullDescription: "")
        let model = EditableProductModel(product: product)
        XCTAssertTrue(sut.shouldShowTooltip(for: model))
    }

    func test_shouldShowTooltip_is_false_when_isProductDescriptionAIFromStoreOnboardingEnabled_is_false() {
        let featureFlagService = MockFeatureFlagService(isProductDescriptionAIFromStoreOnboardingEnabled: false)
        var sut = ProductDescriptionAITooltipUseCase(userDefaults: MockUserDefaults(),
                                                     featureFlagService: featureFlagService,
                                                     isDescriptionAIEnabled: true)
        sut.hasDismissedWriteWithAITooltip = false
        sut.numberOfTimesWriteWithAITooltipIsShown = 2

        let product = Product.fake().copy(fullDescription: "")
        let model = EditableProductModel(product: product)
        XCTAssertFalse(sut.shouldShowTooltip(for: model))
    }

    // MARK: Product description

    func test_shouldShowTooltip_is_true_only_when_product_description_is_empty() {
        let featureFlagService = MockFeatureFlagService(isProductDescriptionAIFromStoreOnboardingEnabled: true)
        var sut = ProductDescriptionAITooltipUseCase(userDefaults: MockUserDefaults(),
                                                     featureFlagService: featureFlagService,
                                                     isDescriptionAIEnabled: true)
        sut.hasDismissedWriteWithAITooltip = false
        sut.numberOfTimesWriteWithAITooltipIsShown = 2

        let product = Product.fake().copy(fullDescription: "")
        let model = EditableProductModel(product: product)
        XCTAssertTrue(sut.shouldShowTooltip(for: model))
    }

    func test_shouldShowTooltip_is_false_when_product_description_is_not_empty() {
        let featureFlagService = MockFeatureFlagService(isProductDescriptionAIFromStoreOnboardingEnabled: false)
        var sut = ProductDescriptionAITooltipUseCase(userDefaults: MockUserDefaults(),
                                                     featureFlagService: featureFlagService,
                                                     isDescriptionAIEnabled: true)
        sut.hasDismissedWriteWithAITooltip = false
        sut.numberOfTimesWriteWithAITooltipIsShown = 2

        let product = Product.fake().copy(fullDescription: "This is a non-empty product description.")
        let model = EditableProductModel(product: product)
        XCTAssertFalse(sut.shouldShowTooltip(for: model))
    }

    // MARK: Counter

    func test_shouldShowTooltip_is_true_only_when_counter_is_below_3() {
        let featureFlagService = MockFeatureFlagService(isProductDescriptionAIFromStoreOnboardingEnabled: true)
        var sut = ProductDescriptionAITooltipUseCase(userDefaults: MockUserDefaults(),
                                                     featureFlagService: featureFlagService,
                                                     isDescriptionAIEnabled: true)
        sut.hasDismissedWriteWithAITooltip = false
        sut.numberOfTimesWriteWithAITooltipIsShown = 2

        let product = Product.fake().copy(fullDescription: "")
        let model = EditableProductModel(product: product)
        XCTAssertTrue(sut.shouldShowTooltip(for: model))
    }

    func test_shouldShowTooltip_is_false_when_counter_is_3() {
        let featureFlagService = MockFeatureFlagService(isProductDescriptionAIFromStoreOnboardingEnabled: true)
        var sut = ProductDescriptionAITooltipUseCase(userDefaults: MockUserDefaults(),
                                                     featureFlagService: featureFlagService,
                                                     isDescriptionAIEnabled: true)
        sut.numberOfTimesWriteWithAITooltipIsShown = 3

        let product = Product.fake().copy(fullDescription: "")
        let model = EditableProductModel(product: product)
        XCTAssertFalse(sut.shouldShowTooltip(for: model))
    }

    // MARK: Dismissed by user

    func test_shouldShowTooltip_is_true_only_when_hasDismissedWriteWithAITooltip_is_false() {
        let featureFlagService = MockFeatureFlagService(isProductDescriptionAIFromStoreOnboardingEnabled: true)
        var sut = ProductDescriptionAITooltipUseCase(userDefaults: MockUserDefaults(),
                                                     featureFlagService: featureFlagService,
                                                     isDescriptionAIEnabled: true)
        sut.numberOfTimesWriteWithAITooltipIsShown = 1

        let product = Product.fake().copy(fullDescription: "")
        let model = EditableProductModel(product: product)
        XCTAssertTrue(sut.shouldShowTooltip(for: model))
    }

    func test_shouldShowTooltip_is_false_when_hasDismissedWriteWithAITooltip_is_true() {
        let featureFlagService = MockFeatureFlagService(isProductDescriptionAIFromStoreOnboardingEnabled: true)
        var sut = ProductDescriptionAITooltipUseCase(userDefaults: MockUserDefaults(),
                                                     featureFlagService: featureFlagService,
                                                     isDescriptionAIEnabled: true)
        sut.hasDismissedWriteWithAITooltip = true
        sut.numberOfTimesWriteWithAITooltipIsShown = 1

        let product = Product.fake().copy(fullDescription: "")
        let model = EditableProductModel(product: product)
        XCTAssertFalse(sut.shouldShowTooltip(for: model))
    }
}

private class MockUserDefaults: UserDefaults {
    var hasDismissedWriteWithAITooltip = false
    var numberOfTimesWriteWithAITooltipIsShown = 0

    override func bool(forKey defaultName: String) -> Bool {
        hasDismissedWriteWithAITooltip
    }

    override func set(_ value: Bool, forKey defaultName: String) {
        hasDismissedWriteWithAITooltip = value
    }

    override func integer(forKey defaultName: String) -> Int {
        numberOfTimesWriteWithAITooltipIsShown
    }

    override func set(_ integer: Int, forKey defaultName: String) {
        numberOfTimesWriteWithAITooltipIsShown = integer
    }
}
