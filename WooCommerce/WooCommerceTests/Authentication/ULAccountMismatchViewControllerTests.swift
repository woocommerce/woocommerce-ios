import XCTest
@testable import WooCommerce

final class ULAccountMismatchViewControllerTests: XCTestCase {

    func test_viewcontroller_presents_username_provided_by_viewmodel() throws {
        // Given
        let viewModel = MistmatchViewModel()
        let viewController = ULAccountMismatchViewController(viewModel: viewModel)

        // When
        _ = try XCTUnwrap(viewController.view)
        let userName = viewController.getUserNameLabel().text

        // Then
        XCTAssertEqual(userName, viewModel.userName)
    }

    func test_viewcontroller_presents_signedIn_provided_by_viewmodel() throws {
        // Given
        let viewModel = MistmatchViewModel()
        let viewController = ULAccountMismatchViewController(viewModel: viewModel)

        // When
        _ = try XCTUnwrap(viewController.view)
        let signedInAs = viewController.getSingedInAsLabel().text

        // Then
        XCTAssertEqual(signedInAs, viewModel.signedInText)
    }

    func test_viewcontroller_presents_image_provided_by_viewmodel() throws {
        // Given
        let viewModel = MistmatchViewModel()
        let viewController = ULAccountMismatchViewController(viewModel: viewModel)

        // When
        _ = try XCTUnwrap(viewController.view)
        let image = viewController.getImageView().image

        // Then
        XCTAssertEqual(image, viewModel.image)
    }

    func test_viewcontroller_presents_text_provided_by_viewmodel() throws {
        // Given
        let viewModel = MistmatchViewModel()
        let viewController = ULAccountMismatchViewController(viewModel: viewModel)

        // When
        _ = try XCTUnwrap(viewController.view)
        let message = viewController.getMessage().attributedText

        // Then
        XCTAssertEqual(message, viewModel.text)
    }

    func test_viewcontroller_assigns_title_provided_by_viewmodel_to_auxbutton() throws {
        // Given
        let viewModel = MistmatchViewModel()
        let viewController = ULAccountMismatchViewController(viewModel: viewModel)

        // When
        _ = try XCTUnwrap(viewController.view)
        let auxiliaryButtonTitle = viewController.getAuxiliaryButton().title(for: .normal)

        // Then
        XCTAssertEqual(auxiliaryButtonTitle, viewModel.auxiliaryButtonTitle)
    }

    func test_viewcontroller_assigns_visibility_provided_by_viewmodel_to_auxbutton() throws {
        // Given
        let viewModel = MistmatchViewModel()
        let viewController = ULAccountMismatchViewController(viewModel: viewModel)

        // When
        _ = try XCTUnwrap(viewController.view)
        let auxiliaryButtonHidden = viewController.getAuxiliaryButton().isHidden

        // Then
        XCTAssertEqual(auxiliaryButtonHidden, viewModel.isAuxiliaryButtonHidden)
    }

    func test_viewcontroller_hits_viewmodel_when_auxbutton_is_tapped() throws {
        // Given
        let viewModel = MistmatchViewModel()
        let viewController = ULAccountMismatchViewController(viewModel: viewModel)

        // When
        _ = try XCTUnwrap(viewController.view)

        let auxiliaryButton = viewController.getAuxiliaryButton()

        auxiliaryButton.sendActions(for: .touchUpInside)

        // Then
        XCTAssertTrue(viewModel.auxiliaryButtonTapped)
    }

    func test_viewcontroller_assigns_title_provided_by_viewmodel_to_primary_button() throws {
        // Given
        let viewModel = MistmatchViewModel()
        let viewController = ULAccountMismatchViewController(viewModel: viewModel)

        // When
        _ = try XCTUnwrap(viewController.view)
        let primaryButtonTitle = viewController.getPrimaryActionButton().title(for: .normal)

        // Then
        XCTAssertEqual(primaryButtonTitle, viewModel.primaryButtonTitle)
    }

    func test_viewcontroller_hits_viewmodel_when_primary_button_is_tapped() throws {
        // Given
        let viewModel = MistmatchViewModel()
        let viewController = ULAccountMismatchViewController(viewModel: viewModel)

        // When
        _ = try XCTUnwrap(viewController.view)
        let primaryButton = viewController.getPrimaryActionButton()
        primaryButton.sendActions(for: .touchUpInside)

        // Then
        XCTAssertTrue(viewModel.primaryButtonTapped)
    }

    func test_viewcontroller_assigns_title_provided_by_viewmodel_to_logout_button() throws {
        // Given
        let viewModel = MistmatchViewModel()
        let viewController = ULAccountMismatchViewController(viewModel: viewModel)

        // When
        _ = try XCTUnwrap(viewController.view)
        let logOutButtonTitle = viewController.getLogOutButton().title(for: .normal)

        // Then
        XCTAssertEqual(logOutButtonTitle, viewModel.logOutButtonTitle)
    }

    func test_viewcontroller_hits_viewmodel_when_logout_button_is_tapped() throws {
        // Given
        let viewModel = MistmatchViewModel()
        let viewController = ULAccountMismatchViewController(viewModel: viewModel)

        // When
        _ = try XCTUnwrap(viewController.view)
        let logOutButton = viewController.getLogOutButton()
        logOutButton.sendActions(for: .touchUpInside)

        // Then
        XCTAssertTrue(viewModel.logOutButtonTapped)
    }
}


private final class MistmatchViewModel: ULAccountMismatchViewModel {
    let userEmail: String = "email@awebsite.com"

    var userName: String = "username"

    var signedInText: String = "signed_in_text"

    var logOutTitle: String = "log_out_title"

    var logOutButtonTitle: String = "logout_button_title"

    let image: UIImage = .loginNoJetpackError

    let text: NSAttributedString = NSAttributedString(string: "woocommerce")

    let isAuxiliaryButtonHidden: Bool = false

    let auxiliaryButtonTitle: String = "Aux"

    let primaryButtonTitle: String = "Primary"


    var primaryButtonTapped: Bool = false
    var logOutButtonTapped: Bool = false
    var auxiliaryButtonTapped: Bool = false

    func didTapPrimaryButton(in viewController: UIViewController?) {
        primaryButtonTapped = true
    }

    func didTapLogOutButton(in viewController: UIViewController?) {
        logOutButtonTapped = true
    }

    func didTapAuxiliaryButton(in viewController: UIViewController?) {
        auxiliaryButtonTapped = true
    }
}
