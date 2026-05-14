import Testing
@testable import ParcelFittingCheck

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
}

// MARK: - Helpers

extension ARParcelFittingResultsViewModelTests.FitsCase: Sendable {}

private extension ARParcelFittingResultsViewModelTests {
    func makePackage(id: String = "pkg", length: Float, width: Float, height: Float) -> ParcelPresetPackage {
        ParcelPresetPackage(id: id, name: id, length: length, width: width, height: height)
    }
}
