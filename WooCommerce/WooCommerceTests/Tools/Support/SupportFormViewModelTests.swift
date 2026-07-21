import XCTest
import Yosemite
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

    func test_site_address_is_sent_when_submitting_request() {
        // Given
        let zendesk = MockZendeskManager()
        let area = SupportFormViewModel.Area(title: "Area 1", datasource: MockDataSource())
        let viewModel = SupportFormViewModel(zendeskProvider: zendesk)

        // When
        viewModel.selectArea(area)
        viewModel.siteAddress = "site-address"
        viewModel.submitSupportRequest()

        // Then
        XCTAssertTrue(zendesk.latestInvokedCustomFields.values.contains("site-address"))
    }

    func test_default_site_is_populated_when_available() {
        // Given
        let zendesk = MockZendeskManager()
        let defaultSite = Site.fake().copy(url: "site-address")
        let viewModel = SupportFormViewModel(zendeskProvider: zendesk, defaultSite: defaultSite)

        // When
        viewModel.onViewAppear()

        // Then
        XCTAssertEqual(viewModel.siteAddress, defaultSite.url)
    }

    func test_transcript_context_does_not_enable_submit_when_editable_message_is_empty() {
        // Given
        let viewModel = SupportFormViewModel(areas: Self.sampleAreas(), transcript: "Formatted transcript")

        // When
        viewModel.area = viewModel.areas.first
        viewModel.subject = "Subject"
        viewModel.siteAddress = "site-address"
        viewModel.description = ""

        // Then
        XCTAssertTrue(viewModel.shouldShowTranscriptDisclosure)
        XCTAssertTrue(viewModel.submitButtonDisabled)
    }

    func test_submitSupportRequest_appends_immutable_transcript_after_user_message() {
        // Given
        let zendesk = MockZendeskManager()
        let transcript = "Transcript header\n\nTest transcript"
        let viewModel = SupportFormViewModel(areas: Self.sampleAreas(),
                                             zendeskProvider: zendesk,
                                             transcript: transcript)
        viewModel.area = viewModel.areas.first
        viewModel.subject = "Subject"
        viewModel.siteAddress = "site-address"
        viewModel.description = "Additional details"

        // When
        viewModel.submitSupportRequest()

        // Then
        XCTAssertEqual(zendesk.latestSupportRequest?.description, "Additional details\n\n\(transcript)")
        XCTAssertEqual(zendesk.latestSupportRequest?.description.components(separatedBy: "Test transcript").count, 2)
    }

    func test_submitSupportRequest_when_transcript_is_whitespace_then_does_not_add_disclosure_or_transcript_separator() {
        // Given
        let zendesk = MockZendeskManager()
        let viewModel = SupportFormViewModel(areas: Self.sampleAreas(),
                                             zendeskProvider: zendesk,
                                             transcript: " \n ")
        viewModel.area = viewModel.areas.first
        viewModel.description = "Additional details"

        // When
        viewModel.submitSupportRequest()

        // Then
        XCTAssertFalse(viewModel.shouldShowTranscriptDisclosure)
        XCTAssertEqual(zendesk.latestSupportRequest?.description, "Additional details")
    }

    func test_submitSupportRequest_includes_diagnostic_and_application_log_attachments() {
        // Given
        let zendesk = MockZendeskManager()
        let diagnostic = ZendeskAttachment(data: Data("Diagnostic".utf8),
                                           filename: "connectivitytest_log.txt",
                                           contentType: "text/plain")
        let attachmentProvider = DefaultSupportRequestAttachmentProvider(
            applicationLogProvider: MockApplicationLogProvider(logs: "Application log")
        )
        let viewModel = SupportFormViewModel(areas: Self.sampleAreas(),
                                             zendeskProvider: zendesk,
                                             attachmentProvider: attachmentProvider,
                                             attachments: [diagnostic])
        viewModel.area = viewModel.areas.first

        // When
        viewModel.submitSupportRequest()

        // Then
        XCTAssertEqual(zendesk.latestSupportRequest?.attachments.map(\.filename),
                       ["connectivitytest_log.txt", "application_log.txt"])
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
