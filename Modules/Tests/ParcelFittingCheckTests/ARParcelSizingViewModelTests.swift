import Testing
import EventHorizonSDK
@testable import ParcelFittingCheck

@Suite("ARParcelSizingViewModel")
struct ARParcelSizingViewModelTests {

    // MARK: - recordGestureCompleted

    @Test func test_recordGestureCompleted_when_resize_then_increments_resizeCount() {
        // Given
        let sut = makeSUT()

        // When
        sut.recordGestureCompleted(mode: .resize)
        sut.recordGestureCompleted(mode: .resize)

        // Then
        #expect(sut.resizeCount == 2)
        #expect(sut.rotateCount == 0)
    }

    @Test func test_recordGestureCompleted_when_rotate_then_increments_rotateCount() {
        // Given
        let sut = makeSUT()

        // When
        sut.recordGestureCompleted(mode: .rotate)

        // Then
        #expect(sut.rotateCount == 1)
        #expect(sut.resizeCount == 0)
    }

    @Test func test_recordGestureCompleted_when_undecided_then_does_not_increment() {
        // Given
        let sut = makeSUT()

        // When
        sut.recordGestureCompleted(mode: .undecided)

        // Then
        #expect(sut.resizeCount == 0)
        #expect(sut.rotateCount == 0)
    }

    // MARK: - recordReset

    @Test func test_recordReset_increments_resetCount() {
        // Given
        let sut = makeSUT()

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
        let sut = makeSUT()
        #expect(sut.arReadyTime == nil)

        // When
        sut.recordARReady()

        // Then
        #expect(sut.arReadyTime != nil)
    }

    @Test func test_recordARReady_when_called_twice_then_keeps_first_time() {
        // Given
        let sut = makeSUT()
        sut.recordARReady()
        let firstTime = sut.arReadyTime

        // When
        sut.recordARReady()

        // Then
        #expect(sut.arReadyTime == firstTime)
    }

    // MARK: - trackBoxPlaced

    @Test func test_trackBoxPlaced_when_called_then_tracks_arfittingBoxPlaced() {
        // Given
        let analytics = MockParcelFittingAnalytics()
        let sut = makeSUT(analytics: analytics)
        sut.recordARReady()

        // When
        sut.trackBoxPlaced()

        // Then
        #expect(analytics.lastTrackedEventName == "wcs_ar_parcel_fitting")
        let props = analytics.trackedEvents.last?.properties
        #expect(props?["action"] == "arfitting_box_placed")
    }

    @Test func test_trackBoxPlaced_when_called_twice_then_tracks_only_once() {
        // Given
        let analytics = MockParcelFittingAnalytics()
        let sut = makeSUT(analytics: analytics)
        sut.recordARReady()

        // When
        sut.trackBoxPlaced()
        sut.trackBoxPlaced()

        // Then
        #expect(analytics.trackedEvents.count == 1)
    }

    // MARK: - trackSizingCompleted

    @Test func test_trackSizingCompleted_when_called_then_tracks_with_dimensions_and_counts() {
        // Given
        let analytics = MockParcelFittingAnalytics()
        let sut = makeSUT(unit: .centimeters, analytics: analytics)
        sut.dimensions = ParcelDimensions(length: 20, width: 15, height: 10)
        sut.recordGestureCompleted(mode: .resize)
        sut.recordGestureCompleted(mode: .rotate)
        sut.recordReset()

        // When
        sut.trackSizingCompleted()

        // Then
        let props = analytics.trackedEvents.last?.properties
        #expect(props?["action"] == "arfitting_sizing_completed")
        #expect(props?["length_cm"] == "20")
        #expect(props?["width_cm"] == "15")
        #expect(props?["height_cm"] == "10")
        #expect(props?["resize_count"] == "1")
        #expect(props?["rotate_count"] == "1")
        #expect(props?["reset_count"] == "1")
    }

    @Test func test_trackSizingCompleted_when_inches_then_converts_to_centimeters() {
        // Given
        let analytics = MockParcelFittingAnalytics()
        let sut = makeSUT(unit: .inches, analytics: analytics)
        sut.dimensions = ParcelDimensions(length: 10, width: 8, height: 5)

        // When
        sut.trackSizingCompleted()

        // Then
        let props = analytics.trackedEvents.last?.properties
        #expect(props?["length_cm"] == "25")
        #expect(props?["width_cm"] == "20")
        #expect(props?["height_cm"] == "13")
    }

    // MARK: - trackSizingCanceled

    @Test func test_trackSizingCanceled_when_called_then_tracks_with_state_and_counts() {
        // Given
        let analytics = MockParcelFittingAnalytics()
        let sut = makeSUT(analytics: analytics)
        sut.recordGestureCompleted(mode: .resize)
        sut.recordGestureCompleted(mode: .resize)

        // When
        sut.trackSizingCanceled(hadPlacedBox: true, arReady: true)

        // Then
        let props = analytics.trackedEvents.last?.properties
        #expect(props?["action"] == "arfitting_sizing_canceled")
        #expect(props?["had_placed_box"] == "true")
        #expect(props?["ar_ready"] == "true")
        #expect(props?["resize_count"] == "2")
        #expect(props?["rotate_count"] == "0")
        #expect(props?["reset_count"] == "0")
    }
}

private extension ARParcelSizingViewModelTests {
    func makeSUT(unit: UnitLength = .centimeters,
                 analytics: ParcelFittingAnalyticsTracking = MockParcelFittingAnalytics()) -> ARParcelSizingViewModel {
        ARParcelSizingViewModel(unit: unit, analytics: analytics)
    }
}
