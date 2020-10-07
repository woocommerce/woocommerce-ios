import UIKit
import Lottie
import WordPressShared


class LoginProloguePromoViewController: UIViewController {
    fileprivate let type: PromoType
    fileprivate let stackView: UIStackView
    fileprivate let headingLabel: UILabel
    fileprivate let animationHolder: UIView
    fileprivate var animationView: AnimationView

    fileprivate struct Constants {
        static let stackSpacing: CGFloat = 36.0
        static let stackHeightMultiplier: CGFloat = 0.87
        static let stackWidthMultiplier: CGFloat = 0.8
        static let labelMinHeight: CGFloat = 21.0
        static let labelMaxWidth: CGFloat = 600.0
        static let animationWidthHeightRatio: CGFloat = 0.6667
    }

    enum PromoType: String {
        case post
        case stats
        case reader
        case notifications
        case jetpack
        // new prologue carousel
        case intro
        case editor
        case comments
        case analytics
        case discover

        var animationKey: String {
            return rawValue
        }

        var headlineText: String {
            switch self {
            case .post:
                return NSLocalizedString("Publish from the park. Blog from the bus. Comment from the café. WordPress goes where you do.", comment: "shown in promotional screens during first launch")
            case .stats:
                return NSLocalizedString("Watch readers from around the world read and interact with your site — in real time.", comment: "shown in promotional screens during first launch")
            case .reader:
                return NSLocalizedString("Catch up with your favorite sites and join the conversation anywhere, any time.", comment: "shown in promotional screens during first launch")
            case .notifications:
                return NSLocalizedString("Your notifications travel with you — see comments and likes as they happen.", comment: "shown in promotional screens during first launch")
            case .jetpack:
                return NSLocalizedString("Manage your Jetpack-powered site on the go — you've got WordPress in your pocket.", comment: "shown in promotional screens during first launch")
            // new prologue carousel
            case .intro:
                return NSLocalizedString("Welcome to the world’s most popular website builder.", comment: "Shown in the prologue carousel (promotional screens) during first launch.")
            case .editor:
                return NSLocalizedString("With this powerful editor you can post on the go.", comment: "Shown in the prologue carousel (promotional screens) during first launch.")
            case .comments:
                return NSLocalizedString("See comments and notifications in real time.", comment: "Shown in the prologue carousel (promotional screens) during first launch.")
            case .analytics:
                return NSLocalizedString("Watch your audience grow with in-depth analytics.", comment: "Shown in the prologue carousel (promotional screens) during first launch.")
            case .discover:
                return NSLocalizedString("Follow your favourite sites and discover new reads.", comment: "Shown in the prologue carousel (promotional screens) during first launch.")
            }
        }

        var headlineColor: UIColor {
            if WordPressAuthenticator.shared.configuration.enableUnifiedCarousel {
                return WordPressAuthenticator.shared.unifiedStyle?.textColor ?? WordPressAuthenticator.shared.style.secondaryTitleColor
            }

            return WordPressAuthenticator.shared.style.prologueTitleColor
        }
    }

    init(as promoType: PromoType) {
        type = promoType
        stackView = UIStackView()
        headingLabel = UILabel()
        animationHolder = UIView()

        let bundle = WordPressAuthenticator.bundle
        animationView = AnimationView(name: type.animationKey, bundle: bundle)

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupBackground()

        if WordPressAuthenticator.shared.configuration.enableUnifiedCarousel {
            styleHeadingLabel()
        } else {
            setupHeadingLabel()
        }

        setupLayout()
    }

    private func setupBackground() {
        view.backgroundColor = UIColor.clear
    }

    private func styleHeadingLabel() {
        headingLabel.font = WPStyleGuide.serifFontForTextStyle(.title1)
        headingLabel.textColor = type.headlineColor
        headingLabel.text = type.headlineText
        headingLabel.textAlignment = .center
        headingLabel.numberOfLines = 0
        headingLabel.adjustsFontSizeToFitWidth = true
        headingLabel.sizeToFit()
    }

    private func setupHeadingLabel() {
        headingLabel.font = WPStyleGuide.mediumWeightFont(forStyle: .title3)
        headingLabel.textColor = type.headlineColor
        headingLabel.text = type.headlineText
        headingLabel.textAlignment = .center
        headingLabel.numberOfLines = 0
        headingLabel.adjustsFontSizeToFitWidth = true
        headingLabel.sizeToFit()
    }

    private func didChangePreferredContentSize() {
        setupHeadingLabel()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        animationView.currentProgress = 0.0
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        animationView.play()
    }


    // MARK: layout

    private func setupLayout() {
        view.addSubview(stackView)
        stackView.addArrangedSubview(headingLabel)
        stackView.addArrangedSubview(animationHolder)
        animationHolder.addSubview(animationView)

        stackView.axis = .vertical
        stackView.spacing = Constants.stackSpacing
        stackView.alignment = .center
        stackView.distribution = .fill
        stackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stackView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            stackView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: Constants.stackWidthMultiplier),
            stackView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: Constants.stackHeightMultiplier)
        ])

        headingLabel.setContentHuggingPriority(.defaultLow, for: .vertical)
        headingLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        headingLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            headingLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: Constants.labelMinHeight),
            headingLabel.widthAnchor.constraint(lessThanOrEqualToConstant: Constants.labelMaxWidth)
        ])

        animationHolder.setContentHuggingPriority(.defaultLow, for: .vertical)
        animationHolder.setContentCompressionResistancePriority(.defaultHigh, for: .vertical)
        animationHolder.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            animationHolder.widthAnchor.constraint(greaterThanOrEqualTo: animationHolder.heightAnchor, multiplier: Constants.animationWidthHeightRatio)
        ])

        animationView.contentMode = .scaleAspectFit
        animationView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            animationView.leadingAnchor.constraint(equalTo: animationHolder.leadingAnchor),
            animationView.trailingAnchor.constraint(equalTo: animationHolder.trailingAnchor),
            animationView.topAnchor.constraint(equalTo: animationHolder.topAnchor),
            animationView.bottomAnchor.constraint(equalTo: animationHolder.bottomAnchor)
        ])
    }
}

extension LoginProloguePromoViewController {
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if previousTraitCollection?.preferredContentSizeCategory != traitCollection.preferredContentSizeCategory {
            didChangePreferredContentSize()
        }
    }
}
