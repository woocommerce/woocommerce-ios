import XCTest
import TestKit
import CoreData

@testable import Storage

private typealias MigrationStep = CoreDataIterativeMigrator.MigrationStep

final class MappingModelTests: XCTestCase {

    private let mappingModelNamePattern = #"^WooCommerceModelV(?<source>\d+)toV(?<target>\d+)$"#

    private var modelsInventory: ManagedObjectModelsInventory!
    private var mainBundle: Bundle!

    override func setUpWithError() throws {
        try super.setUpWithError()
        mainBundle = Bundle(for: CoreDataManager.self)
        modelsInventory = try .from(packageName: "WooCommerce", bundle: mainBundle)
    }

    override func tearDown() {
        modelsInventory = nil
        mainBundle = nil
        super.tearDown()
    }

    func test_NSMappingModel_returns_the_appropriate_custom_mapping_models() throws {
        // Given
        let mappingModelNames = self.mappingModelNames()
        // Confidence-check. We have custom mapping models so this should not be empty.
        assertNotEmpty(mappingModelNames)

        let steps: [MigrationStep] = try {
            let firstModel = try XCTUnwrap(modelsInventory.model(for: try XCTUnwrap(modelsInventory.versions.first)))
            return try MigrationStep.steps(using: modelsInventory,
                                           source: firstModel,
                                           target: modelsInventory.currentModel)
        }()
        assertNotEmpty(steps)

        // When and Then
        steps.forEach { step in
            let expectedMappingModelName = self.expectedMappingModelName(step: step)

            guard NSMappingModel(from: [mainBundle],
                                 forSourceModel: step.sourceModel,
                                 destinationModel: step.targetModel) != nil else {
                return
            }

            let failureMessage = """
                Failed to find a \(expectedMappingModelName).xcmappingmodel file in \
                the bundle.

                This can mean that NSMappingModel() returned an incorrect \
                mapping model to use for migrating from \(step.sourceVersion.name) to
                \(step.targetVersion.name). There's probably something wrong with how we \
                configured the mapping or the model.

                If not that, the mapping model is probably not following the standard naming \
                pattern that we use for mapping model files.
                """
            XCTAssertTrue(mappingModelNames.contains(expectedMappingModelName), failureMessage)
        }
    }

    func test_all_mapping_model_files_follow_the_standard_naming_pattern() {
        // Given
        let mappingModelNames = self.mappingModelNames()

        mappingModelNames.forEach { name in
            // When
            let range = name.range(of: mappingModelNamePattern, options: .regularExpression)

            // Then
            XCTAssertNotNil(range)
        }
    }
}

private extension MappingModelTests {

    /// Returns all the mapping model file names (excluding extensions) from the bundle.
    func mappingModelNames() -> [String] {
        // The mapping models (.xcmappingmodel) have the "cdm" file extension when they are compiled.
        (mainBundle.urls(forResourcesWithExtension: "cdm", subdirectory: nil) ?? []).map {
            $0.deletingPathExtension().lastPathComponent
        }
    }

    /// Return the expected file name of the mapping model for the given migration step.
    ///
    /// If the step is for migrating from "Model 40" to "Model 41", we expected the mapping model
    /// to be named "WooCommerceModelV40to41".
    ///
    func expectedMappingModelName(step: MigrationStep) -> String {
        "WooCommerceModelV\(step.sourceVersion.versionNumber)toV\(step.targetVersion.versionNumber)"
    }
}

private extension ManagedObjectModelsInventory.ModelVersion {
    /// Return the number part of the models name. For example, if the name is "Model 41", this
    /// will return "41".
    var versionNumber: String {
        name.dropFirst("Model ".count).description
    }
}
