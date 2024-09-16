import XCTest
@testable import WooFoundation
@testable import WooCommerce

final class PointOfSaleCardPresentPaymentConnectionSuccessAlertViewModelTests: XCTestCase {

    func test_manual_equatable_conformance_number_of_properties_unchanged() {
        let sut = PointOfSaleCardPresentPaymentConnectionSuccessAlertViewModel(doneAction: {})

        XCTAssertPropertyCount(sut,
                               expectedCount: 5,
                               messageHint: "Please check that the manual equatable conformance includes new properties.")
    }

    func test_manual_hashable_conformance_number_of_properties_unchanged() {
        let sut = PointOfSaleCardPresentPaymentConnectionSuccessAlertViewModel(doneAction: {})

        XCTAssertPropertyCount(sut,
                               expectedCount: 5,
                               messageHint: "Please check that the manual hashable conformance includes new properties.")
    }

    func test_when_scheduler_fires_the_modal_is_dismissed() {
        // Given
        let testScheduler = MockScheduler()

        waitFor { promise in
            let sut = PointOfSaleCardPresentPaymentConnectionSuccessAlertViewModel(
                doneAction: {
                    // Then doneAction is called
                    promise(())
                },
                scheduler: testScheduler
            )
            // When the scheduler fires
            testScheduler.runNextAction()
        }
    }

    func test_when_the_view_model_is_destroyed_the_autodismiss_work_item_is_cancelled() {
        // Given
        let testScheduler = MockScheduler()

        var sut: PointOfSaleCardPresentPaymentConnectionSuccessAlertViewModel? = .init(
            doneAction: { },
            scheduler: testScheduler
        )

        guard let autoDismissWorkItem = try? XCTUnwrap(testScheduler.scheduledActions.first?.2) else {
            return XCTFail("The autoDismiss work item wasn't found")
        }

        XCTAssertFalse(autoDismissWorkItem.isCancelled)

        // When
        sut = nil

        // Then
        XCTAssertTrue(autoDismissWorkItem.isCancelled)
    }

    func test_when_the_button_is_tapped_the_autodismiss_work_item_is_cancelled() {
        // Given
        let testScheduler = MockScheduler()

        let sut = PointOfSaleCardPresentPaymentConnectionSuccessAlertViewModel(
            doneAction: { },
            scheduler: testScheduler
        )

        guard let autoDismissWorkItem = try? XCTUnwrap(testScheduler.scheduledActions.first?.2) else {
            return XCTFail("The autoDismiss work item wasn't found")
        }

        XCTAssertFalse(autoDismissWorkItem.isCancelled)

        // When
        sut.buttonViewModel.actionHandler()

        // Then
        XCTAssertTrue(autoDismissWorkItem.isCancelled)
    }

}
