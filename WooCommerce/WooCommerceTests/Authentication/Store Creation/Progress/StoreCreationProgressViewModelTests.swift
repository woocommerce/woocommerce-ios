import XCTest
@testable import WooCommerce

final class StoreCreationProgressViewModelTests: XCTestCase {
    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }

    // MARK: Initial values

    func test_progress_has_correct_initial_value() {
        // Given
        let sut = StoreCreationProgressViewModel(incrementInterval: 1)

        // Then
        XCTAssertEqual(sut.progress, StoreCreationProgressViewModel.Progress.creatingStore)
    }

    func test_totalProgressAmount_has_correct_initial_value() {
        // Given
        let sut = StoreCreationProgressViewModel(incrementInterval: 1)

        // Then
        XCTAssertEqual(sut.totalProgressAmount, StoreCreationProgressViewModel.Progress.finished.rawValue)
    }

    func test_progressValue_has_correct_initial_value() {
        // Given
        let sut = StoreCreationProgressViewModel(incrementInterval: 1)

        // Then
        XCTAssertEqual(sut.progressValue, StoreCreationProgressViewModel.Progress.creatingStore.rawValue)
    }

    // MARK: On appear

    func test_onAppear_increments_progressValue_at_expected_interval() {
        // Given
        let timeInterval = 0.01
        let incrementInterval = 1.0
        let sut = StoreCreationProgressViewModel(incrementInterval: incrementInterval,
                                                 progressViewAnimationTimerInterval: timeInterval)

        // When
        sut.onAppear()

        // Then
        // Wait a tiny bit longer than `timeInterval`
        DispatchQueue.main.asyncAfter(deadline: .now() + (timeInterval + (timeInterval * 0.1))) {
            XCTAssertEqual(sut.progressValue, StoreCreationProgressViewModel.Progress.creatingStore.rawValue + Float(incrementInterval / timeInterval))
        }
    }

    func test_onAppear_increments_progressValue_only_upto_next_progress() {
        // Given
        let timeInterval = 0.01
        let incrementInterval = 1.0
        let sut = StoreCreationProgressViewModel(incrementInterval: incrementInterval,
                                                 progressViewAnimationTimerInterval: timeInterval)

        // Then
        XCTAssertEqual(sut.progressValue, StoreCreationProgressViewModel.Progress.creatingStore.rawValue)

        // When
        sut.onAppear()

        // Then
        // Giving enough time to process all enum cases. (The logic should only process upto the next case)
        DispatchQueue.main.asyncAfter(deadline: .now() + timeInterval * Double(StoreCreationProgressViewModel.Progress.allCases.count)) {
            XCTAssertGreaterThan(sut.progressValue, StoreCreationProgressViewModel.Progress.creatingStore.rawValue)
            XCTAssertLessThan(sut.progressValue, StoreCreationProgressViewModel.Progress.buildingFoundations.rawValue)
        }
    }

    func test_onAppear_increments_progressValue_as_expected_after_calling_incrementProgress() {
        // Given
        let timeInterval = 0.01
        let incrementInterval = 1.0
        let sut = StoreCreationProgressViewModel(incrementInterval: incrementInterval,
                                                 progressViewAnimationTimerInterval: timeInterval)

        // Then
        XCTAssertEqual(sut.progressValue, StoreCreationProgressViewModel.Progress.creatingStore.rawValue)

        // When
        sut.onAppear()
        sut.incrementProgress()

        // Then
        // Giving enough time to process all enum cases. (The logic should only process upto the next case)
        DispatchQueue.main.asyncAfter(deadline: .now() + timeInterval * Double(StoreCreationProgressViewModel.Progress.allCases.count)) {
            XCTAssertGreaterThan(sut.progressValue, StoreCreationProgressViewModel.Progress.buildingFoundations.rawValue)
            XCTAssertLessThan(sut.progressValue, StoreCreationProgressViewModel.Progress.organizingStockRoom.rawValue)
        }
    }

    // MARK: Incrementing to next progress stage

    func test_incrementProgress_sets_progress_as_expected() {
        // Given
        let sut = StoreCreationProgressViewModel(incrementInterval: 1)

        // Then
        XCTAssertEqual(sut.progress, StoreCreationProgressViewModel.Progress.creatingStore)

        // When
        sut.incrementProgress()

        // Then
        XCTAssertEqual(sut.progress, StoreCreationProgressViewModel.Progress.buildingFoundations)

        // When
        sut.incrementProgress()

        // Then
        XCTAssertEqual(sut.progress, StoreCreationProgressViewModel.Progress.organizingStockRoom)

        // When
        sut.incrementProgress()

        // Then
        XCTAssertEqual(sut.progress, StoreCreationProgressViewModel.Progress.applyingFinishingTouches)

        // When
        sut.incrementProgress()

        // Then
        XCTAssertEqual(sut.progress, StoreCreationProgressViewModel.Progress.finished)

        // When
        sut.incrementProgress()

        // Then
        XCTAssertEqual(sut.progress, StoreCreationProgressViewModel.Progress.finished)
    }

    // MARK: Marking as complete

    func test_markAsComplete_sets_progress_as_finished() {
        // Given
        let sut = StoreCreationProgressViewModel(incrementInterval: 1)

        // When
        sut.markAsComplete()

        // Then
        XCTAssertEqual(sut.progress, StoreCreationProgressViewModel.Progress.finished)
    }
}
