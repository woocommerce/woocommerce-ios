import Foundation
import UIKit



/// Simple custom star rating UIView control (0 to 5 stars).
///
class RatingView: UIView {

    // MARK: Public Properties

    /// Current "star" rating
    ///
    var rating: CGFloat {
        get {
            return _rating
        }
        set (newRating) {
            guard newRating >= Defaults.minRating else {
                _rating = Defaults.minRating
                return
            }

            _rating = min(newRating, Defaults.maxStars)
        }
    }

    /// Image to use for an empty "star"
    ///
    var emptyStarImage: UIImage! {
        didSet {
            updateImageViews()
        }
    }

    /// Image to use for a filled "star"
    ///
    var starImage: UIImage! {
        didSet {
            updateImageViews()
        }
    }

    // MARK: Private Properties

    private var _rating: CGFloat = Defaults.minRating {
        didSet {
            updateImageViews()
        }
    }

    private lazy var starViews: [StarView] = {
        var lazyImageViews: [StarView] = []
        for x in stride(from: 0, to: Defaults.maxStars, by: 1) {
            let imageView = StarView()
            imageView.translatesAutoresizingMaskIntoConstraints = false
            lazyImageViews.append(imageView)
        }

        return lazyImageViews
    }()

    // MARK: Lifecycle & Overrides

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupStarViewConstraints()
        configureStarColors(fullStarTintColor: Defaults.fullStarTintColor, emptyStarTintColor: Defaults.emptyStarTintColor)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupStarViewConstraints()
        configureStarColors(fullStarTintColor: Defaults.fullStarTintColor, emptyStarTintColor: Defaults.emptyStarTintColor)
    }

    override var intrinsicContentSize: CGSize {
        guard emptyStarImage != nil, starImage != nil else {
            return CGSize(width: (Defaults.height * Defaults.maxStars) + (Defaults.padding * (Defaults.maxStars - 1)), height: Defaults.height)
        }

        let tallestImageHeight = max(emptyStarImage.size.height, starImage.size.height)
        return CGSize(width: (tallestImageHeight * Defaults.maxStars) + (Defaults.padding * (Defaults.maxStars - 1)), height: tallestImageHeight)
    }

    // MARK: Public Configurations

    func configureStarColors(fullStarTintColor: UIColor, emptyStarTintColor: UIColor) {
        starViews.forEach { starView in
            starView.updateStarColors(fullStarColor: fullStarTintColor, emptyStarColor: emptyStarTintColor)
        }
    }

    // MARK: Private Helpers

    private func setupStarViewConstraints() {
        var lastStarView: StarView?
        for starView in starViews {
            addSubview(starView)

            if lastStarView != nil {
                let relationalConstraints = [
                    NSLayoutConstraint(item: starView,
                                       attribute: .left,
                                       relatedBy: .equal,
                                       toItem: lastStarView,
                                       attribute: .right,
                                       multiplier: 1.0,
                                       constant: Defaults.padding),

                    NSLayoutConstraint(item: starView,
                                       attribute: .top,
                                       relatedBy: .equal,
                                       toItem: lastStarView,
                                       attribute: .top,
                                       multiplier: 1.0,
                                       constant: 0.0),

                    NSLayoutConstraint(item: starView,
                                       attribute: .width,
                                       relatedBy: .equal,
                                       toItem: lastStarView,
                                       attribute: .width,
                                       multiplier: 1.0,
                                       constant: 0.0),
                    ]
                NSLayoutConstraint.activate(relationalConstraints)
            } else {
                let leftEdgeConstraints = [
                    NSLayoutConstraint(item: starView,
                                       attribute: .left,
                                       relatedBy: .equal,
                                       toItem: self,
                                       attribute: .left,
                                       multiplier: 1.0,
                                       constant: 0.0),

                    NSLayoutConstraint(item: starView,
                                       attribute: .top,
                                       relatedBy: .equal,
                                       toItem: self,
                                       attribute: .top,
                                       multiplier: 1.0,
                                       constant: 0.0),
                    ]
                NSLayoutConstraint.activate(leftEdgeConstraints)
            }

            lastStarView = starView
        }
    }

    private func updateImageViews() {
        guard emptyStarImage != nil, starImage != nil else {
            return
        }

        invalidateIntrinsicContentSize()

        let lastFullStar = floor(rating)
        let remainingStarFillPercentage = rating - lastFullStar

        for (index, starView) in starViews.enumerated() {
            if index < Int(lastFullStar) {
                starView.percentFill = 1.0
            } else if index == Int(lastFullStar) {
                starView.percentFill = remainingStarFillPercentage
            } else {
                starView.percentFill = 0.0
            }

            starView.setFullStarImage(fullStarImage: starImage, emptyStarImage: emptyStarImage)
        }

        invalidateIntrinsicContentSize()
    }
}


/// Individual star contained within the RatingView
///
private class StarView: UIView {
    var percentFill: CGFloat = 0.0
    var emptyStarImageView = UIImageView()
    var starImageView = UIImageView()

    private var starContainerView = UIView()

    override init(frame: CGRect = .zero) {
        super.init(frame: frame)

        starContainerView.clipsToBounds = true

        starContainerView.addSubview(starImageView)
        addSubview(emptyStarImageView)
        addSubview(starContainerView)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    func updateStarColors(fullStarColor: UIColor, emptyStarColor: UIColor) {
        emptyStarImageView.tintColor = emptyStarColor
        starImageView.tintColor = fullStarColor
    }

    func setFullStarImage(fullStarImage: UIImage, emptyStarImage: UIImage) {
        emptyStarImageView.image = emptyStarImage
        starImageView.image = fullStarImage

        emptyStarImageView.sizeToFit()
        starImageView.sizeToFit()

        //Because of the order of functions above, we can assume that we have a percent fill at this point
        starContainerView.frame = CGRect(origin: .zero, size: CGSize(width: intrinsicContentSize.width * percentFill, height: intrinsicContentSize.height))
    }

    override var intrinsicContentSize: CGSize {
        if emptyStarImageView.image != nil && starImageView.image != nil {
            let tallestImageHeight = max(emptyStarImageView.image?.size.height ?? 0, starImageView.image?.size.height ?? 0)
            return CGSize(width: tallestImageHeight, height: tallestImageHeight)
        } else {
            return CGSize(width: (Defaults.height * Defaults.maxStars) + (Defaults.padding * (Defaults.maxStars - 1)), height: Defaults.height)
        }
    }
}


// MARK: - Constants!
//
fileprivate enum Defaults {
    static let minRating = CGFloat(0.0)
    static let maxStars = CGFloat(5.0)
    static let padding  = CGFloat(0.0)
    static let height = CGFloat(10.0)
    static let fullStarTintColor = UIColor.text
    static let emptyStarTintColor = UIColor.text
}
