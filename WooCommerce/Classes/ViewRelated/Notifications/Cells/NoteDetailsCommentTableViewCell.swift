import Foundation
import UIKit
import WordPressUI
import Gridicons
import Cosmos


// MARK: - NoteDetailsCommentTableViewCell
//
class NoteDetailsCommentTableViewCell: UITableViewCell {

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

    /// UIView: container view for rating star view
    ///
    @IBOutlet private var starViewContainer: UIView!

    /// Star View for reviews
    ///
    private var starView = CosmosView()

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
                starViewContainer.isHidden = true
                return
            }

            starView.rating = Double(starRating)
            starViewContainer.isHidden = false
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
        configureActionButtons()
        configureStarView()
        configureDefaultAppearance()
    }

    override public func prepareForReuse() {
        starView.prepareForReuse()
    }
}


// MARK: - Setup
//
private extension NoteDetailsCommentTableViewCell {

    /// Setup: Actions!
    ///
    func configureActionButtons() {
        let spamImage = Gridicon.iconOfType(.spam)
        spamButton.setImage(spamImage, for: .normal)
        spamButton.setTitle(Spam.normalTitle, for: .normal)
        spamButton.accessibilityLabel = Spam.normalLabel
        spamButton.accessibilityTraits = .button

        let trashImage = Gridicon.iconOfType(.trash)
        trashButton.setImage(trashImage, for: .normal)
        trashButton.setTitle(Trash.normalTitle, for: .normal)
        trashButton.accessibilityLabel = Trash.normalLabel
        trashButton.accessibilityTraits = .button

        let checkmarkImage = Gridicon.iconOfType(.checkmark)
        approvalButton.setImage(checkmarkImage, for: .normal)
        approvalButton.setTitle(Approve.normalTitle, for: .normal)
        approvalButton.setTitle(Approve.selectedTitle, for: .selected)
        approvalButton.accessibilityLabel = Approve.normalLabel
        approvalButton.accessibilityTraits = .button
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
        if starViewContainer.subviews.isEmpty {
            starView.translatesAutoresizingMaskIntoConstraints = false
            starViewContainer.addSubview(starView)
            starViewContainer.pinSubviewToAllEdges(starView)
        }

        starView.accessibilityLabel = NSLocalizedString("Star rating", comment: "VoiceOver accessibility label for a product review star rating ")
        starView.settings.updateOnTouch = false
        starView.settings.totalStars = Star.totalStars
        starView.settings.fillMode = .full
        starView.settings.starSize = Star.size
        starView.settings.starMargin = Star.margin
        starView.settings.filledImage = Star.filledImage
        starView.settings.emptyImage = Star.emptyImage
        starViewContainer.isHidden = (starRating == nil)
    }

    /// Setup: Button Appearance
    ///
    func refreshAppearance(button: UIButton) {
        let bgColor = button.isSelected ? StyleManager.wooCommerceBrandColor : StyleManager.wooGreyLight
        let textColor = button.isSelected ? StyleManager.wooGreyLight : StyleManager.wooCommerceBrandColor

        button.backgroundColor = bgColor
        button.tintColor = textColor
        button.setTitleColor(textColor, for: .normal)
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
    static let totalStars  = 5
    static let size        = Double(18)
    static let margin      = Double(2)
    static let filledImage = Gridicon.iconOfType(.star, withSize: CGSize(width: Star.size, height: Star.size)).imageWithTintColor(StyleManager.goldStarColor)
    static let emptyImage  = Gridicon.iconOfType(.star, withSize: CGSize(width: Star.size, height: Star.size)).imageWithTintColor(StyleManager.wooGreyLight)
}
