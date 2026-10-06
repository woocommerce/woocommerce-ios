import UIKit

final class ListEmptyView: UIView {
    private let imageView = UIImageView()
    private let messageLabel = UILabel()
    private let detailsLabel = UILabel()
    private let actionButton = UIButton(type: .system)
    private var onAction: ((UIButton) -> Void)?

    init() {
        super.init(frame: .zero)

        backgroundColor = .listBackground
        imageView.contentMode = .scaleAspectFit
        messageLabel.applySecondaryTitleStyle()
        messageLabel.numberOfLines = 0
        messageLabel.textAlignment = .center
        detailsLabel.applySecondaryBodyStyle()
        detailsLabel.numberOfLines = 0
        detailsLabel.textAlignment = .center
        actionButton.applyPrimaryButtonStyle()
        actionButton.addTarget(self, action: #selector(actionButtonTapped), for: .touchUpInside)

        let stackView = UIStackView(arrangedSubviews: [imageView, messageLabel, detailsLabel, actionButton])
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.spacing = 4
        stackView.setCustomSpacing(48, after: imageView)
        stackView.setCustomSpacing(24, after: detailsLabel)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stackView)

        let buttonWidth = actionButton.widthAnchor.constraint(equalToConstant: 228)
        buttonWidth.priority = .defaultHigh
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 58),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -58),
            stackView.centerYAnchor.constraint(equalTo: centerYAnchor),
            stackView.topAnchor.constraint(greaterThanOrEqualTo: topAnchor, constant: 8),
            stackView.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -8),
            actionButton.widthAnchor.constraint(lessThanOrEqualTo: stackView.widthAnchor),
            buttonWidth
        ])

        registerForTraitChanges([UITraitVerticalSizeClass.self]) { (view: ListEmptyView, _: UITraitCollection) in
            view.updateImageVisibility()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("Not supported")
    }

    func configure(message: NSAttributedString, image: UIImage, details: String?, buttonTitle: String, onAction: @escaping (UIButton) -> Void) {
        messageLabel.attributedText = message
        imageView.image = image
        detailsLabel.text = details
        detailsLabel.isHidden = details == nil
        actionButton.setTitle(buttonTitle, for: .normal)
        self.onAction = onAction
        updateImageVisibility()
    }

    func show(in tableView: UITableView) {
        guard tableView.tableFooterView !== self else {
            updateHeight(in: tableView)
            return
        }

        // Resolve the initial layout before insertion without inheriting the table's transition animation.
        UIView.performWithoutAnimation {
            frame.size = fittedSize(in: tableView)
            layoutIfNeeded()
            tableView.tableFooterView = self
        }
    }

    /// Fill the visible table area, while allowing larger content to scroll.
    func updateHeight(in tableView: UITableView) {
        guard tableView.tableFooterView === self else { return }
        let size = fittedSize(in: tableView)
        guard frame.size != size else { return }
        UIView.performWithoutAnimation {
            frame.size = size
            layoutIfNeeded()
            tableView.tableFooterView = self
        }
    }

    private func fittedSize(in tableView: UITableView) -> CGSize {
        let width = tableView.bounds.width
        let fittingSize = systemLayoutSizeFitting(CGSize(width: width, height: 0),
                                                  withHorizontalFittingPriority: .required,
                                                  verticalFittingPriority: .fittingSizeLevel)
        let availableHeight = tableView.bounds.height - tableView.adjustedContentInset.top - tableView.adjustedContentInset.bottom
            - (tableView.tableHeaderView?.frame.height ?? 0)
        return CGSize(width: width, height: max(fittingSize.height, availableHeight))
    }

    private func updateImageVisibility() {
        imageView.isHidden = traitCollection.verticalSizeClass == .compact
    }

    @objc private func actionButtonTapped() {
        onAction?(actionButton)
    }
}
