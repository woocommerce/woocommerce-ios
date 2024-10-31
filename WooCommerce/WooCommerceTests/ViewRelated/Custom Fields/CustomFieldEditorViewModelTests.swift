import XCTest
@testable import WooCommerce

final class CustomFieldEditorViewModelTests: XCTestCase {
    private var viewModel: CustomFieldEditorViewModel!
    private var savedKey: String?
    private var savedValue: String?
    private var deleteCallCount: Int = 0

    override func setUp() {
        super.setUp()
        savedKey = nil
        savedValue = nil
        deleteCallCount = 0
    }

    override func tearDown() {
        viewModel = nil
        super.tearDown()
    }

    // MARK: - Initial State Tests

    func test_given_initial_state_then_values_match_initial_input() {
        // Given
        let initialKey = "testKey"
        let initialValue = "testValue"

        // When
        viewModel = createViewModel(key: initialKey, value: initialValue)

        // Then
        XCTAssertEqual(viewModel.key, initialKey)
        XCTAssertEqual(viewModel.value, initialValue)
        XCTAssertNil(viewModel.keyErrorMessage)
        XCTAssertTrue(viewModel.hasValidKey)
        XCTAssertFalse(viewModel.hasUnsavedChanges)
    }

    // MARK: - Key Validation Tests

    func test_given_key_starting_with_underscore_then_show_error_message() {
        // Given
        viewModel = createViewModel(key: "key", value: "value")

        // When
        viewModel.key = "_invalidKey"

        // Then
        XCTAssertEqual(viewModel.keyErrorMessage, Expectations.keyErrorPrefix)
        XCTAssertFalse(viewModel.hasValidKey)
    }

    func test_given_key_similar_to_disallowed_key_then_show_error_message() {
        // Given
        let disallowedKeys = ["existingKey"]
        viewModel = createViewModel(key: "key", value: "value", disallowedKeys: disallowedKeys)

        // When
        viewModel.key = "existingKey"

        // Then
        XCTAssertEqual(viewModel.keyErrorMessage, Expectations.keyErrorDisallowedKey)
        XCTAssertFalse(viewModel.hasValidKey)
    }

    func test_given_empty_key_then_hasValidKey_is_false_but_show_no_error_message() {
        // Given
        viewModel = createViewModel(key: "key", value: "value")

        // When
        viewModel.key = ""

        // Then
        XCTAssertFalse(viewModel.hasValidKey)
        XCTAssertNil(viewModel.keyErrorMessage)
    }

    func test_given_valid_key_then_show_no_error_message() {
        // Given
        viewModel = createViewModel(key: "key", value: "value")

        // When
        viewModel.key = "validKey"

        // Then
        XCTAssertNil(viewModel.keyErrorMessage)
        XCTAssertTrue(viewModel.hasValidKey)
    }

    // MARK: - Value Changes Tests

    func test_given_value_change_then_hasUnsavedChanges_is_true() {
        // Given
        viewModel = createViewModel(key: "key", value: "value")

        // When
        viewModel.value = "newValue"

        // Then
        XCTAssertTrue(viewModel.hasUnsavedChanges)
    }

    // MARK: - Save Changes Tests

    func test_given_valid_changes_when_saveChanges_is_called_then_onSave_is_called() {
        // Given
        viewModel = createViewModel(key: "key", value: "value")
        viewModel.key = "newKey"
        viewModel.value = "newValue"

        // When
        viewModel.saveChanges()

        // Then
        XCTAssertEqual(savedKey, "newKey")
        XCTAssertEqual(savedValue, "newValue")
    }

    // MARK: - Delete Tests

    func test_given_delete_enabled_when_deleteField_is_called_then_onDelete_is_called() {
        // Given
        viewModel = createViewModel(key: "key", value: "value", onDelete: {
            self.deleteCallCount += 1
        })

        // When
        viewModel.deleteField()

        // Then
        XCTAssertEqual(deleteCallCount, 1)
    }

    func test_given_delete_disabled_when_deleteField_is_called_then_onDelete_is_not_called() {
        // Given
        viewModel = createViewModel(key: "key", value: "value", onDelete: nil)

        // When
        viewModel.deleteField()

        // Then
        XCTAssertEqual(deleteCallCount, 0)
    }
}

// MARK: - Helpers
private extension CustomFieldEditorViewModelTests {
    func createViewModel(
        key: String,
        value: String,
        disallowedKeys: [String] = [],
        onDelete: (() -> Void)? = nil
    ) -> CustomFieldEditorViewModel {
        CustomFieldEditorViewModel(
            customField: CustomFieldViewModel(key: key, value: value),
            disallowedKeys: disallowedKeys,
            onSave: { newKey, newValue in
                self.savedKey = newKey
                self.savedValue = newValue
            },
            onDelete: onDelete
        )
    }
}

// MARK: - Constants
private extension CustomFieldEditorViewModelTests {
    enum Expectations {
        static let keyErrorPrefix = NSLocalizedString(
            "customFieldEditorViewModelTests.keyErrorPrefix",
            value: "Invalid key: please remove the '_' character from the beginning.",
            comment: "Error message shown when key starts with underscore"
        )

        static let keyErrorDisallowedKey = NSLocalizedString(
            "customFieldEditorViewModelTests.keyErrorDisallowedKey",
            value: "Invalid key: This key is already used for another custom field. \n" +
            "The app currently does not support creating duplicate keys. Please use wp-admin to duplicate a key if needed.",
            comment: "Error message shown when the entered key is identical to an existing key."
        )
    }
}
