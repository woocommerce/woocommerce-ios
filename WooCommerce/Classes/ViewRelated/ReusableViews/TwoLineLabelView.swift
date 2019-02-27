import UIKit

final class TwoLineLabelView: UIView {
    @IBOutlet private var topLine: UILabel!
    @IBOutlet private var bottomLine: UILabel!
    @IBOutlet private var actionButton: UIButton!

    var onActionTouchUp: (() -> Void)?

    var topText: String? {
        get {
            return topLine.text
        }
        set {
            topLine.text = newValue
        }
    }

    var bottomText: String? {
        get {
            return bottomLine.text
        }
        set {
            bottomLine.text = newValue
        }
    }

    var actionButtonNormalText: String? {
        get {
            return actionButton.title(for: .normal)
        }
        set {
            actionButton.setTitle(newValue, for: .normal)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        configureTopLine()
        configureBottomLine()
        configureActionButton()
    }

    private func configureTopLine() {
        topLine.applyHeadlineStyle()
    }

    private func configureBottomLine() {
        bottomLine.applySubheadlineStyle()
    }

    private func configureActionButton() {
        actionButton.applySecondaryButtonStyle()
    }

    class func makeFromNib() -> TwoLineLabelView {
        return Bundle.main.loadNibNamed("TwoLineLabelView", owner: self, options: nil)?.first as! TwoLineLabelView
    }
}

extension TwoLineLabelView {
    @IBAction func actionWasPressed(_ sender: Any) {
        onActionTouchUp?()
    }
}
