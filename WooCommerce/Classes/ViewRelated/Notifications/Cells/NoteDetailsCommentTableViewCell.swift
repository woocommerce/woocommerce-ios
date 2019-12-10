import Foundation
import UIKit
import WordPressUI
import Gridicons

private extension UIButton {
    func applyNoteDetailsActionStyle(icon: UIImage) {
        setImage(icon, for: .normal)
        backgroundColor = .systemColor(.systemGray5)
        imageView?.tintColor = .primary
        setTitleColor(.primary, for: .normal)
        accessibilityTraits = .button
    }

    func updateNoteDetailsActionStyle(isSelected: Bool) {
        let bgColor = isSelected ? UIColor.primary : UIColor.systemColor(.systemGray5)
        let textColor = isSelected ? UIColor.white : UIColor.primary

        backgroundColor = bgColor
        tintColor = textColor
        imageView?.tintColor = textColor
        setTitleColor(textColor, for: .normal)
    }
}


// MARK: - NoteDetailsCommentTableViewCell
//
final class NoteDetailsCommentTableViewCell: UITableViewCell {

    /// Gravatar ImageView.
    ///
    @IBOutlet private var gravatarImageView: CircularImageView!

    /// Source's Title.
    ///
    @IBOutlet private var titleLabel: UILabel!

    /// Source's Details.
    ///
    @IBOutlet private var detailsLabel: UILabel!

    /// Main Comment's TextView.
    ///
    @IBOutlet private var textView: UITextView!

    /// Button: Spam
    ///
    @IBOutlet private var spamButton: UIButton!

    /// Button: Trash
    ///
    @IBOutlet private var trashButton: UIButton!

    /// Button: Approval
    ///
    @IBOutlet private var approvalButton: UIButton!

    /// Custom UIView: Rating star view
    ///
    @IBOutlet private var starRatingView: RatingView!

    /// Closure to be executed whenever the Spam Button is pressed.
    ///
    var onSpam: (() -> Void)?

    /// Closure to be executed whenever the Trash Button is pressed.
    ///
    var onTrash: (() -> Void)?

    /// Closure to be executed whenever the Approve Button is pressed.
    ///
    var onApprove: (() -> Void)?

    /// Closure to be executed whenever the Unapprove Button is pressed.
    ///
    var onUnapprove: (() -> Void)?


    /// Indicates if the Spam Button is enabled (or not!)
    ///
    var isSpamEnabled: Bool {
        get {
            return !spamButton.isHidden
        }
        set {
            spamButton.isHidden = !newValue
        }
    }

    /// Indicates if the Trash Button is enabled (or not!)
    ///
    var isTrashEnabled: Bool {
        get {
            return !trashButton.isHidden
        }
        set {
            trashButton.isHidden = !newValue
        }
    }

    /// Indicates if the Approval Button is enabled (or not!)
    ///
    var isApproveEnabled: Bool {
        get {
            return !approvalButton.isHidden
        }
        set {
            approvalButton.isHidden = !newValue
        }
    }

    /// Indicates if the Approval Button is Selected (or not!)
    ///
    var isApproveSelected: Bool {
        get {
            return approvalButton.isSelected
        }
        set {
            approvalButton.isSelected = newValue
            refreshApprovalLabels()
            refreshAppearance(button: approvalButton)
        }
    }

    /// Title: Usually displays the Author's Name.
    ///
    var titleText: String? {
        get {
            return titleLabel.text
        }
        set {
            titleLabel.text = newValue
        }
    }

    /// Details: Usually displays the Time Elapsed since the comment was posted.
    ///
    var detailsText: String? {
        get {
            return detailsLabel.text
        }
        set {
            detailsLabel.text = newValue
        }
    }

    /// Comment's Body.
    ///
    var commentAttributedText: NSAttributedString? {
        get {
            return textView.attributedText
        }
        set {
            textView.attributedText = newValue
        }
    }

    /// Star rating value (if nil, star rating view will be hidden)
    ///
    var starRating: Int? {
        didSet {
            guard let starRating = starRating else {
                starRatingView.isHidden = true
                return
            }

            starRatingView.rating = CGFloat(starRating)
            starRatingView.isHidden = false
        }
    }

    /// Downloads the Gravatar Image at the specified URL (if any!).
    ///
    func downloadGravatar(with url: URL?) {
        let gravatar = url.flatMap { Gravatar($0) }
        gravatarImageView.downloadGravatar(gravatar, placeholder: .gravatarPlaceholderImage, animate: true)
    }


    // MARK: - Overridden Methods

    override func awakeFromNib() {
        super.awakeFromNib()
        configureBackground()
        configureActionButtons()
        configureTitleLabel()
        configureDetailsLabel()
        configureTextView()
        configureStarView()
        configureDefaultAppearance()
    }
}


// MARK: - Setup
//
private extension NoteDetailsCommentTableViewCell {

    /// Setup: Cell background
    ///
    func configureBackground() {
        applyDefaultBackgroundStyle()
    }

    /// Setup: Actions!
    ///
    func configureActionButtons() {
        spamButton.applyNoteDetailsActionStyle(icon: .spamImage)
        spamButton.setTitle(Spam.normalTitle, for: .normal)
        spamButton.accessibilityLabel = Spam.normalLabel

        trashButton.applyNoteDetailsActionStyle(icon: .trashImage)
        trashButton.setTitle(Trash.normalTitle, for: .normal)
        trashButton.accessibilityLabel = Trash.normalLabel

        approvalButton.applyNoteDetailsActionStyle(icon: .checkmarkImage)
        approvalButton.setTitle(Approve.normalTitle, for: .normal)
        approvalButton.setTitle(Approve.selectedTitle, for: .selected)
        approvalButton.accessibilityLabel = Approve.normalLabel
    }

    func configureTitleLabel() {
        titleLabel.textColor = .systemColor(.label)
    }

    func configureDetailsLabel() {
        detailsLabel.textColor = .systemColor(.secondaryLabel)
    }

    func configureTextView() {
        textView.backgroundColor = .listForeground
    }

    /// Setup: Default Action(s) Style
    ///
    func configureDefaultAppearance() {
        let buttons = [spamButton, trashButton, approvalButton].compactMap { $0 }

        for button in buttons {
            refreshAppearance(button: button)
        }
    }

    /// Setup: Star rating view
    ///
    func configureStarView() {
        starRatingView.configureStarColors(fullStarTintColor: Star.filledColor, emptyStarTintColor: Star.emptyColor)
        starRatingView.starImage = Star.filledImage
        starRatingView.emptyStarImage = Star.emptyImage
        starRatingView.isHidden = (starRating == nil)
    }

    /// Setup: Button Appearance
    ///
    func refreshAppearance(button: UIButton) {
        button.updateNoteDetailsActionStyle(isSelected: button.isSelected)
    }

    /// Refreshes the ApprovalButton's Accessibility Label
    ///
    func refreshApprovalLabels() {
        approvalButton.accessibilityLabel = approvalButton.isSelected ? Approve.selectedLabel : Approve.normalLabel
    }
}


// MARK: - Delegates
//
private extension NoteDetailsCommentTableViewCell {

    /// Spam Button Callback
    ///
    @IBAction func spamWasPressed(_ sender: UIButton) {
        sender.animateImageOverlay(style: .explosion)
        onSpam?()
    }

    /// Trash Button Callback
    ///
    @IBAction func trashWasPressed(_ sender: UIButton) {
        sender.animateImageOverlay(style: .explosion)
        onTrash?()
    }

    /// Approval Button Callback
    ///
    @IBAction func approveWasPressed(_ sender: UIButton) {
        let onClick = isApproveSelected ? onUnapprove : onApprove
        let newState = !isApproveSelected

        sender.animateImageOverlay(style: newState ? .explosion : .implosion)
        isApproveSelected = newState

        onClick?()
    }
}


// MARK: - Spam Button: Strings!
//
private struct Spam {
    static let normalTitle      = NSLocalizedString("Spam", comment: "Verb, spam a comment")
    static let normalLabel      = NSLocalizedString("Moves a comment to Spam", comment: "Spam Action Spoken hint.")
}


// MARK: - Trash Button: Strings!
//
private struct Trash {
    static let normalTitle      = NSLocalizedString("Trash", comment: "Move a comment to the trash")
    static let normalLabel      = NSLocalizedString("Moves the comment to Trash", comment: "Trash Action Spoken hint")
}


// MARK: - Approve Button: Strings!
//
private struct Approve {
    static let normalTitle      = NSLocalizedString("Approve", comment: "Approve a comment")
    static let selectedTitle    = NSLocalizedString("Approved", comment: "Unapprove a comment")
    static let normalLabel      = NSLocalizedString("Approves the comment", comment: "Approves a comment. Spoken Hint.")
    static let selectedLabel    = NSLocalizedString("Unapproves the comment", comment: "Unapproves a comment. Spoken Hint.")
}


// MARK: - Star View: Defaults
//
private struct Star {
    static let size        = Double(18)
    static let filledImage = UIImage.starImage(size: Star.size)
    static let emptyImage = UIImage.starImage(size: Star.size)
    static let filledColor = UIColor.ratingStarFilled
    static let emptyColor = UIColor.ratingStarEmpty
}
