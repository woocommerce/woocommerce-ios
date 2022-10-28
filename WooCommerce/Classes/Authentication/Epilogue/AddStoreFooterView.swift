import UIKit

/// Displays the "Add a Store" button at the bottom of the store picker for simplified login
///
final class AddStoreFooterView: UIView {

    private let addStoreHandler: () -> Void

    private lazy var addStoreButton = UIButton(type: .custom)
    private lazy var divider: UIView = {
        let view = UIView(frame: .zero)
        view.backgroundColor = .border
        return view
    }()

    init(addStoreHandler: @escaping () -> Void) {
        self.addStoreHandler = addStoreHandler
        super.init(frame: .zero)
        configureSubviews()
        configureAddStoreButton()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureSubviews() {
        addStoreButton.translatesAutoresizingMaskIntoConstraints = false
        addSubview(addStoreButton)

        divider.translatesAutoresizingMaskIntoConstraints = false
        addSubview(divider)

        NSLayoutConstraint.activate([
            addStoreButton.leadingAnchor.constraint(equalTo: leadingAnchor),
            trailingAnchor.constraint(equalTo: addStoreButton.trailingAnchor),
            addStoreButton.topAnchor.constraint(equalTo: topAnchor),
            bottomAnchor.constraint(equalTo: addStoreButton.bottomAnchor),
            divider.leadingAnchor.constraint(equalTo: leadingAnchor),
            divider.trailingAnchor.constraint(equalTo: trailingAnchor),
            divider.bottomAnchor.constraint(equalTo: bottomAnchor),
            divider.heightAnchor.constraint(equalToConstant: 1.0 / UIScreen.main.scale)
        ])
    }

    private func configureAddStoreButton() {
        addStoreButton.setTitle(Localization.addStoreButton, for: .normal)
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

        addStoreButton.addAction(UIAction { [weak self] _ in
            self?.addStoreHandler()
        }, for: .touchUpInside)
    }
}

private extension AddStoreFooterView {
    enum Localization {
        static let addStoreButton = NSLocalizedString("Add a Store", comment: "Button title on the store picker for store creation")
    }

    enum Constants {
        static let horizontalPadding: CGFloat = 24
        static let verticalPadding: CGFloat = 16
    }
}
