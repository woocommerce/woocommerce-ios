import XCTest
@testable import WooCommerce

final class SupportFormViewModelTests: XCTestCase {

    func test_submit_button_is_disabled_when_subject_and_description_are_empty() {
        // Given
        let viewModel = SupportFormViewModel(areas: Self.sampleAreas())

        // When
        viewModel.subject = ""
        viewModel.description = ""

        // Then
        XCTAssertTrue(viewModel.submitButtonDisabled)
    }

    func test_submit_button_is_disabled_when_subject_is_not_empty_and_description_is_empty() {
        // Given
        let viewModel = SupportFormViewModel(areas: Self.sampleAreas())

        // When
        viewModel.subject = "Subject"
        viewModel.description = ""

        // Then
        XCTAssertTrue(viewModel.submitButtonDisabled)
    }

    func test_submit_button_is_disabled_when_subject_is_empty_and_description_is_not_empty() {
        // Given
        let viewModel = SupportFormViewModel(areas: Self.sampleAreas())

        // When
        viewModel.subject = ""
        viewModel.description = "Description"

        // Then
        XCTAssertTrue(viewModel.submitButtonDisabled)
    }

    func test_submit_button_is_enabled_when_subject_is_and_description_are_not_empty() {
        // Given
        let viewModel = SupportFormViewModel(areas: Self.sampleAreas())

        // When
        viewModel.subject = "Subject"
        viewModel.description = "Description"

        // Then
        XCTAssertFalse(viewModel.submitButtonDisabled)
    }
}

private extension SupportFormViewModelTests {
    private struct MockDataSource: SupportFormMetaDataSource {
        let formID: Int64 = 0
        let tags: [String] = []
        let customFields: [Int64: String] = [:]
    }

    static func sampleAreas() -> [SupportFormViewModel.Area] {
        [
            .init(title: "Area 1", datasource: MockDataSource()),
            .init(title: "Area 2", datasource: MockDataSource())
        ]
    }
}
