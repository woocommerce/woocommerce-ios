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
        modelsInventory = try .from(packageName: "WooCommerce", bundle: Bundle(for: CoreDataManager.self))
    }

    override func tearDown() {
        modelsInventory = nil
        super.tearDown()
    }

    func test_steps_returns_MigrationSteps_from_source_to_the_target_model() throws {
        // Given
        let modelVersion23 = ModelVersion(name: "Model 23")
        let modelVersion31 = ModelVersion(name: "Model 31")
        let sourceModel = try XCTUnwrap(modelsInventory.model(for: modelVersion23))
        let targetModel = try XCTUnwrap(modelsInventory.model(for: modelVersion31))

        // When
        let steps = try MigrationStep.steps(using: modelsInventory, source: sourceModel, target: targetModel)

        // Then
        // There should be 8 steps:
        //   - 23 to 24
        //   - 24 to 25
        //   - 25 to 26
        //   - 26 to 27
        //   - 27 to 28
        //   - 28 to 29
        //   - 29 to 30
        //   - 30 to 31
        XCTAssertEqual(steps.count, 8)

        // Assert the values of first and last steps.
        let modelVersion24 = ModelVersion(name: "Model 24")

        let expectedFirstStep = MigrationStep(sourceVersion: modelVersion23,
                                              sourceModel: try XCTUnwrap(modelsInventory.model(for: modelVersion23)),
                                              targetVersion: modelVersion24,
                                              targetModel: try XCTUnwrap(modelsInventory.model(for: modelVersion24)))
        let actualFirstStep = try XCTUnwrap(steps.first)
        XCTAssertEqual(actualFirstStep, expectedFirstStep)

        let modelVersion30 = ModelVersion(name: "Model 30")

        let expectedLastStep = MigrationStep(sourceVersion: modelVersion30,
                                              sourceModel: try XCTUnwrap(modelsInventory.model(for: modelVersion30)),
                                              targetVersion: modelVersion31,
                                              targetModel: try XCTUnwrap(modelsInventory.model(for: modelVersion31)))
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

    /// If the `source` and `target` are the same models, `steps()` will return steps from **that**
    /// model version up to the latest version in the inventory.
    ///
    /// This seems like a bug in the `steps()` loop that has existed for a long time. I would have
    /// expected that 0 steps are returned. I'm just keeping it as is for now. We don't
    /// reach this condition because of the precondition checks in `CoreDataIterativeMigrator`.
    func test_steps_returns_source_to_latest_version_MigrationSteps_if_the_source_and_target_are_the_same() throws {
        // Given
        let modelVersion37 = ModelVersion(name: "Model 37")
        let sourceModel = try XCTUnwrap(modelsInventory.model(for: modelVersion37))

        // When
        let steps = try MigrationStep.steps(using: modelsInventory, source: sourceModel, target: sourceModel)

        // Then
        XCTAssertEqual(steps.count, modelsInventory.versions.count - 37)
    }
}
