import Testing
@testable import ParcelFittingCheck

@Suite("ARParcelSizingViewModel")
struct ARParcelSizingViewModelTests {

    // MARK: - recordGestureCompleted

    @Test func test_recordGestureCompleted_when_resize_then_increments_resizeCount() {
        // Given
        let sut = ARParcelSizingViewModel(unit: .centimeters)

        // When
        sut.recordGestureCompleted(mode: .resize)
        sut.recordGestureCompleted(mode: .resize)

        // Then
        #expect(sut.resizeCount == 2)
        #expect(sut.rotateCount == 0)
    }

    @Test func test_recordGestureCompleted_when_rotate_then_increments_rotateCount() {
        // Given
        let sut = ARParcelSizingViewModel(unit: .centimeters)

        // When
        sut.recordGestureCompleted(mode: .rotate)

        // Then
        #expect(sut.rotateCount == 1)
        #expect(sut.resizeCount == 0)
    }

    @Test func test_recordGestureCompleted_when_undecided_then_does_not_increment() {
        // Given
        let sut = ARParcelSizingViewModel(unit: .centimeters)

        // When
        sut.recordGestureCompleted(mode: .undecided)

        // Then
        #expect(sut.resizeCount == 0)
        #expect(sut.rotateCount == 0)
    }

    // MARK: - recordReset

    @Test func test_recordReset_increments_resetCount() {
        // Given
        let sut = ARParcelSizingViewModel(unit: .centimeters)

        // When
        sut.recordReset()
        sut.recordReset()
        sut.recordReset()

        // Then
        #expect(sut.resetCount == 3)
    }

    // MARK: - recordARReady

    @Test func test_recordARReady_when_called_first_time_then_sets_arReadyTime() {
        // Given
        let sut = ARParcelSizingViewModel(unit: .centimeters)
        #expect(sut.arReadyTime == nil)

        // When
        sut.recordARReady()

        // Then
        #expect(sut.arReadyTime != nil)
    }

    @Test func test_recordARReady_when_called_twice_then_keeps_first_time() {
        // Given
        let sut = ARParcelSizingViewModel(unit: .centimeters)
        sut.recordARReady()
        let firstTime = sut.arReadyTime

        // When
        sut.recordARReady()

        // Then
        #expect(sut.arReadyTime == firstTime)
    }

    // MARK: - hasTrackedPlacement

    @Test func test_hasTrackedPlacement_defaults_to_false() {
        // Given / When
        let sut = ARParcelSizingViewModel(unit: .centimeters)

        // Then
        #expect(sut.hasTrackedPlacement == false)
    }
}
