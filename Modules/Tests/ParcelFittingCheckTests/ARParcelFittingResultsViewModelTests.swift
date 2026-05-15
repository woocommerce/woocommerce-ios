import Testing
import EventHorizonSDK
@testable @preconcurrency import ParcelFittingCheck

@Suite("ARParcelFittingResultsViewModel")
struct ARParcelFittingResultsViewModelTests {

    // MARK: - fits(measured:into:)

    struct FitsCase: CustomTestStringConvertible {
        let measured: ParcelDimensions
        let package: ParcelPresetPackage
        let expected: Bool
        let testDescription: String

        var id: String { testDescription }
    }

    static let fitsCases: [FitsCase] = [
        FitsCase(
            measured: ParcelDimensions(length: 5, width: 4, height: 3),
            package: ParcelPresetPackage(id: "p", name: "p", length: 10, width: 8, height: 6),
            expected: true,
            testDescription: "package larger in all dimensions"
        ),
        FitsCase(
            measured: ParcelDimensions(length: 3, width: 7, height: 5),
            package: ParcelPresetPackage(id: "p", name: "p", length: 10, width: 4, height: 6),
            expected: true,
            testDescription: "dimensions shuffled but still fits"
        ),
        FitsCase(
            measured: ParcelDimensions(length: 5, width: 4, height: 3),
            package: ParcelPresetPackage(id: "p", name: "p", length: 10, width: 8, height: 2),
            expected: false,
            testDescription: "one dimension too small"
        ),
    ]

    @Test(arguments: fitsCases)
    func test_fits(_ testCase: FitsCase) {
        let result = ARParcelFittingResultsViewModel.fits(measured: testCase.measured, into: testCase.package)
        #expect(result == testCase.expected)
    }

    // MARK: - smallestFitting(in:for:)

    @Test func test_smallestFitting_when_multiple_fit_then_returns_minimum_volume() {
        let measured = ParcelDimensions(length: 4, width: 3, height: 2)
        let small = makePackage(id: "small", length: 5, width: 4, height: 3)
        let large = makePackage(id: "large", length: 10, width: 8, height: 6)

        let result = ARParcelFittingResultsViewModel.smallestFitting(in: [large, small], for: measured)

        #expect(result?.id == "small")
    }

    @Test func test_smallestFitting_when_nothing_fits_then_returns_nil() {
        let measured = ParcelDimensions(length: 20, width: 20, height: 20)

        let result = ARParcelFittingResultsViewModel.smallestFitting(in: [makePackage(id: "tiny", length: 5, width: 5, height: 5)], for: measured)

        #expect(result == nil)
    }

    // MARK: - init

    @Test func test_init_carrierResults_one_per_carrier_sorted_by_volume() {
        let measured = ParcelDimensions(length: 4, width: 3, height: 2)
        let carrierA = ParcelPresetCarrier(id: "a", name: "A", packages: [makePackage(id: "big", length: 10, width: 8, height: 6)])
        let carrierB = ParcelPresetCarrier(id: "b", name: "B", packages: [makePackage(id: "small", length: 5, width: 4, height: 3)])
        let carrierC = ParcelPresetCarrier(id: "c", name: "C", packages: [makePackage(id: "tiny", length: 1, width: 1, height: 1)])

        let vm = ARParcelFittingResultsViewModel(measuredDimensions: measured, unit: .centimeters, carriers: [carrierA, carrierB, carrierC])

        #expect(vm.carrierResults.count == 2)
        #expect(vm.carrierResults[0].package.id == "small")
        #expect(vm.carrierResults[1].package.id == "big")
    }

    // MARK: - trackResultsDisplayed

    @Test func test_trackResultsDisplayed_when_called_then_tracks_with_counts() {
        // Given
        let analytics = MockParcelFittingAnalytics()
        let vm = makeSUT(carriers: [
            ParcelPresetCarrier(id: "a", name: "A", packages: [makePackage(id: "fit", length: 30, width: 20, height: 15)]),
            ParcelPresetCarrier(id: "b", name: "B", packages: [makePackage(id: "nofit", length: 1, width: 1, height: 1)]),
        ], analytics: analytics)

        // When
        vm.trackResultsDisplayed()

        // Then
        let event = try #require(analytics.lastEvent)
        #expect(event.hasProperty("action", value: "arfitting_results_displayed"))
        #expect(event.hasProperty("carrier_match_count", value: "1"))
        #expect(event.hasProperty("total_carrier_count", value: "2"))
    }

    // MARK: - trackCarrierPackageSelected

    @Test func test_trackCarrierPackageSelected_when_called_then_tracks_with_index_and_starred() {
        // Given
        let analytics = MockParcelFittingAnalytics()
        let vm = makeSUT(analytics: analytics)

        // When
        vm.trackCarrierPackageSelected(index: 2, isStarred: true)

        // Then
        let event = try #require(analytics.lastEvent)
        #expect(event.hasProperty("action", value: "arfitting_carrier_package_selected"))
        #expect(event.hasProperty("index", value: "2"))
        #expect(event.hasProperty("is_starred", value: "true"))
    }

    // MARK: - trackCustomDimensionsSelected

    @Test func test_trackCustomDimensionsSelected_when_called_then_tracks_event() {
        // Given
        let analytics = MockParcelFittingAnalytics()
        let vm = makeSUT(analytics: analytics)

        // When
        vm.trackCustomDimensionsSelected()

        // Then
        let event = try #require(analytics.lastEvent)
        #expect(event.hasProperty("action", value: "arfitting_custom_dimensions_selected"))
    }

    // MARK: - trackSelectPackageTapped

    @Test func test_trackSelectPackageTapped_when_carrier_then_tracks_carrier_type() {
        // Given
        let analytics = MockParcelFittingAnalytics()
        let vm = makeSUT(analytics: analytics)

        // When
        vm.trackSelectPackageTapped(selectionType: .carrier)

        // Then
        let event = try #require(analytics.lastEvent)
        #expect(event.hasProperty("action", value: "arfitting_select_package_tapped"))
        #expect(event.hasProperty("selection_type", value: "carrier"))
    }

    @Test func test_trackSelectPackageTapped_when_custom_then_tracks_custom_type() {
        // Given
        let analytics = MockParcelFittingAnalytics()
        let vm = makeSUT(analytics: analytics)

        // When
        vm.trackSelectPackageTapped(selectionType: .custom)

        // Then
        let event = try #require(analytics.lastEvent)
        #expect(event.hasProperty("selection_type", value: "custom"))
    }

    // MARK: - trackBrowseAllPackagesTapped

    @Test func test_trackBrowseAllPackagesTapped_when_called_then_tracks_event() {
        // Given
        let analytics = MockParcelFittingAnalytics()
        let vm = makeSUT(analytics: analytics)

        // When
        vm.trackBrowseAllPackagesTapped()

        // Then
        let event = try #require(analytics.lastEvent)
        #expect(event.hasProperty("action", value: "arfitting_browse_all_packages_tapped"))
    }

    // MARK: - trackPackageStarTapped

    @Test func test_trackPackageStarTapped_when_starring_then_tracks_with_isStarred_true() {
        // Given
        let analytics = MockParcelFittingAnalytics()
        let vm = makeSUT(analytics: analytics)

        // When
        vm.trackPackageStarTapped(index: 0, isStarred: true)

        // Then
        let event = try #require(analytics.lastEvent)
        #expect(event.hasProperty("action", value: "arfitting_package_star_tapped"))
        #expect(event.hasProperty("index", value: "0"))
        #expect(event.hasProperty("is_starred", value: "true"))
    }

    @Test func test_trackPackageStarTapped_when_unstarring_then_tracks_with_isStarred_false() {
        // Given
        let analytics = MockParcelFittingAnalytics()
        let vm = makeSUT(analytics: analytics)

        // When
        vm.trackPackageStarTapped(index: 1, isStarred: false)

        // Then
        let event = try #require(analytics.lastEvent)
        #expect(event.hasProperty("is_starred", value: "false"))
    }
}

// MARK: - Helpers

extension ARParcelFittingResultsViewModelTests.FitsCase: Sendable {}

private extension ARParcelFittingResultsViewModelTests {
    func makePackage(id: String = "pkg", length: Float, width: Float, height: Float) -> ParcelPresetPackage {
        ParcelPresetPackage(id: id, name: id, length: length, width: width, height: height)
    }

    func makeSUT(carriers: [ParcelPresetCarrier] = [],
                 analytics: ParcelFittingAnalyticsTracking = MockParcelFittingAnalytics()) -> ARParcelFittingResultsViewModel {
        ARParcelFittingResultsViewModel(
            measuredDimensions: ParcelDimensions(length: 20, width: 15, height: 10),
            unit: .centimeters,
            carriers: carriers,
            analytics: analytics
        )
    }
}
