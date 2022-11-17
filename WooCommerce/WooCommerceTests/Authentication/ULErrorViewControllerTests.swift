import XCTest
import WordPressAuthenticator
@testable import WooCommerce

final class ULErrorViewControllerTests: XCTestCase {

    override func setUp() {
        super.setUp()

        WordPressAuthenticator.initializeAuthenticator()
    }

    override func tearDown() {
        // There is no known tear down for the Authenticator. So this method intentionally does
        // nothing.
        super.tearDown()
    }

    func test_viewcontroller_presents_title_provided_by_viewmodel() throws {
        // Given
        let viewModel = ErrorViewModel()
        let viewController = ULErrorViewController(viewModel: viewModel)

        // When
        _ = try XCTUnwrap(viewController.view)
        let title = viewController.title

        // Then
        XCTAssertEqual(title, viewModel.title)
    }

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

    func test_viewcontroller_does_not_have_right_bar_button_item_when_rightBarButtonItemTitle_is_nil_in_viewmodel() throws {
        // Given
        let viewModel = ErrorViewModel()
        viewModel.rightBarButtonItemTitle = nil
        let viewController = ULErrorViewController(viewModel: viewModel)

        // When
        _ = try XCTUnwrap(viewController.view)

        // Then
        XCTAssertNil(viewController.navigationItem.rightBarButtonItem)
    }

    func test_viewcontroller_shows_right_bar_button_item_when_rightBarButtonItemTitle_provided_by_viewmodel() throws {
        // Given
        let title = "Title"
        let viewModel = ErrorViewModel()
        viewModel.rightBarButtonItemTitle = title
        let viewController = ULErrorViewController(viewModel: viewModel)

        // When
        _ = try XCTUnwrap(viewController.view)
        let rightBarButtonItem = try XCTUnwrap(viewController.navigationItem.rightBarButtonItem)

        // Then
        XCTAssertEqual(rightBarButtonItem.title, title)
    }

    func test_viewcontroller_hits_viewmodel_when_right_bar_button_item_is_tapped() throws {
        // Given
        let viewModel = ErrorViewModel()
        viewModel.rightBarButtonItemTitle = "Button"
        let viewController = ULErrorViewController(viewModel: viewModel)

        // When
        _ = try XCTUnwrap(viewController.view)
        let rightBarButtonItem = try XCTUnwrap(viewController.navigationItem.rightBarButtonItem)

        _ = rightBarButtonItem.target?.perform(rightBarButtonItem.action)

        // Then
        XCTAssertTrue(viewModel.rightBarButtonItemTapped)
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

    func test_viewController_informs_viewModel_when_the_view_is_loaded() throws {
        // Given
        let viewModel = ErrorViewModel()
        let viewController = ULErrorViewController(viewModel: viewModel)

        XCTAssertFalse(viewModel.viewDidLoadTriggered)

        // When
        _ = try XCTUnwrap(viewController.view)

        // Then
        XCTAssertTrue(viewModel.viewDidLoadTriggered)
    }

    func test_terms_label_is_hidden_if_terms_text_is_nil() throws {
        // Given
        let viewModel = ErrorViewModel()
        let viewController = ULErrorViewController(viewModel: viewModel)

        // When
        _ = try XCTUnwrap(viewController.view)
        let termsLabel = viewController.getTermsLabel()

        // Then
        XCTAssertTrue(termsLabel.isHidden)
    }
}


private final class ErrorViewModel: ULErrorViewModel {
    let title: String? = "Test"

    let image: UIImage = .loginNoJetpackError

    let text: NSAttributedString = NSAttributedString(string: "woocommerce")

    let isAuxiliaryButtonHidden: Bool = false

    let auxiliaryButtonTitle: String = "Aux"

    let primaryButtonTitle: String = "Primary"

    let secondaryButtonTitle: String = "Secondary"

    var rightBarButtonItemTitle: String?

    var termsLabelText: NSAttributedString?

    var primaryButtonTapped: Bool = false
    var secondaryButtonTapped: Bool = false
    var auxiliaryButtonTapped: Bool = false
    var viewDidLoadTriggered = false
    var rightBarButtonItemTapped = false

    func didTapPrimaryButton(in viewController: UIViewController?) {
        primaryButtonTapped = true
    }

    func didTapSecondaryButton(in viewController: UIViewController?) {
        secondaryButtonTapped = true
    }

    func didTapAuxiliaryButton(in viewController: UIViewController?) {
        auxiliaryButtonTapped = true
    }

    func didTapRightBarButtonItem(in viewController: UIViewController?) {
        rightBarButtonItemTapped = true
    }

    func viewDidLoad(_ viewController: UIViewController?) {
        viewDidLoadTriggered = true
    }
}
