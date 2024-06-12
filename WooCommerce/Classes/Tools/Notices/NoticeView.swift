import UIKit


/// NoticeView: Renders a Notice onScreen!
///
class NoticeView: UIView {
    private let contentStackView = UIStackView()

    private let backgroundContainerView = UIView()
    private let backgroundView: UIVisualEffectView
    private let shadowLayer = CAShapeLayer()
    private let shadowMaskLayer = CAShapeLayer()

    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let messageLabel = UILabel()
    private let actionButton = UIButton(type: .system)

    private let notice: Notice

    var dismissHandler: (() -> Void)?

    override var bounds: CGRect {
        didSet {
            updateShadowPath()
        }
    }


    /// Designated Initializer
    ///
    init(notice: Notice) {
        self.notice = notice

        self.backgroundView = UIVisualEffectView(effect: UIBlurEffect(style: .systemThickMaterial))

        super.init(frame: .zero)

        configureBackgroundViews()
        configureShadow()
        configureContentStackView()
        configureLabels()
        configureActionButton()
        configureDismissRecognizer()

        configureForNotice()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}


// MARK: - Setup Methods
//
private extension NoticeView {

    func configureBackgroundViews() {
        addSubview(backgroundContainerView)
        backgroundContainerView.translatesAutoresizingMaskIntoConstraints = false
        pinSubviewToAllEdges(backgroundContainerView)

        backgroundContainerView.addSubview(backgroundView)
        backgroundView.translatesAutoresizingMaskIntoConstraints = false
        pinSubviewToAllEdges(backgroundView)

        backgroundContainerView.layer.cornerRadius = Metrics.cornerRadius
        backgroundContainerView.layer.masksToBounds = true
    }

    func configureShadow() {
        shadowLayer.shadowPath = UIBezierPath(roundedRect: layer.bounds, cornerRadius: Metrics.cornerRadius).cgPath
        shadowLayer.shadowColor = Appearance.shadowColor.cgColor
        shadowLayer.shadowOpacity = Appearance.shadowOpacity
        shadowLayer.shadowRadius = Appearance.shadowRadius
        shadowLayer.shadowOffset = Appearance.shadowOffset
        layer.insertSublayer(shadowLayer, at: 0)

        shadowMaskLayer.fillRule = .evenOdd
        shadowLayer.mask = shadowMaskLayer

        updateShadowPath()
    }

    func updateShadowPath() {
        let shadowPath = UIBezierPath(roundedRect: bounds, cornerRadius: Metrics.cornerRadius).cgPath
        shadowLayer.shadowPath = shadowPath

        // Construct a mask path with the notice's roundrect cut out of a larger padding rect.
        // This, combined with the `kCAFillRuleEvenOdd` gives us an inverted mask, so
        // the shadow only appears _outside_ of the notice roundrect, and doesn't appear underneath
        // and obscure the blur visual effect view.
        let maskPath = CGMutablePath()
        let leftInset = Metrics.layoutMargins.left * 2
        let topInset = Metrics.layoutMargins.top * 2
        maskPath.addRect(bounds.insetBy(dx: -leftInset, dy: -topInset))
        maskPath.addPath(shadowPath)
        shadowMaskLayer.path = maskPath
    }

    func configureContentStackView() {
        contentStackView.axis = .horizontal
        contentStackView.translatesAutoresizingMaskIntoConstraints = false
        backgroundView.contentView.addSubview(contentStackView)
        backgroundView.contentView.pinSubviewToAllEdges(contentStackView)
    }

    func configureLabels() {
        let labelStackView = UIStackView()
        labelStackView.translatesAutoresizingMaskIntoConstraints = false
        labelStackView.alignment = .leading
        labelStackView.axis = .vertical
        labelStackView.spacing = Metrics.labelLineSpacing
        labelStackView.isBaselineRelativeArrangement = true
        labelStackView.isLayoutMarginsRelativeArrangement = true
        labelStackView.layoutMargins = Metrics.layoutMargins

        labelStackView.addArrangedSubview(titleLabel)
        labelStackView.addArrangedSubview(subtitleLabel)
        labelStackView.addArrangedSubview(messageLabel)

        contentStackView.addArrangedSubview(labelStackView)

        NSLayoutConstraint.activate([
            labelStackView.topAnchor.constraint(equalTo: backgroundView.contentView.topAnchor),
            labelStackView.bottomAnchor.constraint(equalTo: backgroundView.contentView.bottomAnchor)
            ])

        titleLabel.font = Fonts.titleLabelFont
        subtitleLabel.font = Fonts.subtitleLabelFont
        messageLabel.font = Fonts.messageLabelFont

        titleLabel.textColor = Appearance.titleColor
        subtitleLabel.textColor = Appearance.titleColor
        messageLabel.textColor = Appearance.titleColor
    }

    func configureActionButton() {
        contentStackView.addArrangedSubview(actionButton)

        NSLayoutConstraint.activate([
            actionButton.topAnchor.constraint(equalTo: backgroundView.contentView.topAnchor),
            actionButton.bottomAnchor.constraint(equalTo: backgroundView.contentView.bottomAnchor),
            ])

        actionButton.titleLabel?.font = Fonts.actionButtonFont
        actionButton.setTitleColor(Appearance.actionColor, for: .normal)
        actionButton.addTarget(self, action: #selector(actionButtonTapped), for: .touchUpInside)
        actionButton.setContentCompressionResistancePriority(.required, for: .horizontal)
        var configuration = UIButton.Configuration.plain()
        configuration.contentInsets = Metrics.actionButtonContentInsets
        actionButton.configuration = configuration
        actionButton.backgroundColor = Appearance.actionBackgroundColor
    }

    func configureDismissRecognizer() {
        let recognizer = UITapGestureRecognizer(target: self, action: #selector(viewTapped))
        addGestureRecognizer(recognizer)

        let swipeRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(viewSwiped))
        swipeRecognizer.direction = .down
        addGestureRecognizer(swipeRecognizer)
    }

    func configureForNotice() {
        titleLabel.text = notice.title

        if let subtitle = notice.subtitle {
            subtitleLabel.isHidden = false
            subtitleLabel.text = subtitle
        } else {
            subtitleLabel.isHidden = true
        }

        if let message = notice.message {
            messageLabel.text = message
            messageLabel.numberOfLines = 0
        } else {
            titleLabel.numberOfLines = 2
        }

        if let actionTitle = notice.actionTitle {
            actionButton.setTitle(actionTitle, for: .normal)
            actionButton.isHidden = false
        } else {
            actionButton.isHidden = true
        }
    }
}


// MARK: - Action handlers
//
private extension NoticeView {

    @objc private func viewTapped() {
        dismissHandler?()
    }

    @objc func viewSwiped() {
        dismissHandler?()
    }

    @objc private func actionButtonTapped() {
        notice.actionHandler?()
        dismissHandler?()
    }
}


// MARK: - Nested Types
//
private extension NoticeView {

    enum Metrics {
        static let cornerRadius: CGFloat = 13.0
        static let layoutMargins = UIEdgeInsets(top: 16.0, left: 16.0, bottom: 16.0, right: 16.0)
        static let actionButtonContentInsets = NSDirectionalEdgeInsets(top: 22.0, leading: 16.0, bottom: 22.0, trailing: 16.0)
        static let labelLineSpacing: CGFloat = 18.0
    }

    enum Fonts {
        static let actionButtonFont = UIFont.systemFont(ofSize: 14.0)
        static let titleLabelFont = UIFont.boldSystemFont(ofSize: 14.0)
        static let subtitleLabelFont = UIFont.boldSystemFont(ofSize: 14.0)
        static let messageLabelFont = UIFont.systemFont(ofSize: 14.0)
    }

    enum Appearance {
        static let actionBackgroundColor = UIColor.systemColor(.secondarySystemGroupedBackground)
        static let actionColor: UIColor = .primaryButtonBackground
        static let shadowColor: UIColor = .black
        static let shadowOpacity: Float = 0.2
        static let shadowRadius: CGFloat = 8.0
        static let shadowOffset = CGSize(width: 0.0, height: 2.0)
        static let titleColor: UIColor = .text
    }
}
