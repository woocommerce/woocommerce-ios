import UIKit


/// Represents a regular UITableView Cell: [Image | Text |  Disclosure]
///
class BadgedLeftImageTableViewCell: UITableViewCell {

    /// Left Image
    ///
    var leftImage: UIImage? {
        get {
            return imageView?.image
        }
        set {
            imageView?.image = newValue
        }
    }

    /// Label's Text
    ///
    var labelText: String? {
        get {
            return textLabel?.text
        }
        set {
            textLabel?.text = newValue
        }
    }

    // MARK: - Overridden Methods

    override func awakeFromNib() {
        super.awakeFromNib()
        configureBackground()
        imageView?.tintColor = .primary
        textLabel?.applyBodyStyle()
    }

    private func configureBackground() {
        applyDefaultBackgroundStyle()

        //Background when selected
        selectedBackgroundView = UIView()
        selectedBackgroundView?.backgroundColor = .listBackground
    }
}

// MARK: - Public Methods
//
extension BadgedLeftImageTableViewCell {
    func configure(image: UIImage, text: String, showBadge: Bool) {
        imageView?.image = image
        textLabel?.text = text
        badgeImage(visible: showBadge)
    }
}

private extension BadgedLeftImageTableViewCell {
    func badgeImage(visible: Bool) {
        guard let imageView,
        imageView.frame != .zero else {
            return
        }

        if visible {
            dotView?.removeFromSuperview() // ensures we don't end up with multiple dotViews
            let dot = DotView(frame: CGRect(x: xOffset(in: imageView),
                                            y: DotConstants.yOffset,
                                            width: DotConstants.diameter,
                                            height: DotConstants.diameter),
                              color: .accent,
                              borderWidth: DotConstants.borderWidth)
            imageView.insertSubview(dot, at: 1)
        } else {
            dotView?.fadeOut()
            dotView?.removeFromSuperview()
        }
    }

    private var dotView: DotView? {
        imageView?.subviews.first(where: { $0 is DotView }) as? DotView
    }

    private func xOffset(in imageView: UIImageView) -> CGFloat {
        return imageView.frame.width - DotConstants.diameter
    }

    private enum DotConstants {
        static let diameter = CGFloat(9)
        static let borderWidth = CGFloat(1)
        static let yOffset = CGFloat(0)
    }
}
