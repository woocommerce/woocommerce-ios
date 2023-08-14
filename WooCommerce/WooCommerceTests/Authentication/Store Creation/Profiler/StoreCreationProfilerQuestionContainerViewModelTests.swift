import XCTest
@testable import WooCommerce
@testable import Yosemite

final class StoreCreationProfilerQuestionContainerViewModelTests: XCTestCase {

    // MARK: - Saving answers

    func test_saveSellingStatus_updates_currentQuestion_to_category() {
        // Given
        let viewModel = StoreCreationProfilerQuestionContainerViewModel(storeName: "Test", onCompletion: { _ in })
        XCTAssertEqual(viewModel.currentQuestion, .sellingStatus)

        // When
        viewModel.saveSellingStatus(nil)

        // Then
        XCTAssertEqual(viewModel.currentQuestion, .category)
    }

    func test_saveCategory_updates_currentQuestion_to_country() {
        // Given
        let viewModel = StoreCreationProfilerQuestionContainerViewModel(storeName: "Test", onCompletion: { _ in })

        // When
        viewModel.saveCategory(nil)

        // Then
        XCTAssertEqual(viewModel.currentQuestion, .country)
    }

    func test_saveCountry_updates_currentQuestion_to_challenges() {
        // Given
        let viewModel = StoreCreationProfilerQuestionContainerViewModel(storeName: "Test", onCompletion: { _ in })

        // When
        viewModel.saveCountry(.US)

        // Then
        XCTAssertEqual(viewModel.currentQuestion, .challenges)
    }

    func test_saveFeatures_triggers_onCompletion() throws {
        // Given
        var profilerData: SiteProfilerData?
        let viewModel = StoreCreationProfilerQuestionContainerViewModel(storeName: "Test", onCompletion: { profilerData = $0 })

        // When
        viewModel.saveSellingStatus(.init(sellingStatus: .justStarting, sellingPlatforms: nil))
        viewModel.saveCategory(nil)
        viewModel.saveCountry(.US)
        viewModel.saveChallenges([])
        viewModel.saveFeatures([])

        // Then
        let data = try XCTUnwrap(profilerData)
        XCTAssertEqual(data.name, viewModel.storeName)
        XCTAssertEqual(data.sellingStatus, .justStarting)
        XCTAssertNil(data.sellingPlatforms)
        XCTAssertEqual(data.countryCode, "US")
    }

    // MARK: - `backtrackOrDismissProfiler`

    func test_backtrackOrDismissProfiler_triggers_completionHandler_without_profiler_data_if_current_question_is_selling_status() {
        // Given
        var triggeredCompletion = false
        var profilerData: SiteProfilerData?
        let viewModel = StoreCreationProfilerQuestionContainerViewModel(storeName: "Test", onCompletion: {
            profilerData = $0
            triggeredCompletion = true
        })
        XCTAssertEqual(viewModel.currentQuestion, .sellingStatus)

        // When
        viewModel.backtrackOrDismissProfiler()

        // Then
        XCTAssertTrue(triggeredCompletion)
        XCTAssertNil(profilerData)
    }

    func test_backtrackOrDismissProfiler_sets_current_question_to_selling_status_if_current_question_is_category() {
        // Given
        var triggeredCompletion = false
        let viewModel = StoreCreationProfilerQuestionContainerViewModel(storeName: "Test", onCompletion: { _ in triggeredCompletion = true })
        viewModel.saveSellingStatus(nil)

        // When
        viewModel.backtrackOrDismissProfiler()

        // Then
        XCTAssertFalse(triggeredCompletion)
        XCTAssertEqual(viewModel.currentQuestion, .sellingStatus)
    }

    func test_backtrackOrDismissProfiler_sets_current_question_to_category_if_current_question_is_country() {
        // Given
        var triggeredCompletion = false
        let viewModel = StoreCreationProfilerQuestionContainerViewModel(storeName: "Test", onCompletion: { _ in triggeredCompletion = true })
        viewModel.saveCategory(nil)

        // When
        viewModel.backtrackOrDismissProfiler()

        // Then
        XCTAssertFalse(triggeredCompletion)
        XCTAssertEqual(viewModel.currentQuestion, .category)
    }

    func test_backtrackOrDismissProfiler_sets_current_question_to_country_if_current_question_is_challenges() {
        // Given
        var triggeredCompletion = false
        let viewModel = StoreCreationProfilerQuestionContainerViewModel(storeName: "Test", onCompletion: { _ in triggeredCompletion = true })
        viewModel.saveCountry(.US)

        // When
        viewModel.backtrackOrDismissProfiler()

        // Then
        XCTAssertFalse(triggeredCompletion)
        XCTAssertEqual(viewModel.currentQuestion, .country)
    }

    func test_backtrackOrDismissProfiler_sets_current_question_to_challenges_if_current_question_is_features() {
        // Given
        var triggeredCompletion = false
        let viewModel = StoreCreationProfilerQuestionContainerViewModel(storeName: "Test", onCompletion: { _ in triggeredCompletion = true })
        viewModel.saveChallenges([])

        // When
        viewModel.backtrackOrDismissProfiler()

        // Then
        XCTAssertFalse(triggeredCompletion)
        XCTAssertEqual(viewModel.currentQuestion, .challenges)
    }

    // MARK: - Analytics
}
