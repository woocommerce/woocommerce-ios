import UIKit

class TwoColumnLabelView: UIView {
    @IBOutlet private var leftColumn: UILabel!
    @IBOutlet private var rightColumn: UILabel!
    @IBOutlet private var topConstraint: NSLayoutConstraint!
    @IBOutlet private var bottomConstraint: NSLayoutConstraint!

    enum Mode {
        case body
        case title
    }

    var mode: Mode {
        didSet {
            refreshStyle(mode: mode)
        }
    }

    var leftText: String? {
        get {
            return leftColumn.text
        }
        set {
            leftColumn.text = newValue
        }
    }

    var rightText: String? {
        get {
            return rightColumn.text
        }
        set {
            rightColumn.text = newValue
        }
    }

    func refreshStyle(mode: Mode) {
        switch mode {
        case .body:
            leftColumn.applyBodyStyle()
            rightColumn.applyBodyStyle()
        case .title:
            leftColumn.applyTitleStyle()
            rightColumn.applyTitleStyle()
            topConstraint.constant = Constants.topConstant
            bottomConstraint.constant = Constants.bottomConstant
        }
    }

    required init?(coder aDecoder: NSCoder) {
        mode = .body
        super.init(coder: aDecoder)
    }

    class func makeFromNib() -> TwoColumnLabelView {
        return Bundle.main.loadNibNamed("TwoColumnLabelView", owner: self, options: nil)?.first as! TwoColumnLabelView
    }
}

extension TwoColumnLabelView {
    struct Constants {
        static let topConstant = CGFloat(14)
        static let bottomConstant = CGFloat(20)
    }
}
