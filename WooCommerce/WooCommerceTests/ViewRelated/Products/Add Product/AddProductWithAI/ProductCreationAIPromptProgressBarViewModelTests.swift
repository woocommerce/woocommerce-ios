import XCTest
@testable import WooCommerce
import WooFoundation
import SwiftUI

class ProductCreationAIPromptProgressBarViewModelTests: XCTestCase {

    // MARK: - Test updateText(to:)
    func test_update_text_to_empty_string() {
        // Given
        let viewModel = ProductCreationAIPromptProgressBarViewModel()

        // When
        viewModel.updateText(to: "")

        // Then
        XCTAssertEqual(viewModel.status, .start)
    }

    func test_update_text_to_five_words() {
        // Given
        let viewModel = ProductCreationAIPromptProgressBarViewModel()

        // When
        viewModel.updateText(to: "This is a test input.")

        // Then
        XCTAssertEqual(viewModel.status, .inProgress)
    }

    func test_update_text_to_fifteen_words() {
        // Given
        let viewModel = ProductCreationAIPromptProgressBarViewModel()

        // When
        viewModel.updateText(to: "This is a test input with fifteen words to check halfway status.")

        // Then
        XCTAssertEqual(viewModel.status, .halfway)
    }

    func test_update_text_to_twenty_five_words() {
        // Given
        let viewModel = ProductCreationAIPromptProgressBarViewModel()

        // When
        viewModel.updateText(to: "This is a test input with twenty five words to check the almost done status of the progress bar view model in Swift.")

        // Then
        XCTAssertEqual(viewModel.status, .almostDone)
    }

    func test_update_text_to_thirty_five_words() {
        // Given
        let viewModel = ProductCreationAIPromptProgressBarViewModel()

        // When
        viewModel.updateText(to: "This is a test input with thirty five words to check the completed status of the progress bar view model in Swift" +
                             " Adding more words to ensure it exceeds thirty words.")

        // Then
        XCTAssertEqual(viewModel.status, .completed)
    }

    // MARK: - Test ProgressStatus Enum
    func test_progress_status_start() {
        // Given
        let status = ProductCreationAIPromptProgressBarViewModel.ProgressStatus.start

        // Then
        XCTAssertEqual(status.progress, 0.03)
        XCTAssertEqual(status.color, Color(uiColor: .gray(.shade50)))
        XCTAssertEqual(status.mainDescription, "")
        XCTAssertEqual(status.secondaryDescription, ProductCreationAIPromptProgressBarViewModel.Localization.SecondaryDescription.startStatus)
    }

    func test_progress_status_in_progress() {
        // Given
        let status = ProductCreationAIPromptProgressBarViewModel.ProgressStatus.inProgress

        // Then
        XCTAssertEqual(status.progress, 0.2)
        XCTAssertEqual(status.color, Color(uiColor: .withColorStudio(.red, shade: .shade50)))
        XCTAssertEqual(status.mainDescription, ProductCreationAIPromptProgressBarViewModel.Localization.MainDescription.inProgressStatus)
        XCTAssertEqual(status.secondaryDescription, ProductCreationAIPromptProgressBarViewModel.Localization.SecondaryDescription.inProgressStatus)
    }

    func test_progress_status_halfway() {
        // Given
        let status = ProductCreationAIPromptProgressBarViewModel.ProgressStatus.halfway

        // Then
        XCTAssertEqual(status.progress, 0.4)
        XCTAssertEqual(status.color, Color(uiColor: .withColorStudio(.orange, shade: .shade50)))
        XCTAssertEqual(status.mainDescription, ProductCreationAIPromptProgressBarViewModel.Localization.MainDescription.halfwayStatus)
        XCTAssertEqual(status.secondaryDescription, ProductCreationAIPromptProgressBarViewModel.Localization.SecondaryDescription.halfwayStatus)
    }

    func test_progress_status_almost_done() {
        // Given
        let status = ProductCreationAIPromptProgressBarViewModel.ProgressStatus.almostDone

        // Then
        XCTAssertEqual(status.progress, 0.7)
        XCTAssertEqual(status.color, Color(uiColor: .withColorStudio(.yellow, shade: .shade50)))
        XCTAssertEqual(status.mainDescription, ProductCreationAIPromptProgressBarViewModel.Localization.MainDescription.almostDoneStatus)
        XCTAssertEqual(status.secondaryDescription, ProductCreationAIPromptProgressBarViewModel.Localization.SecondaryDescription.almostDoneStatus)
    }

    func test_progress_status_completed() {
        // Given
        let status = ProductCreationAIPromptProgressBarViewModel.ProgressStatus.completed

        // Then
        XCTAssertEqual(status.progress, 0.9)
        XCTAssertEqual(status.color, Color(uiColor: .withColorStudio(.green, shade: .shade50)))
        XCTAssertEqual(status.mainDescription, ProductCreationAIPromptProgressBarViewModel.Localization.MainDescription.completedStatus)
        XCTAssertEqual(status.secondaryDescription, ProductCreationAIPromptProgressBarViewModel.Localization.SecondaryDescription.completedStatus)
    }
}
