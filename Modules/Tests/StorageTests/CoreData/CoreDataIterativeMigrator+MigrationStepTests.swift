import XCTest
import TestKit
import CoreData

@testable import Storage

private typealias MigrationStep = CoreDataIterativeMigrator.MigrationStep
private typealias ModelVersion = ManagedObjectModelsInventory.ModelVersion

/// Test cases for `MigrationStep` functions.
final class CoreDataIterativeMigrator_MigrationStepTests: XCTestCase {

    private var modelsInventory: ManagedObjectModelsInventory!

    override func setUpWithError() throws {
        try super.setUpWithError()
        modelsInventory = try .from(packageName: "WooCommerce", bundle: .storage)
    }

    override func tearDown() {
        modelsInventory = nil
        super.tearDown()
    }

    func test_steps_returns_MigrationSteps_from_source_to_the_target_model() throws {
        // Given
        let modelVersion33 = ModelVersion(name: "Model 33")
        let modelVersion41 = ModelVersion(name: "Model 41")
        let sourceModel = try XCTUnwrap(modelsInventory.model(for: modelVersion33))
        let targetModel = try XCTUnwrap(modelsInventory.model(for: modelVersion41))

        // When
        let steps = try MigrationStep.steps(using: modelsInventory, source: sourceModel, target: targetModel)

        // Then
        // There should be 8 steps:
        //   - 33 to 34
        //   - 34 to 35
        //   - 35 to 36
        //   - 36 to 37
        //   - 37 to 38
        //   - 38 to 39
        //   - 39 to 40
        //   - 40 to 41
        XCTAssertEqual(steps.count, 8)

        // Assert the values of first and last steps.
        let modelVersion34 = ModelVersion(name: "Model 34")

        let expectedFirstStep = MigrationStep(sourceVersion: modelVersion33,
                                              sourceModel: try XCTUnwrap(modelsInventory.model(for: modelVersion33)),
                                              targetVersion: modelVersion34,
                                              targetModel: try XCTUnwrap(modelsInventory.model(for: modelVersion34)))
        let actualFirstStep = try XCTUnwrap(steps.first)
        XCTAssertEqual(actualFirstStep, expectedFirstStep)

        let modelVersion40 = ModelVersion(name: "Model 40")

        let expectedLastStep = MigrationStep(sourceVersion: modelVersion40,
                                              sourceModel: try XCTUnwrap(modelsInventory.model(for: modelVersion40)),
                                              targetVersion: modelVersion41,
                                              targetModel: try XCTUnwrap(modelsInventory.model(for: modelVersion41)))
        let actualLastStep = try XCTUnwrap(steps.last)
        XCTAssertEqual(actualLastStep, expectedLastStep)
    }

    func test_steps_returns_one_MigrationStep_if_the_source_and_target_are_next_to_each_other() throws {
        // Given
        let sourceVersion = ModelVersion(name: "Model 37")
        let sourceModel = try XCTUnwrap(modelsInventory.model(for: sourceVersion))

        let targetVersion = ModelVersion(name: "Model 38")
        let targetModel = try XCTUnwrap(modelsInventory.model(for: targetVersion))

        // When
        let steps = try MigrationStep.steps(using: modelsInventory, source: sourceModel, target: targetModel)

        // Then
        XCTAssertEqual(steps.count, 1)

        let expectedStep = MigrationStep(sourceVersion: sourceVersion,
                                         sourceModel: sourceModel,
                                         targetVersion: targetVersion,
                                         targetModel: targetModel)
        let actualStep = try XCTUnwrap(steps.first)
        XCTAssertEqual(actualStep, expectedStep)
    }

    func test_steps_returns_one_MigrationStep_if_source_is_second_to_last_version() throws {
        // Given
        let sourceVersion = modelsInventory.versions[modelsInventory.versions.endIndex - 2]
        let sourceModel = try XCTUnwrap(modelsInventory.model(for: sourceVersion))

        // When
        let steps = try MigrationStep.steps(using: modelsInventory,
                                            source: sourceModel,
                                            target: modelsInventory.currentModel)

        // Then
        XCTAssertEqual(steps.count, 1)

        let expectedStep = MigrationStep(sourceVersion: sourceVersion,
                                         sourceModel: sourceModel,
                                         targetVersion: try XCTUnwrap(modelsInventory.versions.last),
                                         targetModel: modelsInventory.currentModel)
        let actualStep = try XCTUnwrap(steps.first)
        XCTAssertEqual(actualStep, expectedStep)
    }

    func test_steps_returns_empty_if_the_source_is_an_unknown_model() throws {
        // Given
        let unknownModel = NSManagedObjectModel()

        // When
        let steps = try MigrationStep.steps(using: modelsInventory,
                                            source: unknownModel,
                                            target: modelsInventory.currentModel)

        // Then
        assertEmpty(steps)
    }

    func test_steps_returns_empty_if_the_source_is_the_current_model() throws {
        // Given
        let sourceModel = modelsInventory.currentModel
        let targetModel = modelsInventory.currentModel

        // When
        let steps = try MigrationStep.steps(using: modelsInventory, source: sourceModel, target: targetModel)

        // Then
        assertEmpty(steps)
    }
}
