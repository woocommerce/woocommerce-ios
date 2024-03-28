import UIKit

/// Displays the "Add a Store" button at the bottom of the store picker for simplified login
///
final class AddStoreFooterView: UIView {

    private let addStoreHandler: () -> Void

    private lazy var addStoreButton = UIButton(type: .custom)

    init(addStoreHandler: @escaping () -> Void) {
        self.addStoreHandler = addStoreHandler
        super.init(frame: .zero)
        configureAddStoreButton()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureAddStoreButton() {
        addStoreButton.translatesAutoresizingMaskIntoConstraints = false
        addSubview(addStoreButton)
        addStoreButton.setTitle(Localization.connectExistingStoreButton, for: .normal)
        addStoreButton.applyLinkButtonStyle()
        addStoreButton.contentHorizontalAlignment = .leading

        var configuration = UIButton.Configuration.borderless()
        configuration.image = .plusImage
        configuration.imagePadding = 8
        configuration.contentInsets = .init(top: Constants.verticalPadding,
                                            leading: Constants.horizontalPadding,
                                            bottom: Constants.verticalPadding,
                                            trailing: Constants.horizontalPadding)
        addStoreButton.configuration = configuration

        NSLayoutConstraint.activate([
            addStoreButton.leadingAnchor.constraint(equalTo: leadingAnchor),
            trailingAnchor.constraint(equalTo: addStoreButton.trailingAnchor),
            addStoreButton.topAnchor.constraint(equalTo: topAnchor),
            bottomAnchor.constraint(equalTo: addStoreButton.bottomAnchor),
        ])

        addStoreButton.addAction(UIAction { [weak self] _ in
            self?.addStoreHandler()
        }, for: .touchUpInside)
    }
}

private extension AddStoreFooterView {
    enum Localization {
        static let connectExistingStoreButton = NSLocalizedString(
            "addStoreFooterView.connectExistingStoreButton",
            value: "Connect existing store",
            comment: "Button title on the store picker for store connection")
    }

    enum Constants {
        static let horizontalPadding: CGFloat = 24
        static let verticalPadding: CGFloat = 16
    }
}
