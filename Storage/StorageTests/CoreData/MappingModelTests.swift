import XCTest
import TestKit
import CoreData

@testable import Storage

private typealias MigrationStep = CoreDataIterativeMigrator.MigrationStep

final class MappingModelTests: XCTestCase {
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
        let customMappingModelNames = (mainBundle.urls(forResourcesWithExtension: "cdm", subdirectory: nil) ?? []).map {
            $0.deletingPathExtension().lastPathComponent
        }
        // Confidence-check. We have custom mapping models so this should not be empty.
        assertNotEmpty(customMappingModelNames)

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

            let message = """
                Failed to find a \(expectedMappingModelName).xcmappingmodel file in \
                the bundle.

                This can mean that NSMappingModel() returned an incorrect \
                mapping model to use for migrating from \(step.sourceVersion.name) to
                \(step.targetVersion.name). There's probably something wrong with how we \
                configured the mapping or the model.

                If not that, the mapping model is probably not following the standard naming \
                pattern that we use for mapping model files.
                """
            XCTAssertTrue(customMappingModelNames.contains(expectedMappingModelName), message)
        }
    }
}

private extension MappingModelTests {
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
