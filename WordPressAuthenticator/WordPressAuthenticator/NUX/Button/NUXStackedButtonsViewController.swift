import UIKit
import WordPressKit

struct StackedButton {
    enum StackView {
        case top
        case bottom
    }

    var stackView = StackView.top
    let title: String
    var isPrimary = false
    var configureBodyFontForTitle = false
    var accessibilityIdentifier: String? = nil
    let style: NUXButtonStyle?

    let onTap: NUXButtonConfig.CallBackType

    var config: NUXButtonConfig {
        NUXButtonConfig(title: title, isPrimary: isPrimary, configureBodyFontForTitle: configureBodyFontForTitle, accessibilityIdentifier: accessibilityIdentifier, callback: onTap)
    }
}

/// Used to create two stack views of NUXButtons optionally divided by a OR divider
///
/// Created as a replacement for NUXButtonViewController
///
open class NUXStackedButtonsViewController: UIViewController {
    // MARK: - Properties
    @IBOutlet private weak var buttonHolder: UIView?

    // Stack view
    @IBOutlet private var topStackView: UIStackView?
    @IBOutlet private var bottomStackView: UIStackView?

    // Divider line
    @IBOutlet private weak var leadingDividerLine: UIView!
    @IBOutlet private weak var leadingDividerLineHeight: NSLayoutConstraint!
    @IBOutlet private weak var dividerStackView: UIStackView!
    @IBOutlet private weak var dividerLabel: UILabel!
    @IBOutlet private weak var trailingDividerLine: UIView!
    @IBOutlet private weak var trailingDividerLineHeight: NSLayoutConstraint!

    // Shaow
    @IBOutlet private var shadowView: UIImageView?
    @IBOutlet private var shadowViewEdgeConstraints: [NSLayoutConstraint]!

    /// Used to constrain the shadow view outside of the
    /// bounds of this view controller.
    weak var shadowLayoutGuide: UILayoutGuide? {
        didSet {
            updateShadowViewEdgeConstraints()
        }
    }

    var backgroundColor: UIColor?
    private var showDivider = true
    private var buttons: [NUXButton] = []

    private let style = WordPressAuthenticator.shared.style

    private var buttonConfigs = [StackedButton]()

    // MARK: - View
    override open func viewDidLoad() {
        super.viewDidLoad()
        view.translatesAutoresizingMaskIntoConstraints = false

        shadowView?.image = style.buttonViewTopShadowImage
        configureDivider()
    }

    override open func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        reloadViews()

        buttonHolder?.backgroundColor = backgroundColor
    }

    // MARK: public API
    func setUpButtons(using config: [StackedButton], showDivider: Bool) {
        self.buttonConfigs = config
        self.showDivider = showDivider
        createButtons()
    }

    func hideShadowView() {
        shadowView?.isHidden = true
    }
}

// MARK: Helpers
//
private extension NUXStackedButtonsViewController {
    func reloadViews() {
        for (index, button) in buttons.enumerated() {
            button.configure(withConfig: buttonConfigs[index].config, and: buttonConfigs[index].style)
        }
        dividerStackView.isHidden = !showDivider
    }

    func createButtons() {
        buttons = []
        topStackView?.arrangedSubviews.forEach({ $0.removeFromSuperview() })
        bottomStackView?.arrangedSubviews.forEach({ $0.removeFromSuperview() })
        for config in buttonConfigs {
            let button = NUXButton()
            switch config.stackView {
            case .top:
                topStackView?.addArrangedSubview(button)
            case .bottom:
                bottomStackView?.addArrangedSubview(button)
            }
            button.configure(withConfig: config.config, and: config.style)
            buttons.append(button)
        }
    }

    func configureDivider() {
        guard showDivider else {
            return dividerStackView.isHidden = true
        }
        let color = WordPressAuthenticator.shared.unifiedStyle?.borderColor ?? WordPressAuthenticator.shared.style.primaryNormalBorderColor
        leadingDividerLine.backgroundColor = color
        leadingDividerLineHeight.constant = WPStyleGuide.hairlineBorderWidth
        trailingDividerLine.backgroundColor = color
        trailingDividerLineHeight.constant = WPStyleGuide.hairlineBorderWidth
        dividerLabel.textColor = color
        dividerLabel.text = NSLocalizedString("Or", comment: "Divider on initial auth view separating auth options.").localizedUppercase
    }

    func updateShadowViewEdgeConstraints() {
        guard let layoutGuide = shadowLayoutGuide,
              let shadowView = shadowView else {
            return
        }

        NSLayoutConstraint.deactivate(shadowViewEdgeConstraints)
        shadowView.translatesAutoresizingMaskIntoConstraints = false

        shadowViewEdgeConstraints = [
            layoutGuide.leadingAnchor.constraint(equalTo: shadowView.leadingAnchor),
            layoutGuide.trailingAnchor.constraint(equalTo: shadowView.trailingAnchor),
        ]

        NSLayoutConstraint.activate(shadowViewEdgeConstraints)
    }

    // MARK: - Dynamic type
    func didChangePreferredContentSize() {
        reloadViews()
    }
}

extension NUXStackedButtonsViewController {
    override open func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if previousTraitCollection?.preferredContentSizeCategory != traitCollection.preferredContentSizeCategory {
            didChangePreferredContentSize()
        }
    }
}

extension NUXStackedButtonsViewController {

    /// Sets the parentViewControlleras the receiver instance's container. Plus: the containerView will also get the receiver's
    /// view, attached to it's edges. This is effectively analog to using an Embed Segue with the NUXButtonViewController.
    ///
    public func move(to parentViewController: UIViewController, into containerView: UIView) {
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(view)
        containerView.pinSubviewToAllEdges(view)

        willMove(toParent: parentViewController)
        parentViewController.addChild(self)
        didMove(toParent: parentViewController)
    }

    /// Returns a new NUXButtonViewController Instance
    ///
    public class func instance() -> NUXStackedButtonsViewController {
        let storyboard = UIStoryboard(name: "NUXButtonView", bundle: WordPressAuthenticator.bundle)
        guard let buttonViewController = storyboard.instantiateViewController(withIdentifier: "NUXStackedButtonsViewController") as? NUXStackedButtonsViewController else {
            fatalError()
        }

        return buttonViewController
    }
}

private extension NUXButton {
    func configure(withConfig buttonConfig: NUXButtonConfig?, and style: NUXButtonStyle?) {
        guard let buttonConfig = buttonConfig else {
            isHidden = true
            return
        }

        if let attributedTitle = buttonConfig.attributedTitle {
            setAttributedTitle(attributedTitle, for: .normal)
            socialService = buttonConfig.socialService
        } else {
            setTitle(buttonConfig.title, for: .normal)
        }

        accessibilityIdentifier = buttonConfig.accessibilityIdentifier ?? "\(buttonConfig.title ?? "") Button"
        isPrimary = buttonConfig.isPrimary

        if buttonConfig.configureBodyFontForTitle == true {
            customizeFont(WPStyleGuide.mediumWeightFont(forStyle: .body))
        }

        buttonStyle = style

        isHidden = false
    }
}
