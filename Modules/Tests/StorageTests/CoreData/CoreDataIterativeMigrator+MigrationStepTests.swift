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
        let modelVersion83 = ModelVersion(name: "Model 83")
        let modelVersion91 = ModelVersion(name: "Model 91")
        let sourceModel = try XCTUnwrap(modelsInventory.model(for: modelVersion83))
        let targetModel = try XCTUnwrap(modelsInventory.model(for: modelVersion91))

        // When
        let steps = try MigrationStep.steps(using: modelsInventory, source: sourceModel, target: targetModel)

        // Then
        // There should be 8 steps:
        //   - 83 to 84
        //   - 84 to 85
        //   - 85 to 86
        //   - 86 to 87
        //   - 87 to 88
        //   - 88 to 89
        //   - 89 to 90
        //   - 90 to 91
        XCTAssertEqual(steps.count, 8)

        // Assert the values of first and last steps.
        let modelVersion84 = ModelVersion(name: "Model 84")

        let expectedFirstStep = MigrationStep(sourceVersion: modelVersion83,
                                              sourceModel: try XCTUnwrap(modelsInventory.model(for: modelVersion83)),
                                              targetVersion: modelVersion84,
                                              targetModel: try XCTUnwrap(modelsInventory.model(for: modelVersion84)))
        let actualFirstStep = try XCTUnwrap(steps.first)
        XCTAssertEqual(actualFirstStep, expectedFirstStep)

        let modelVersion90 = ModelVersion(name: "Model 90")

        let expectedLastStep = MigrationStep(sourceVersion: modelVersion90,
                                              sourceModel: try XCTUnwrap(modelsInventory.model(for: modelVersion90)),
                                              targetVersion: modelVersion91,
                                              targetModel: try XCTUnwrap(modelsInventory.model(for: modelVersion91)))
        let actualLastStep = try XCTUnwrap(steps.last)
        XCTAssertEqual(actualLastStep, expectedLastStep)
    }

    func test_steps_returns_one_MigrationStep_if_the_source_and_target_are_next_to_each_other() throws {
        // Given
        let sourceVersion = ModelVersion(name: "Model 87")
        let sourceModel = try XCTUnwrap(modelsInventory.model(for: sourceVersion))

        let targetVersion = ModelVersion(name: "Model 88")
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
        let sourceModelName = "Model 87"
        let modelVersion37 = ModelVersion(name: sourceModelName)
        let sourceModel = try XCTUnwrap(modelsInventory.model(for: modelVersion37))

        // Find the index of Model 87 in the current inventory
        // which only contains Models 80-127 as per latest update on [https://github.com/woocommerce/woocommerce-ios/pull/16181]
        let sourceModelIndex = try XCTUnwrap(modelsInventory.versions.firstIndex { $0.name == sourceModelName },
                                             "Model 87 should exist in the inventory")
        // When
        let steps = try MigrationStep.steps(using: modelsInventory, source: sourceModel, target: sourceModel)

        // Then
        // Expected behavior (bug): When source == target, it returns steps from that model to the latest version
        // This means: Model 87 → Model 88 → ... → Model 127
        // Calculation: total versions - source index - 1 (since we don't include the source model itself)
        let expectedStepCount = modelsInventory.versions.count - sourceModelIndex - 1
        XCTAssertEqual(steps.count, expectedStepCount,
                       "Should return steps from Model 87 to the latest model (Model 127)")
    }
}
