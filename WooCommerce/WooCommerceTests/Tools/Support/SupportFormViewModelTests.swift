import XCTest
@testable import WooCommerce

@MainActor
final class SupportFormViewModelTests: XCTestCase {

    func test_submit_button_is_disabled_when_area_and_subject_and_description_are_empty() {
        // Given
        let viewModel = SupportFormViewModel(areas: Self.sampleAreas())

        // When
        viewModel.area = nil
        viewModel.subject = ""
        viewModel.siteAddress = ""
        viewModel.description = ""

        // Then
        XCTAssertTrue(viewModel.submitButtonDisabled)
    }

    func test_submit_button_is_disabled_when_area_is_empty_and_subject_is_not_empty_and_description_is_empty() {
        // Given
        let viewModel = SupportFormViewModel(areas: Self.sampleAreas())

        // When
        viewModel.area = nil
        viewModel.subject = "Subject"
        viewModel.siteAddress = "site-address"
        viewModel.description = ""

        // Then
        XCTAssertTrue(viewModel.submitButtonDisabled)
    }

    func test_submit_button_is_disabled_when_area_is_empty_and_subject_is_empty_and_description_is_not_empty() {
        // Given
        let viewModel = SupportFormViewModel(areas: Self.sampleAreas())

        // When
        viewModel.area = nil
        viewModel.subject = ""
        viewModel.siteAddress = ""
        viewModel.description = "Description"

        // Then
        XCTAssertTrue(viewModel.submitButtonDisabled)
    }

    func test_submit_button_is_disabled_when_site_address_is_empty() {
        // Given
        let viewModel = SupportFormViewModel(areas: Self.sampleAreas())

        // When
        viewModel.area = viewModel.areas.first
        viewModel.subject = "Subject"
        viewModel.description = "Description"
        viewModel.siteAddress = ""

        // Then
        XCTAssertTrue(viewModel.submitButtonDisabled)
    }

    func test_submit_button_is_enabled_when_all_fields_are_not_empty() {
        // Given
        let viewModel = SupportFormViewModel(areas: Self.sampleAreas())

        // When
        viewModel.area = viewModel.areas.first
        viewModel.subject = "Subject"
        viewModel.siteAddress = "site-address"
        viewModel.description = "Description"

        // Then
        XCTAssertFalse(viewModel.submitButtonDisabled)
    }

    func test_source_tag_is_properly_sent_when_creating_a_request() {
        // Given
        let sourceTag = "custom-tag"
        let zendesk = MockZendeskManager()
        let viewModel = SupportFormViewModel(areas: Self.sampleAreas(), sourceTag: sourceTag, zendeskProvider: zendesk)
        viewModel.area = viewModel.areas.first

        // When
        viewModel.submitSupportRequest()

        // Then
        XCTAssertTrue(zendesk.latestInvokedTags.contains(sourceTag))
    }

    func test_shouldShowIdentityInput_is_true_when_triggering_onViewAppear_no_existing_identity() {
        // Given
        let zendesk = MockZendeskManager()
        let viewModel = SupportFormViewModel(zendeskProvider: zendesk)

        // When
        zendesk.mockIdentity(name: "Test", email: "test@example.com", haveUserIdentity: false)
        viewModel.onViewAppear()

        // Then
        XCTAssertTrue(viewModel.shouldShowIdentityInput)
        XCTAssertEqual(viewModel.contactName, "Test")
        XCTAssertEqual(viewModel.contactEmailAddress, "test@example.com")
    }

    func test_shouldShowIdentityInput_is_false_when_triggering_onViewAppear_with_existing_identity() {
        // Given
        let zendesk = MockZendeskManager()
        let viewModel = SupportFormViewModel(zendeskProvider: zendesk)

        // When
        zendesk.mockIdentity(name: "Test", email: "test@example.com", haveUserIdentity: true)
        viewModel.onViewAppear()

        // Then
        XCTAssertFalse(viewModel.shouldShowIdentityInput)
    }

    func test_submitIdentityInfo_sets_shouldShowErrorAlert_to_true_when_fails() async {
        // Given
        let zendesk = MockZendeskManager()
        let viewModel = SupportFormViewModel(zendeskProvider: zendesk)

        // When
        zendesk.whenCreateIdentity(thenReturn: .failure(NSError(domain: "Test", code: 500)))
        await viewModel.submitIdentityInfo()

        // Then
        XCTAssertTrue(viewModel.shouldShowErrorAlert)
    }

    func test_submitSupportRequest_sets_shouldShowSuccessAlert_to_true_when_succeeds() {
        // Given
        let zendesk = MockZendeskManager()
        let area = SupportFormViewModel.Area(title: "Area 1", datasource: MockDataSource())
        let viewModel = SupportFormViewModel(zendeskProvider: zendesk)
        XCTAssertFalse(viewModel.shouldShowSuccessAlert)

        // When
        zendesk.whenCreateSupportRequest(thenReturn: .success(()))
        viewModel.selectArea(area)
        viewModel.submitSupportRequest()

        // Then
        waitUntil {
            viewModel.shouldShowSuccessAlert == true
        }
    }

    func test_submitSupportRequest_sets_shouldShowErrorAlert_to_true_when_fails() {
        // Given
        let zendesk = MockZendeskManager()
        let area = SupportFormViewModel.Area(title: "Area 1", datasource: MockDataSource())
        let viewModel = SupportFormViewModel(zendeskProvider: zendesk)
        XCTAssertFalse(viewModel.shouldShowErrorAlert)

        // When
        zendesk.whenCreateSupportRequest(thenReturn: .failure(NSError(domain: "Test", code: 500)))
        viewModel.selectArea(area)
        viewModel.submitSupportRequest()

        // Then
        waitUntil {
            viewModel.shouldShowErrorAlert == true
        }
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
