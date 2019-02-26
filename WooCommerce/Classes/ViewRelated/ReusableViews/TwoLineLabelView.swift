import UIKit

final class TwoLineLabelView: UIView {
    @IBOutlet private var topLine: UILabel!
    @IBOutlet private var bottomLine: UILabel!

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
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        topLine.applyHeadlineStyle()
        bottomLine.applySubheadlineStyle()
    }

    class func makeFromNib() -> TwoLineLabelView {
        return Bundle.main.loadNibNamed("TwoLineLabelView", owner: self, options: nil)?.first as! TwoLineLabelView
    }
}
