import Testing
@testable import ParcelFittingCheck

@Suite("ARParcelFittingResultsViewModel")
struct ARParcelFittingResultsViewModelTests {

    // MARK: - fits(measured:into:)

    @Test func test_fits_when_package_is_larger_in_all_dimensions_then_returns_true() {
        // Given
        let measured = ParcelDimensions(length: 5, width: 4, height: 3)
        let package = makePackage(length: 10, width: 8, height: 6)

        // When
        let result = ARParcelFittingResultsViewModel.fits(measured: measured, into: package)

        // Then
        #expect(result == true)
    }

    @Test func test_fits_when_dimensions_are_shuffled_then_returns_true() {
        // Given — measured has its largest dim in width, package in length; should still fit
        let measured = ParcelDimensions(length: 3, width: 7, height: 5)
        let package = makePackage(length: 10, width: 4, height: 6)

        // When
        let result = ARParcelFittingResultsViewModel.fits(measured: measured, into: package)

        // Then — sorted descending: measured [7,5,3], package [10,6,4] — each p >= m
        #expect(result == true)
    }

    @Test func test_fits_when_one_dimension_is_too_small_then_returns_false() {
        // Given
        let measured = ParcelDimensions(length: 5, width: 4, height: 3)
        let package = makePackage(length: 10, width: 8, height: 2)

        // When
        let result = ARParcelFittingResultsViewModel.fits(measured: measured, into: package)

        // Then — sorted: measured [5,4,3], package [10,8,2]; p[2]=2 < m[2]=3
        #expect(result == false)
    }

    // MARK: - smallestFitting(in:for:)

    @Test func test_smallestFitting_when_multiple_packages_fit_then_returns_minimum_volume_package() {
        // Given
        let measured = ParcelDimensions(length: 4, width: 3, height: 2)
        let small = makePackage(id: "small", length: 5, width: 4, height: 3)   // volume 60
        let large = makePackage(id: "large", length: 10, width: 8, height: 6)  // volume 480

        // When
        let result = ARParcelFittingResultsViewModel.smallestFitting(in: [large, small], for: measured)

        // Then
        #expect(result?.id == "small")
    }

    @Test func test_smallestFitting_when_nothing_fits_then_returns_nil() {
        // Given
        let measured = ParcelDimensions(length: 20, width: 20, height: 20)
        let tooSmall = makePackage(id: "tiny", length: 5, width: 5, height: 5)

        // When
        let result = ARParcelFittingResultsViewModel.smallestFitting(in: [tooSmall], for: measured)

        // Then
        #expect(result == nil)
    }

    // MARK: - init

    @Test func test_init_when_multiple_carriers_provided_then_carrierResults_contains_one_result_per_fitting_carrier_sorted_by_volume() {
        // Given
        let measured = ParcelDimensions(length: 4, width: 3, height: 2)

        let largePackage = makePackage(id: "big", length: 10, width: 8, height: 6)    // volume 480
        let smallPackage = makePackage(id: "small", length: 5, width: 4, height: 3)   // volume 60

        let carrierA = ParcelPresetCarrier(id: "carrierA", name: "Carrier A", packages: [largePackage])
        let carrierB = ParcelPresetCarrier(id: "carrierB", name: "Carrier B", packages: [smallPackage])
        let carrierC = ParcelPresetCarrier(id: "carrierC", name: "Carrier C", packages: [makePackage(id: "tiny", length: 1, width: 1, height: 1)])

        // When
        let viewModel = ARParcelFittingResultsViewModel(
            measuredDimensions: measured,
            unit: .centimeters,
            carriers: [carrierA, carrierB, carrierC]
        )

        // Then — carrierC has no fitting package, so only two results; sorted by volume ascending
        #expect(viewModel.carrierResults.count == 2)
        #expect(viewModel.carrierResults[0].package.id == "small")
        #expect(viewModel.carrierResults[1].package.id == "big")
    }
}

// MARK: - Helpers

private extension ARParcelFittingResultsViewModelTests {
    func makePackage(id: String = "pkg", length: Float, width: Float, height: Float) -> ParcelPresetPackage {
        ParcelPresetPackage(id: id, name: id, length: length, width: width, height: height)
    }
}
