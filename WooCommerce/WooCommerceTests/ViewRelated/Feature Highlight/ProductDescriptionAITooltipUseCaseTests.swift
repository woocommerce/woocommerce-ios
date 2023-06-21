import XCTest
@testable import WooCommerce

final class ProductDescriptionAITooltipUseCaseTests: XCTestCase {
    // MARK: Counter

    func test_shouldShowTooltip_is_true_only_when_counter_is_below_3() {
        var sut = ProductDescriptionAITooltipUseCase(userDefaults: MockUserDefaults())
        sut.hasDismissedWriteWithAITooltip = false
        sut.numberOfTimesWriteWithAITooltipIsShown = 2

        XCTAssertTrue(sut.shouldShowTooltip)
    }

    func test_shouldShowTooltip_is_false_when_counter_is_3() {
        var sut = ProductDescriptionAITooltipUseCase(userDefaults: MockUserDefaults())
        sut.hasDismissedWriteWithAITooltip = false
        sut.numberOfTimesWriteWithAITooltipIsShown = 3

        XCTAssertFalse(sut.shouldShowTooltip)
    }

    // MARK: Dismissed by user

    func test_shouldShowTooltip_is_true_only_when_hasDismissedWriteWithAITooltip_is_false() {
        var sut = ProductDescriptionAITooltipUseCase(userDefaults: MockUserDefaults())
        sut.hasDismissedWriteWithAITooltip = false
        sut.numberOfTimesWriteWithAITooltipIsShown = 1

        XCTAssertTrue(sut.shouldShowTooltip)
    }

    func test_shouldShowTooltip_is_false_when_hasDismissedWriteWithAITooltip_is_true() {
        var sut = ProductDescriptionAITooltipUseCase(userDefaults: MockUserDefaults())
        sut.hasDismissedWriteWithAITooltip = true
        sut.numberOfTimesWriteWithAITooltipIsShown = 1

        XCTAssertFalse(sut.shouldShowTooltip)
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
