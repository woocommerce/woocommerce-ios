import XCTest
@testable import WooCommerce

final class ULErrorViewControllerTests: XCTestCase {

    func test_viewcontroller_presents_image_provided_by_viewmodel() throws {
        // Given
        let viewModel = ErrorViewModel()
        let viewController = ULErrorViewController(viewModel: viewModel)

        // When
        _ = try XCTUnwrap(viewController.view)
        let image = viewController.getImageView().image

        // Then
        XCTAssertEqual(image, viewModel.image)
    }

    func test_viewcontroller_presents_text_provided_by_viewmodel() throws {
        // Given
        let viewModel = ErrorViewModel()
        let viewController = ULErrorViewController(viewModel: viewModel)

        // When
        _ = try XCTUnwrap(viewController.view)
        let text = viewController.getLabel().attributedText

        // Then
        XCTAssertEqual(text, viewModel.text)
    }

    func test_viewcontroller_assigns_title_provided_by_viewmodel_to_auxbutton() throws {
        // Given
        let viewModel = ErrorViewModel()
        let viewController = ULErrorViewController(viewModel: viewModel)

        // When
        _ = try XCTUnwrap(viewController.view)
        let auxiliaryButtonTitle = viewController.getAuxiliaryButton().title(for: .normal)

        // Then
        XCTAssertEqual(auxiliaryButtonTitle, viewModel.auxiliaryButtonTitle)
    }

    func test_viewcontroller_assigns_visibility_provided_by_viewmodel_to_auxbutton() throws {
        // Given
        let viewModel = ErrorViewModel()
        let viewController = ULErrorViewController(viewModel: viewModel)

        // When
        _ = try XCTUnwrap(viewController.view)
        let auxiliaryButtonHidden = viewController.getAuxiliaryButton().isHidden

        // Then
        XCTAssertEqual(auxiliaryButtonHidden, viewModel.isAuxiliaryButtonHidden)
    }

    func test_viewcontroller_hits_viewmodel_when_auxbutton_is_tapped() throws {
        // Given
        let viewModel = ErrorViewModel()
        let viewController = ULErrorViewController(viewModel: viewModel)

        // When
        _ = try XCTUnwrap(viewController.view)

        let auxiliaryButton = viewController.getAuxiliaryButton()

        auxiliaryButton.sendActions(for: .touchUpInside)

        // Then
        XCTAssertTrue(viewModel.auxiliaryButtonTapped)
    }

    func test_viewcontroller_assigns_title_provided_by_viewmodel_to_primary_button() throws {
        // Given
        let viewModel = ErrorViewModel()
        let viewController = ULErrorViewController(viewModel: viewModel)

        // When
        _ = try XCTUnwrap(viewController.view)
        let primaryButtonTitle = viewController.primaryActionButton().title(for: .normal)

        // Then
        XCTAssertEqual(primaryButtonTitle, viewModel.primaryButtonTitle)
    }

    func test_viewcontroller_hits_viewmodel_when_primary_button_is_tapped() throws {
        // Given
        let viewModel = ErrorViewModel()
        let viewController = ULErrorViewController(viewModel: viewModel)

        // When
        _ = try XCTUnwrap(viewController.view)
        let primaryButton = viewController.primaryActionButton()
        primaryButton.sendActions(for: .touchUpInside)

        // Then
        XCTAssertTrue(viewModel.primaryButtonTapped)
    }

    func test_viewcontroller_assigns_title_provided_by_viewmodel_to_secondary_button() throws {
        // Given
        let viewModel = ErrorViewModel()
        let viewController = ULErrorViewController(viewModel: viewModel)

        // When
        _ = try XCTUnwrap(viewController.view)
        let secondaryActionButtonTitle = viewController.secondaryActionButton().title(for: .normal)

        // Then
        XCTAssertEqual(secondaryActionButtonTitle, viewModel.secondaryButtonTitle)
    }

    func test_viewcontroller_hits_viewmodel_when_secondary_button_is_tapped() throws {
        // Given
        let viewModel = ErrorViewModel()
        let viewController = ULErrorViewController(viewModel: viewModel)

        // When
        _ = try XCTUnwrap(viewController.view)
        let secondaryButton = viewController.secondaryActionButton()
        secondaryButton.sendActions(for: .touchUpInside)

        // Then
        XCTAssertTrue(viewModel.secondaryButtonTapped)
    }
}


private final class ErrorViewModel: ULErrorViewModel {
    let image: UIImage = .loginNoJetpackError

    let text: NSAttributedString = NSAttributedString(string: "woocommerce")

    let isAuxiliaryButtonHidden: Bool = false

    let auxiliaryButtonTitle: String = "Aux"

    let primaryButtonTitle: String = "Primary"

    let secondaryButtonTitle: String = "Secondary"

    var primaryButtonTapped: Bool = false
    var secondaryButtonTapped: Bool = false
    var auxiliaryButtonTapped: Bool = false

    func didTapPrimaryButton(in viewController: UIViewController?) {
        primaryButtonTapped = true
    }

    func didTapSecondaryButton(in viewController: UIViewController?) {
        secondaryButtonTapped = true
    }

    func didTapAuxiliaryButton(in viewController: UIViewController?) {
        auxiliaryButtonTapped = true
    }
}
