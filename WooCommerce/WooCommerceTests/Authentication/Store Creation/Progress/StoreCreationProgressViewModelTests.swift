import XCTest
@testable import WooCommerce

final class StoreCreationProgressViewModelTests: XCTestCase {
    // MARK: Initial values

    func test_totalProgressAmount_has_correct_initial_value() {
        // Given
        let sut = StoreCreationProgressViewModel(estimatedTimePerProgress: 1)

        // Then
        XCTAssertEqual(sut.totalProgressAmount, StoreCreationProgressViewModel.Progress.finished.rawValue)
    }

    func test_progressValue_has_correct_initial_value() {
        // Given
        let sut = StoreCreationProgressViewModel(estimatedTimePerProgress: 1)

        // Then
        XCTAssertEqual(sut.progressValue, StoreCreationProgressViewModel.Progress.creatingStore.rawValue)
    }

    // MARK: On appear

    func test_onAppear_increments_progressValue_at_expected_interval() {
        // Given
        let timeInterval = 0.1
        let incrementInterval = 1.0
        let sut = StoreCreationProgressViewModel(estimatedTimePerProgress: incrementInterval,
                                                 progressViewAnimationTimerInterval: timeInterval)
        let gapBetweenProgress = StoreCreationProgressViewModel.Progress.allCases[1].rawValue - StoreCreationProgressViewModel.Progress.allCases[0].rawValue
        let expectedIncrement = (gapBetweenProgress / (incrementInterval / timeInterval))

        // When
        sut.onAppear()

        waitFor { promise in
            DispatchQueue.main.asyncAfter(deadline: .now() + timeInterval + (timeInterval * 0.1)) {
                promise(())
            }
        }

        // Then
        XCTAssertEqual(sut.progressValue, StoreCreationProgressViewModel.Progress.creatingStore.rawValue + expectedIncrement)
    }

    func test_onAppear_increments_progressValue_only_upto_next_progress() {
        // Given
        let timeInterval = 0.1
        let incrementInterval = 1.0
        let sut = StoreCreationProgressViewModel(estimatedTimePerProgress: incrementInterval,
                                                 progressViewAnimationTimerInterval: timeInterval)

        // Then
        XCTAssertEqual(sut.progressValue, StoreCreationProgressViewModel.Progress.creatingStore.rawValue)

        // When
        sut.onAppear()

        // Giving enough time to process all enum cases. (The logic should only process upto the next case)
        waitFor { promise in
            DispatchQueue.main.asyncAfter(deadline: .now() + timeInterval * Double(StoreCreationProgressViewModel.Progress.allCases.count)) {
                promise(())
            }
        }

        // Then
        XCTAssertGreaterThan(sut.progressValue, StoreCreationProgressViewModel.Progress.creatingStore.rawValue)
        XCTAssertLessThan(sut.progressValue, StoreCreationProgressViewModel.Progress.buildingFoundations.rawValue)
    }

    func test_onAppear_increments_progressValue_as_expected_after_calling_incrementProgress() {
        // Given
        let timeInterval = 0.1
        let incrementInterval = 1.0
        let sut = StoreCreationProgressViewModel(estimatedTimePerProgress: incrementInterval,
                                                 progressViewAnimationTimerInterval: timeInterval)

        // Then
        XCTAssertEqual(sut.progressValue, StoreCreationProgressViewModel.Progress.creatingStore.rawValue)

        // When
        sut.onAppear()
        sut.incrementProgress()

        // Giving enough time to process all enum cases. (The logic should only process upto the next case)
        waitFor { promise in
            DispatchQueue.main.asyncAfter(deadline: .now() + timeInterval * Double(StoreCreationProgressViewModel.Progress.allCases.count)) {
                promise(())
            }
        }

        // Then
        XCTAssertGreaterThan(sut.progressValue, StoreCreationProgressViewModel.Progress.buildingFoundations.rawValue)
        XCTAssertLessThan(sut.progressValue, StoreCreationProgressViewModel.Progress.organizingStockRoom.rawValue)
    }

    // MARK: Incrementing to next progress stage

    func test_incrementProgress_sets_progressValue_as_expected() {
        // Given
        let sut = StoreCreationProgressViewModel(estimatedTimePerProgress: 1)

        // Then
        XCTAssertEqual(sut.progressValue, StoreCreationProgressViewModel.Progress.creatingStore.rawValue)

        // When
        sut.incrementProgress()

        // Then
        XCTAssertEqual(sut.progressValue, StoreCreationProgressViewModel.Progress.buildingFoundations.rawValue)

        // When
        sut.incrementProgress()

        // Then
        XCTAssertEqual(sut.progressValue, StoreCreationProgressViewModel.Progress.organizingStockRoom.rawValue)

        // When
        sut.incrementProgress()

        // Then
        XCTAssertEqual(sut.progressValue, StoreCreationProgressViewModel.Progress.applyingFinishingTouches.rawValue)

        // When
        sut.incrementProgress()

        // Then
        XCTAssertEqual(sut.progressValue, StoreCreationProgressViewModel.Progress.turningOnTheLights.rawValue)

        // When
        sut.incrementProgress()

        // Then
        XCTAssertEqual(sut.progressValue, StoreCreationProgressViewModel.Progress.openingTheDoors.rawValue)

        // When
        sut.incrementProgress()

        // Then
        XCTAssertEqual(sut.progressValue, StoreCreationProgressViewModel.Progress.finished.rawValue)

        // When
        sut.incrementProgress()

        // Then
        XCTAssertEqual(sut.progressValue, StoreCreationProgressViewModel.Progress.finished.rawValue)
    }

    // MARK: Marking as complete

    func test_markAsComplete_sets_progressValue_as_finished() {
        // Given
        let sut = StoreCreationProgressViewModel(estimatedTimePerProgress: 1)

        // When
        sut.markAsComplete()

        // Then
        XCTAssertEqual(sut.progressValue, StoreCreationProgressViewModel.Progress.finished.rawValue)
    }
}
