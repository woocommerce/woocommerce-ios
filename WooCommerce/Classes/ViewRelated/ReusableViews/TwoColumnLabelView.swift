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

    func refreshStyle(mode: Mode) {
        switch mode {
        case .body:
            leftColumn.applyBodyStyle()
            rightColumn.applyBodyStyle()
        case .title:
            leftColumn.applyTitleStyle()
            rightColumn.applyTitleStyle()
        }
    }

    required init?(coder aDecoder: NSCoder) {
        mode = .body
        super.init(coder: aDecoder)
    }

    class func makeFromNib() -> TwoColumnLabelView {
        return Bundle.main.loadNibNamed("TwoColumnLabelView", owner: self, options: nil)?.first as! TwoColumnLabelView
    }

    override func awakeFromNib() {
        super.awakeFromNib()
    }
}

extension TwoColumnLabelView {
    func configure(leftText: String?, rightText: String?) {
        leftColumn.text = leftText
        rightColumn.text = rightText
    }

    func configureWithTitleStyle(leftText: String?, rightText: String?) {
        mode = .title
        topConstraint.constant = Constants.topConstant
        bottomConstraint.constant = Constants.bottomConstant
        configure(leftText: leftText, rightText: rightText)
    }

    struct Constants {
        static let topConstant = CGFloat(14)
        static let bottomConstant = CGFloat(20)
    }
}
