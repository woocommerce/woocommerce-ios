
import Foundation
import XCTest
import class CoreData.NSManagedObjectModel

@testable import Storage

private typealias ModelVersion = ManagedObjectModelsInventory.ModelVersion
private typealias IntrospectionError = ManagedObjectModelsInventory.IntrospectionError

/// Test cases for `ManagedObjectModelsInventory`.
///
final class ManagedObjectModelsInventoryTests: XCTestCase {

    private let bundle = Bundle(for: CoreDataManager.self)
    private let packageName = "WooCommerce"

    func test_it_loads_the_momd_using_the_given_packageName() throws {
        // Given
        let inventory = try ManagedObjectModelsInventory.from(packageName: packageName, bundle: bundle)

        // When
        let packageURL = inventory.packageURL

        // Then
        XCTAssertEqual(packageURL.lastPathComponent, "\(packageName).momd")
    }

    func test_it_can_load_the_expected_model_versions() throws {
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
            "Model 29",
            "Model 30",
            "Model 31",
            "Model 32",
            "Model 33",
            "Model 34",
            "Model 35",
            "Model 36",
            "Model 37",
            "Model 38",
            "Model 39",
            "Model 40",
            "Model 41",
            "Model 42",
            "Model 43",
            "Model 44",
            "Model 45",
            "Model 46",
            "Model 47",
            "Model 48",
            "Model 49",
            "Model 50",
            "Model 51",
            "Model 52",
            "Model 53",
            "Model 54",
            "Model 55",
            "Model 56",
            "Model 57",
            "Model 58",
            "Model 59",
            "Model 60",
            "Model 61",
            "Model 62",
            "Model 63",
            "Model 64",
            "Model 65",
            "Model 66",
            "Model 67",
            "Model 68",
            "Model 69",
            "Model 70",
            "Model 71",
            "Model 72",
            "Model 73",
            "Model 74",
            "Model 75",
            "Model 76",
            "Model 77",
            "Model 78",
            "Model 79",
            "Model 80",
            "Model 81",
            "Model 82",
            "Model 83",
            "Model 84",
            "Model 85",
            "Model 86",
            "Model 87",
            "Model 88",
            "Model 89",
            "Model 90",
            "Model 91",
            "Model 92",
            "Model 93",
            "Model 94",
            "Model 95",
            "Model 96",
            "Model 97",
            "Model 98",
            "Model 99",
            "Model 100",
            "Model 101",
            "Model 102",
            "Model 103",
            "Model 104",
            "Model 105",
            "Model 106",
            "Model 107",
            "Model 108",
            "Model 109",
            "Model 110",
            "Model 111",
            "Model 112",
            "Model 113"
        ]

        // When
        let inventory = try ManagedObjectModelsInventory.from(packageName: packageName, bundle: bundle)

        let modelVersionNames = inventory.versions.map { $0.name }

        // Then
        // We'll cut the version names up to the length of `expectedVersionNames` so that this
        // test will still pass even if new model versions are added. This is just for
        // maintainability.
        let truncatedModelVersionNames = Array(modelVersionNames[..<expectedVersionNames.count])

        XCTAssertEqual(truncatedModelVersionNames, expectedVersionNames)
    }

    /// Tests that the model versions are sorted according to our convention of incrementing
    /// the number names.
    func test_it_sorts_the_models_using_the_convention() throws {
        // Given
        let modelVersions = [
            ModelVersion(name: "Model 301"),
            ModelVersion(name: "Model 311"),
            ModelVersion(name: "Model 3"),
            ModelVersion(name: "Model 1"),
            ModelVersion(name: "Model"),
            ModelVersion(name: "Model 4"),
            ModelVersion(name: "Model 5"),
            ModelVersion(name: "Model 7"),
            ModelVersion(name: "Model 65"),
            ModelVersion(name: "Model 13"),
            ModelVersion(name: "Model 130"),
            ModelVersion(name: "Model 10"),
        ]

        // When
        let dummyURL = try XCTUnwrap(URL(string: "https://example.com"))
        let dummyMOM = NSManagedObjectModel()
        let sortedModelVersions = ManagedObjectModelsInventory(packageURL: dummyURL,
                                                               currentModel: dummyMOM,
                                                               versions: modelVersions).versions

        // Then
        let expectedSortedNames = [
            "Model",
            "Model 1",
            "Model 3",
            "Model 4",
            "Model 5",
            "Model 7",
            "Model 10",
            "Model 13",
            "Model 65",
            "Model 130",
            "Model 301",
            "Model 311",
        ]
        XCTAssertEqual(sortedModelVersions.map { $0.name }, expectedSortedNames)
    }

    func test_it_throws_an_error_if_the_packageName_does_not_point_to_an_momd_directory() {
        // Given
        let packageName = "InvalidPackageName"

        // When-Then
        XCTAssertThrowsError(try ManagedObjectModelsInventory.from(packageName: packageName, bundle: bundle)) { error in
            XCTAssertEqual(error as? IntrospectionError, IntrospectionError.cannotFindMomd)
        }
    }

    func test_it_can_load_the_current_ManagedObjectModel() throws {
        // Given
        let inventory = try ManagedObjectModelsInventory.from(packageName: packageName, bundle: bundle)

        // By our convention, the version with the highest number should have been configured
        // as the current version. For example, if we have 35 model versions inside
        // `WooCommerce.xcdatamodeld` then there should be a model version named "Model 35" and
        // that should be the configured "current" model version.
        let expectedModelVersionName = try XCTUnwrap(inventory.versions.last?.name)
        let expectedCurrentModel: NSManagedObjectModel = try {
            let urlOfLastVersion = try XCTUnwrap(bundle.url(forResource: expectedModelVersionName,
                                                            withExtension: "mom",
                                                            subdirectory: inventory.packageURL.lastPathComponent))
            return try XCTUnwrap(NSManagedObjectModel(contentsOf: urlOfLastVersion))
        }()

        // When
        let actualCurrentModel = inventory.currentModel

        // Then
        XCTAssertEqual(actualCurrentModel, expectedCurrentModel,
                       "The configured model version should be “\(expectedModelVersionName)”.")
    }
}
