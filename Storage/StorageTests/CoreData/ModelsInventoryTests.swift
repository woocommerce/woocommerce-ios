
import Foundation
import XCTest

@testable import Storage

/// Test cases for `ModelsInventory`.
///
final class ModelsInventoryTests: XCTestCase {

    private let bundle = Bundle(for: CoreDataManager.self)
    private let packageName = "WooCommerce"

    func testItCanLoadTheExpectedModelVersions() throws {
        // Given
        let expectedVersionNames = [
            "Model",
            "Model 2",
            "Model 3",
            "Model 4",
            "Model 5",
            "Model 6",
            "Model 7",
            "Model 8",
            "Model 9",
            "Model 10",
            "Model 11",
            "Model 12",
            "Model 13",
            "Model 14",
            "Model 15",
            "Model 16",
            "Model 17",
            "Model 18",
            "Model 19",
            "Model 20",
            "Model 21",
            "Model 22",
            "Model 23",
            "Model 24",
            "Model 25",
            "Model 26",
            "Model 27",
            "Model 28",
        ]

        // When
        let inventory = try ModelsInventory.from(packageName: packageName, bundle: bundle)

        let modelVersionNames = inventory.modelVersions.map(\.name)

        // Then
        // We'll cut the version names up to the length of `expectedVersionNames` so that this
        // test will still pass even if new model versions are added. This is just for
        // maintainability.
        let truncatedModelVersionNames = Array(modelVersionNames[..<expectedVersionNames.count])

        XCTAssertEqual(truncatedModelVersionNames, expectedVersionNames)
    }
}
