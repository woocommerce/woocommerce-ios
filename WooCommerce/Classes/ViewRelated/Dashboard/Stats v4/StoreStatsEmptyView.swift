import Experiments
import UIKit

final class StoreStatsEmptyView: UIView {
    /// Whether the Jetpack image is shown to indicate the data are unavailable due to Jetpack-the-plugin.
    var showJetpackImage: Bool = false {
        didSet {
            updateJetpackImageVisibility()
        }
    }

    /// Whether to show information icon
    var showInfoIcon: Bool = false {
        didSet {
            updateInfoIconVisibility()
        }
    }

    private lazy var jetpackImageView = UIImageView(image: .jetpackLogoImage.withRenderingMode(.alwaysTemplate))

    private lazy var infoIconImageView = UIImageView(image: .infoOutlineImage.withRenderingMode(.alwaysTemplate))

    convenience init() {
        self.init(frame: .zero)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupSubviews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupSubviews() {
        translatesAutoresizingMaskIntoConstraints = false

        let emptyView = UIView(frame: .zero)
        emptyView.backgroundColor = .systemColor(.secondarySystemBackground)
        emptyView.layer.cornerRadius = 2.0
        emptyView.translatesAutoresizingMaskIntoConstraints = false

        jetpackImageView.contentMode = .scaleAspectFit
        jetpackImageView.tintColor = .jetpackGreen
        jetpackImageView.translatesAutoresizingMaskIntoConstraints = false
        updateJetpackImageVisibility()

        infoIconImageView.contentMode = .scaleAspectFit
        infoIconImageView.translatesAutoresizingMaskIntoConstraints = false
        updateInfoIconVisibility()

        addSubview(emptyView)
        addSubview(jetpackImageView)
        addSubview(infoIconImageView)

        NSLayoutConstraint.activate([
            emptyView.widthAnchor.constraint(equalToConstant: 32),
            emptyView.heightAnchor.constraint(equalToConstant: 10),
            emptyView.centerXAnchor.constraint(equalTo: centerXAnchor),
            emptyView.centerYAnchor.constraint(equalTo: centerYAnchor),
            jetpackImageView.widthAnchor.constraint(equalToConstant: 14),
            jetpackImageView.heightAnchor.constraint(equalToConstant: 14),
            jetpackImageView.leadingAnchor.constraint(equalTo: emptyView.trailingAnchor, constant: 2),
            jetpackImageView.bottomAnchor.constraint(equalTo: emptyView.topAnchor),
            jetpackImageView.topAnchor.constraint(greaterThanOrEqualTo: topAnchor, constant: 0),
            infoIconImageView.widthAnchor.constraint(equalToConstant: 14),
            infoIconImageView.heightAnchor.constraint(equalToConstant: 14),
            infoIconImageView.leadingAnchor.constraint(equalTo: emptyView.trailingAnchor, constant: 2),
            infoIconImageView.bottomAnchor.constraint(equalTo: emptyView.topAnchor),
            infoIconImageView.topAnchor.constraint(greaterThanOrEqualTo: topAnchor, constant: 0)
        ])
    }
}

private extension StoreStatsEmptyView {
    func updateJetpackImageVisibility() {
        jetpackImageView.isHidden = showJetpackImage == false
    }

    func updateInfoIconVisibility() {
        infoIconImageView.isHidden = showInfoIcon == false
    }
}
