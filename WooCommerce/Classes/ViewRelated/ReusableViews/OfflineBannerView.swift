import UIKit

/// Gray banner showing message when device is offline.
///
final class OfflineBannerView: UIView {

    static let height: CGFloat = 44

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 3
        stackView.distribution = .fillProportionally
        stackView.alignment = .center
        stackView.translatesAutoresizingMaskIntoConstraints = false

        let imageView = UIImageView(image: .lightningImage)
        imageView.tintColor = .white
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            imageView.widthAnchor.constraint(equalToConstant: 24),
            imageView.heightAnchor.constraint(equalToConstant: 24)
        ])

        let messageLabel = UILabel()
        messageLabel.text = NSLocalizedString("Offline - using cached data", comment: "Message for offline banner")
        messageLabel.applyCalloutStyle()
        messageLabel.textColor = .white
        messageLabel.translatesAutoresizingMaskIntoConstraints = false

        stackView.addArrangedSubview(imageView)
        stackView.addArrangedSubview(messageLabel)

        addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.safeLeadingAnchor.constraint(greaterThanOrEqualTo: safeLeadingAnchor, constant: 0),
            stackView.safeBottomAnchor.constraint(greaterThanOrEqualTo: safeBottomAnchor, constant: 0),
            stackView.centerXAnchor.constraint(equalTo: centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }
}
