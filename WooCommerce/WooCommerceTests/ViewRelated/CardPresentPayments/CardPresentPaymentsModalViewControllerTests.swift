import XCTest
@testable import WooCommerce

final class CardPresentPaymentsModalViewControllerTests: XCTestCase {
    @MainActor
    override func setUp() async throws {
        try await super.setUp()
        // The NUX buttons require WordPressAuthenticator to be initialized
        AuthenticationManager().initialize()
    }

    @MainActor
    func test_viewcontroller_presents_top_title_provided_by_viewmodel() throws {
        let viewModel = ModalViewModel(textMode: .fullInfo, actionsMode: .none)
        let viewController = CardPresentPaymentsModalViewController(viewModel: viewModel)

        _ = try XCTUnwrap(viewController.view)

        XCTAssertEqual(viewController.getTopTitleLabel().text, viewModel.topTitle)
    }

    @MainActor
    func test_viewcontroller_presents_top_subtitle_provided_by_viewmodel() throws {
        let viewModel = ModalViewModel(textMode: .fullInfo, actionsMode: .none)
        let viewController = CardPresentPaymentsModalViewController(viewModel: viewModel)

        _ = try XCTUnwrap(viewController.view)

        XCTAssertEqual(viewController.getTopSubtitleLabel().text, viewModel.topSubtitle)
    }

    @MainActor
    func test_viewcontroller_presents_image_provided_by_viewmodel() throws {
        let viewModel = ModalViewModel(textMode: .fullInfo, actionsMode: .none)
        let viewController = CardPresentPaymentsModalViewController(viewModel: viewModel)

        _ = try XCTUnwrap(viewController.view)
        let image = viewController.getImageView().image

        XCTAssertEqual(image, viewModel.image)
    }

    @MainActor
    func test_viewcontroller_presents_bottom_title_provided_by_viewmodel() throws {
        let viewModel = ModalViewModel(textMode: .fullInfo, actionsMode: .none)
        let viewController = CardPresentPaymentsModalViewController(viewModel: viewModel)

        _ = try XCTUnwrap(viewController.view)

        XCTAssertEqual(viewController.getBottomTitleLabel().text, viewModel.bottomTitle)
    }

    @MainActor
    func test_viewcontroller_presents_bottom_subtitle_provided_by_viewmodel() throws {
        let viewModel = ModalViewModel(textMode: .fullInfo, actionsMode: .none)
        let viewController = CardPresentPaymentsModalViewController(viewModel: viewModel)

        _ = try XCTUnwrap(viewController.view)

        XCTAssertEqual(viewController.getBottomSubtitleLabel().text, viewModel.bottomSubtitle)
    }

    @MainActor
    func test_viewcontroller_propagates_tap_in_primary_button_to_viewmodel() throws {
        let viewModel = ModalViewModel(textMode: .fullInfo, actionsMode: .oneAction)
        let viewController = CardPresentPaymentsModalViewController(viewModel: viewModel)

        _ = try XCTUnwrap(viewController.view)

        let primaryButton = viewController.getPrimaryActionButton()
        primaryButton.sendActions(for: .touchUpInside)

        XCTAssertTrue(viewModel.primaryButtonTapped)
    }

    @MainActor
    func test_viewcontroller_propagates_tap_in_primary_button_to_viewmodel_in_oneaction_mode() throws {
        let viewModel = ModalViewModel(textMode: .fullInfo, actionsMode: .oneAction)
        let viewController = CardPresentPaymentsModalViewController(viewModel: viewModel)

        _ = try XCTUnwrap(viewController.view)

        let primaryButton = viewController.getPrimaryActionButton()
        primaryButton.sendActions(for: .touchUpInside)

        XCTAssertTrue(viewModel.primaryButtonTapped)
    }

    @MainActor
    func test_viewcontroller_propagates_tap_in_primary_button_to_viewmodel_in_reducedInfo_mode() throws {
        let viewModel = ModalViewModel(textMode: .reducedTopInfo, actionsMode: .oneAction)
        let viewController = CardPresentPaymentsModalViewController(viewModel: viewModel)

        _ = try XCTUnwrap(viewController.view)

        let primaryButton = viewController.getPrimaryActionButton()
        primaryButton.sendActions(for: .touchUpInside)

        XCTAssertTrue(viewModel.primaryButtonTapped)
    }

    @MainActor
    func test_viewcontroller_propagates_tap_in_secondary_button_to_viewmodel() throws {
        let viewModel = ModalViewModel(textMode: .reducedTopInfo, actionsMode: .twoAction)
        let viewController = CardPresentPaymentsModalViewController(viewModel: viewModel)

        _ = try XCTUnwrap(viewController.view)

        let secondaryButton = viewController.getSecondaryActionButton()
        secondaryButton.sendActions(for: .touchUpInside)

        XCTAssertTrue(viewModel.secondaryButtonTapped)
    }

    @MainActor
    func test_viewcontroller_hides_bottom_subtitle_label_in_reduced_bottom_info_mode() throws {
        let viewModel = ModalViewModel(textMode: .reducedBottomInfo, actionsMode: .none)
        let viewController = CardPresentPaymentsModalViewController(viewModel: viewModel)

        _ = try XCTUnwrap(viewController.view)

        let bottomSubtitleLabel = viewController.getBottomSubtitleLabel()

        XCTAssertTrue(bottomSubtitleLabel.isHidden)
    }

    @MainActor
    func test_viewcontroller_shows_primary_action_button_in_one_action_mode() throws {
        let viewModel = ModalViewModel(textMode: .reducedBottomInfo, actionsMode: .oneAction)
        let viewController = CardPresentPaymentsModalViewController(viewModel: viewModel)

        _ = try XCTUnwrap(viewController.view)

        let primaryButton = viewController.getPrimaryActionButton()

        XCTAssertFalse(primaryButton.isHidden)
    }

    @MainActor
    func test_viewcontroller_hides_primary_action_button_in_secondary_only_action_mode() throws {
        let viewModel = ModalViewModel(textMode: .reducedBottomInfo, actionsMode: .secondaryOnlyAction)
        let viewController = CardPresentPaymentsModalViewController(viewModel: viewModel)

        _ = try XCTUnwrap(viewController.view)

        let primaryButton = viewController.getPrimaryActionButton()

        XCTAssertTrue(primaryButton.isHidden)
    }

    @MainActor
    func test_viewcontroller_shows_primary_action_button_in_two_action_mode() throws {
        let viewModel = ModalViewModel(textMode: .reducedBottomInfo, actionsMode: .twoAction)
        let viewController = CardPresentPaymentsModalViewController(viewModel: viewModel)

        _ = try XCTUnwrap(viewController.view)

        let primaryButton = viewController.getPrimaryActionButton()

        XCTAssertFalse(primaryButton.isHidden)
    }

    @MainActor
    func test_viewcontroller_shows_primary_action_button_in_two_action_and_auxiliary_mode() throws {
        let viewModel = ModalViewModel(textMode: .reducedBottomInfo, actionsMode: .twoActionAndAuxiliary)
        let viewController = CardPresentPaymentsModalViewController(viewModel: viewModel)

        _ = try XCTUnwrap(viewController.view)

        let primaryButton = viewController.getPrimaryActionButton()

        XCTAssertFalse(primaryButton.isHidden)
    }

    @MainActor
    func test_viewcontroller_hides_secondary_action_button_in_one_action_mode() throws {
        let viewModel = ModalViewModel(textMode: .reducedBottomInfo, actionsMode: .oneAction)
        let viewController = CardPresentPaymentsModalViewController(viewModel: viewModel)

        _ = try XCTUnwrap(viewController.view)

        let secondaryButton = viewController.getSecondaryActionButton()

        XCTAssertTrue(secondaryButton.isHidden)
    }

    @MainActor
    func test_viewcontroller_shows_secondary_action_button_in_secondary_only_action_mode() throws {
        let viewModel = ModalViewModel(textMode: .reducedBottomInfo, actionsMode: .secondaryOnlyAction)
        let viewController = CardPresentPaymentsModalViewController(viewModel: viewModel)

        _ = try XCTUnwrap(viewController.view)

        let secondaryButton = viewController.getSecondaryActionButton()

        XCTAssertFalse(secondaryButton.isHidden)
    }

    @MainActor
    func test_viewcontroller_shows_secondary_action_button_in_two_action_mode() throws {
        let viewModel = ModalViewModel(textMode: .reducedBottomInfo, actionsMode: .twoAction)
        let viewController = CardPresentPaymentsModalViewController(viewModel: viewModel)

        _ = try XCTUnwrap(viewController.view)

        let secondaryButton = viewController.getSecondaryActionButton()

        XCTAssertFalse(secondaryButton.isHidden)
    }

    @MainActor
    func test_viewcontroller_shows_secondary_action_button_in_two_action_and_auxiliary_mode() throws {
        let viewModel = ModalViewModel(textMode: .reducedBottomInfo, actionsMode: .twoActionAndAuxiliary)
        let viewController = CardPresentPaymentsModalViewController(viewModel: viewModel)

        _ = try XCTUnwrap(viewController.view)

        let secondaryButton = viewController.getSecondaryActionButton()

        XCTAssertFalse(secondaryButton.isHidden)
    }

    @MainActor
    func test_setViewModel_when_first_view_model_hides_top_subtitle_then_top_subtitle_uses_title_font() throws {
        // Given
        let viewController = CardPresentPaymentsModalViewController(viewModel: ModalViewModel(textMode: .reducedTopInfo, actionsMode: .none))
        _ = try XCTUnwrap(viewController.view)

        // When
        viewController.setViewModel(ModalViewModel(textMode: .fullInfo, actionsMode: .none))

        // Then
        XCTAssertEqual(viewController.getTopSubtitleLabel().font, .title1)
    }

    @MainActor
    func test_setViewModel_when_first_view_model_hides_bottom_labels_then_bottom_labels_use_their_fonts() throws {
        // Given
        let viewController = CardPresentPaymentsModalViewController(viewModel: ModalViewModel(textMode: .noBottomInfo, actionsMode: .oneAction))
        _ = try XCTUnwrap(viewController.view)

        // When
        viewController.setViewModel(ModalViewModel(textMode: .fullInfo, actionsMode: .none))

        // Then
        XCTAssertEqual(viewController.getBottomTitleLabel().font, .subheadline)
        XCTAssertEqual(viewController.getBottomSubtitleLabel().font, .footnote)
    }
}


private final class ModalViewModel: CardPresentPaymentsModalViewModel {
    let textMode: PaymentsModalTextMode
    let actionsMode: PaymentsModalActionsMode

    /// The title at the top of the modal view.
    let topTitle: String = "top_title"

    /// The second line of text of the modal view. Right over the illustration
    let topSubtitle: String? = "top_subtitle"

    /// An illustration accompanying the modal
    let image: UIImage = .loginNoJetpackError

    /// Provides a title for a primary action button
    let primaryButtonTitle: String? = "primary_button_title"

    /// Provides a title for a secondary action button
    let secondaryButtonTitle: String? = "secondary_button_title"

    /// Provides a title for an auxiliary action button
    let auxiliaryButtonTitle: String? = "auxiliary_button_title"

    /// The title in the bottom section of the modal. Right below the image
    let bottomTitle: String? = "bottom_title"

    /// The subtitle in the bottom section of the modal. Right below the image
    let bottomSubtitle: String? = "bottom_subtitle"

    /// Flag indicating that the primary button has been tapped
    var primaryButtonTapped: Bool = false

    /// Flag indicating that the secondary button has been tapped
    var secondaryButtonTapped: Bool = false

    /// Flag indicating that the auxiliary button has been tapped
    var auxiliaryButtonTapped: Bool = false

    /// The accessibilityLabel to be provided to VoiceOver
    let accessibilityLabel: String? = "accessibility_label"

    init(textMode: PaymentsModalTextMode, actionsMode: PaymentsModalActionsMode) {
        self.textMode = textMode
        self.actionsMode = actionsMode
    }

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
