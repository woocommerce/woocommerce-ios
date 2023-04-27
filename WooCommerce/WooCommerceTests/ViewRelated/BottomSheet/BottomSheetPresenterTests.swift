import XCTest
@testable import WooCommerce

final class BottomSheetPresenterTests: XCTestCase {
    func test_sheet_customizations_are_set_to_sheetPresentationController() throws {
        // Given
        let presenter = BottomSheetPresenter { bottomSheet in
            var sheet = bottomSheet
            sheet.prefersEdgeAttachedInCompactHeight = false
            sheet.largestUndimmedDetentIdentifier = nil
            sheet.prefersGrabberVisible = false
            sheet.detents = [.large()]
        }
        let viewController = UIViewController()

        // When
        presenter.present(viewController, from: .init())

        // Then
        let sheetPresentationController = try XCTUnwrap(viewController.sheetPresentationController)
        XCTAssertTrue(sheetPresentationController.prefersEdgeAttachedInCompactHeight == false)
        XCTAssertNil(sheetPresentationController.largestUndimmedDetentIdentifier)
        XCTAssertTrue(sheetPresentationController.prefersGrabberVisible == false)
        XCTAssertEqual(sheetPresentationController.detents, [.large()])
    }

    func test_dismiss_sheet_invokes_onDismiss_from_present() throws {
        // Given
        let presenter = BottomSheetPresenter()
        let viewController = UIViewController()

        // When
        waitFor { promise in
            presenter.present(viewController, from: .init()) {
                // Then
                promise(())
            }
            presenter.dismiss()
        }
    }

    func test_dismiss_sheet_invokes_onDismiss_from_dismiss() throws {
        // Given
        let presenter = BottomSheetPresenter()
        let viewController = UIViewController()

        // When
        waitFor { promise in
            presenter.present(viewController, from: .init(), onDismiss: {
                XCTFail("The onDismiss of the present call should not be invoked.")
            })
            presenter.dismiss(onDismiss: {
                // Then
                promise(())
            })
        }
    }

    func test_interactively_dismissing_sheet_invokes_onDismiss() throws {
        // Given
        let presenter = BottomSheetPresenter()
        let viewController = UIViewController()

        // When
        waitFor { promise in
            presenter.present(viewController, from: .init()) {
                // Then
                promise(())
            }
            presenter.presentationControllerDidDismiss(UIPresentationController(presentedViewController: .init(), presenting: nil))
        }
    }
}
