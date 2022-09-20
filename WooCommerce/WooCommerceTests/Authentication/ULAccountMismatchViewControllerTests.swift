import Combine
import XCTest
@testable import WooCommerce

final class ULAccountMismatchViewControllerTests: XCTestCase {

    private var subscriptions: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()
        subscriptions = []
    }

    func test_viewcontroller_presents_username_provided_by_viewmodel() throws {
        // Given
        let viewModel = MismatchViewModel()
        let viewController = ULAccountMismatchViewController(viewModel: viewModel)

        // When
        _ = try XCTUnwrap(viewController.view)
        let userName = viewController.getUserNameLabel().text

        // Then
        XCTAssertEqual(userName, viewModel.userName)
    }

    func test_viewcontroller_presents_signedIn_provided_by_viewmodel() throws {
        // Given
        let viewModel = MismatchViewModel()
        let viewController = ULAccountMismatchViewController(viewModel: viewModel)

        // When
        _ = try XCTUnwrap(viewController.view)
        let signedInAs = viewController.getSingedInAsLabel().text

        // Then
        XCTAssertEqual(signedInAs, viewModel.signedInText)
    }

    func test_viewcontroller_presents_image_provided_by_viewmodel() throws {
        // Given
        let viewModel = MismatchViewModel()
        let viewController = ULAccountMismatchViewController(viewModel: viewModel)

        // When
        _ = try XCTUnwrap(viewController.view)
        let image = viewController.getImageView().image

        // Then
        XCTAssertEqual(image, viewModel.image)
    }

    func test_viewcontroller_presents_text_provided_by_viewmodel() throws {
        // Given
        let viewModel = MismatchViewModel()
        let viewController = ULAccountMismatchViewController(viewModel: viewModel)

        // When
        _ = try XCTUnwrap(viewController.view)
        let message = viewController.getMessage().attributedText

        // Then
        XCTAssertEqual(message, viewModel.text)
    }

    func test_viewcontroller_assigns_title_provided_by_viewmodel_to_auxbutton() throws {
        // Given
        let viewModel = MismatchViewModel()
        let viewController = ULAccountMismatchViewController(viewModel: viewModel)

        // When
        _ = try XCTUnwrap(viewController.view)
        let auxiliaryButtonTitle = viewController.getAuxiliaryButton().title(for: .normal)

        // Then
        XCTAssertEqual(auxiliaryButtonTitle, viewModel.auxiliaryButtonTitle)
    }

    func test_viewcontroller_hits_viewmodel_when_auxbutton_is_tapped() throws {
        // Given
        let viewModel = MismatchViewModel()
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
        let viewModel = MismatchViewModel()
        let viewController = ULAccountMismatchViewController(viewModel: viewModel)

        // When
        _ = try XCTUnwrap(viewController.view)
        let primaryButtonTitle = viewController.getPrimaryActionButton().title(for: .normal)

        // Then
        XCTAssertEqual(primaryButtonTitle, viewModel.primaryButtonTitle)
    }

    func test_viewcontroller_assigns_title_provided_by_viewmodel_to_secondary_button() throws {
        // Given
        let viewModel = MismatchViewModel()
        let viewController = ULAccountMismatchViewController(viewModel: viewModel)

        // When
        _ = try XCTUnwrap(viewController.view)
        let secondaryButtonTitle = viewController.getSecondaryActionButton().title(for: .normal)

        // Then
        XCTAssertEqual(secondaryButtonTitle, viewModel.secondaryButtonTitle)
    }

    func test_viewcontroller_hits_viewmodel_when_view_is_loaded() throws {
        // Given
        let viewModel = MismatchViewModel()
        let viewController = ULAccountMismatchViewController(viewModel: viewModel)

        // When
        _ = try XCTUnwrap(viewController.view)
        viewController.viewDidLoad()

        // Then
        XCTAssertTrue(viewModel.viewLoaded)
    }

    func test_viewcontroller_hits_viewmodel_when_primary_button_is_tapped() throws {
        // Given
        let viewModel = MismatchViewModel()
        let viewController = ULAccountMismatchViewController(viewModel: viewModel)

        // When
        _ = try XCTUnwrap(viewController.view)
        let primaryButton = viewController.getPrimaryActionButton()
        primaryButton.sendActions(for: .touchUpInside)

        // Then
        XCTAssertTrue(viewModel.primaryButtonTapped)
    }

    func test_viewcontroller_hits_viewmodel_when_secondary_button_is_tapped() throws {
        // Given
        let viewModel = MismatchViewModel()
        let viewController = ULAccountMismatchViewController(viewModel: viewModel)

        // When
        _ = try XCTUnwrap(viewController.view)
        let secondaryButton = viewController.getSecondaryActionButton()
        secondaryButton.sendActions(for: .touchUpInside)

        // Then
        XCTAssertTrue(viewModel.secondaryButtonTapped)
    }

    func test_viewcontroller_assigns_title_provided_by_viewmodel_to_logout_button() throws {
        // Given
        let viewModel = MismatchViewModel()
        let viewController = ULAccountMismatchViewController(viewModel: viewModel)

        // When
        _ = try XCTUnwrap(viewController.view)
        let logOutButtonTitle = viewController.getLogOutButton().title(for: .normal)

        // Then
        XCTAssertEqual(logOutButtonTitle, viewModel.logOutButtonTitle)
    }

    func test_viewcontroller_hits_viewmodel_when_logout_button_is_tapped() throws {
        // Given
        let viewModel = MismatchViewModel()
        let viewController = ULAccountMismatchViewController(viewModel: viewModel)

        // When
        _ = try XCTUnwrap(viewController.view)
        let logOutButton = viewController.getLogOutButton()
        logOutButton.sendActions(for: .touchUpInside)

        // Then
        XCTAssertTrue(viewModel.logOutButtonTapped)
    }

    func test_viewcontroller_assigns_visibility_provided_by_viewmodel_to_primary_button() throws {
        // Given
        let viewModel = MismatchViewModel()
        let viewController = ULAccountMismatchViewController(viewModel: viewModel)

        // When
        _ = try XCTUnwrap(viewController.view)
        let primaryButton = viewController.getPrimaryActionButton()
        var isHidden: Bool?
        viewModel.isPrimaryButtonHidden
            .sink { isHidden = $0 }
            .store(in: &subscriptions)
        viewModel.primaryButtonHidden = true

        // Then
        XCTAssertEqual(primaryButton.isHidden, isHidden)
    }

    func test_viewcontroller_assigns_visibility_provided_by_viewmodel_to_secondary_button() throws {
        // Given
        let viewModel = MismatchViewModel()
        let viewController = ULAccountMismatchViewController(viewModel: viewModel)

        // When
        _ = try XCTUnwrap(viewController.view)
        let secondaryButton = viewController.getSecondaryActionButton()

        // Then
        XCTAssertEqual(secondaryButton.isHidden, viewModel.isSecondaryButtonHidden)
    }

    func test_viewcontroller_assigns_loading_state_provided_by_viewmodel_to_activity_indicator() throws {
        // Given
        let viewModel = MismatchViewModel()
        let viewController = ULAccountMismatchViewController(viewModel: viewModel)

        // When
        _ = try XCTUnwrap(viewController.view)
        let activityIndicator = viewController.getActivityIndicator()
        var isLoading: Bool?
        viewModel.isShowingActivityIndicator
            .sink { isLoading = $0 }
            .store(in: &subscriptions)
        viewModel.showingActivityIndicator = true

        // Then
        XCTAssertEqual(activityIndicator.isAnimating, isLoading)
    }
}


private final class MismatchViewModel: ULAccountMismatchViewModel {
    var isPrimaryButtonHidden: AnyPublisher<Bool, Never> {
        Just(primaryButtonHidden).eraseToAnyPublisher()
    }

    var isPrimaryButtonLoading: AnyPublisher<Bool, Never> {
        Just(primaryButtonLoading).eraseToAnyPublisher()
    }

    let secondaryButtonTitle: String = "Secondary"

    let isSecondaryButtonHidden: Bool = false

    var isShowingActivityIndicator: AnyPublisher<Bool, Never> {
        Just(showingActivityIndicator).eraseToAnyPublisher()
    }

    let userEmail: String = "email@awebsite.com"

    var userName: String = "username"

    var signedInText: String = "signed_in_text"

    var logOutTitle: String = "log_out_title"

    var logOutButtonTitle: String = "logout_button_title"

    let image: UIImage = .loginNoJetpackError

    let text: NSAttributedString = NSAttributedString(string: "woocommerce")

    let auxiliaryButtonTitle: String = "Aux"

    let primaryButtonTitle: String = "Primary"

    var viewLoaded: Bool = false
    var primaryButtonTapped: Bool = false
    var secondaryButtonTapped: Bool = false
    var logOutButtonTapped: Bool = false
    var auxiliaryButtonTapped: Bool = false
    var showingActivityIndicator: Bool = false
    var primaryButtonHidden: Bool = false
    var primaryButtonLoading: Bool = false

    func viewDidLoad(_ viewController: UIViewController?) {
        viewLoaded = true
    }

    func didTapSecondaryButton(in viewController: UIViewController?) {
        secondaryButtonTapped = true
    }

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
