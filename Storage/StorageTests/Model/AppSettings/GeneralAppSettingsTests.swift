import XCTest
@testable import Storage

class GeneralAppSettingsTests: XCTestCase {

    func test_it_returns_the_correct_status_of_a_stored_feedback() {
        // Given
        let feedback = FeedbackSettings(name: .general, status: .dismissed)
        let settings = GeneralAppSettings(installationDate: nil, feedbacks: [.general: feedback])

        // When
        let loadedStatus = settings.feedbackStatus(of: .general)

        // Then
        XCTAssertEqual(feedback.status, loadedStatus)
    }

    func test_it_returns_pending_status_of_a_non_stored_feedback() {
        // Given
        let settings = GeneralAppSettings(installationDate: nil, feedbacks: [:])

        // When
        let loadedStatus = settings.feedbackStatus(of: .general)

        // Then
        XCTAssertEqual(loadedStatus, .pending)
    }
}
