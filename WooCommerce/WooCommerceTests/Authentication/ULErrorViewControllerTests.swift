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

}


private final class ErrorViewModel: ULErrorViewModel {
    let image: UIImage = .loginNoJetpackError

    let text: NSAttributedString = NSAttributedString(string: "woocommerce")

    let isAuxiliaryButtonHidden: Bool = true

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
