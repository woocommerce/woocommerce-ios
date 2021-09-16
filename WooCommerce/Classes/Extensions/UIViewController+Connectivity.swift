import UIKit

extension UIViewController {
    /// Content of offline banner
    ///
    var offlineContentView: UIView {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 3
        stackView.distribution = .fillProportionally
        stackView.alignment = .center

        let imageView = UIImageView(image: .lightningImage)
        imageView.tintColor = .white
        imageView.contentMode = .scaleAspectFit
        NSLayoutConstraint.activate([
            imageView.widthAnchor.constraint(equalToConstant: 24),
            imageView.heightAnchor.constraint(equalToConstant: 24)
        ])

        let messageLabel = UILabel()
        messageLabel.text = NSLocalizedString("Offline - using cached data", comment: "Message for offline banner")
        messageLabel.applyCalloutStyle()
        messageLabel.textColor = .white

        stackView.addArrangedSubview(imageView)
        stackView.addArrangedSubview(messageLabel)
        return stackView
    }

    /// Set up toolbar for the view controller to display the offline message,
    /// and listen to connectivity status changes to change the toolbar's visibility.
    ///
    func configureOfflineBanner() {
        let offlineItem = UIBarButtonItem(customView: offlineContentView)
        let spaceItem = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        toolbarItems = [spaceItem, offlineItem, spaceItem]
        navigationController?.toolbar.barTintColor = .gray

        let connected = ServiceLocator.connectivityObserver.isConnectivityAvailable
        navigationController?.setToolbarHidden(connected, animated: true)

        ServiceLocator.connectivityObserver.updateListener { [weak self] status in
            guard let self = self,
                  self.isViewOnScreen() else { return }
            self.navigationController?.setToolbarHidden(status != .notReachable, animated: true)
        }
    }
}
