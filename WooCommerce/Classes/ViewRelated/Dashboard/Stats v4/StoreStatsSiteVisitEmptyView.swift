import UIKit

final class StoreStatsSiteVisitEmptyView: UIView {
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
        emptyView.backgroundColor = .systemColor(.systemGroupedBackground)
        emptyView.layer.cornerRadius = 2.0
        emptyView.translatesAutoresizingMaskIntoConstraints = false

        let jetpackImageView = UIImageView(image: .jetpackLogoImage.withRenderingMode(.alwaysTemplate))
        jetpackImageView.contentMode = .scaleAspectFit
        jetpackImageView.tintColor = .jetpackGreen
        jetpackImageView.translatesAutoresizingMaskIntoConstraints = false

        addSubview(emptyView)
        addSubview(jetpackImageView)

        NSLayoutConstraint.activate([
            self.widthAnchor.constraint(equalToConstant: 48),
            emptyView.widthAnchor.constraint(equalToConstant: 32),
            emptyView.heightAnchor.constraint(equalToConstant: 10),
            emptyView.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            emptyView.topAnchor.constraint(equalTo: jetpackImageView.bottomAnchor),
            jetpackImageView.widthAnchor.constraint(equalToConstant: 14),
            jetpackImageView.heightAnchor.constraint(equalToConstant: 14),
            jetpackImageView.leadingAnchor.constraint(equalTo: emptyView.trailingAnchor),
            jetpackImageView.topAnchor.constraint(equalTo: self.topAnchor, constant: 4)
        ])
    }
}
