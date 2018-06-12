import UIKit

class TwoColumnLabelView: UIView {
    @IBOutlet private var leftColumn: UILabel!
    @IBOutlet private var rightColumn: UILabel!
    @IBOutlet private var topConstraint: NSLayoutConstraint!
    @IBOutlet private var bottomConstraint: NSLayoutConstraint!

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    class func makeFromNib() -> TwoColumnLabelView {
        return Bundle.main.loadNibNamed("TwoColumnLabelView", owner: self, options: nil)?.first as! TwoColumnLabelView
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        leftColumn.applyBodyStyle()
        rightColumn.applyBodyStyle()
    }
}

extension TwoColumnLabelView {
    func configure(leftText: String?, rightText: String?) {
        leftColumn.text = leftText
        rightColumn.text = rightText
    }

    func configureWithTitleStyle(leftText: String?, rightText: String?) {
        leftColumn.applyTitleStyle()
        rightColumn.applyTitleStyle()
        topConstraint.constant = Constants.topConstant
        bottomConstraint.constant = Constants.bottomConstant
        configure(leftText: leftText, rightText: rightText)
    }

    struct Constants {
        static let topConstant = CGFloat(14)
        static let bottomConstant = CGFloat(20)
    }
}
