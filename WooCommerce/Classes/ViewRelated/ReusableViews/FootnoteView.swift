import UIKit

class FootnoteView: UIView {
    @IBOutlet private var separatorLine: UIView!
    @IBOutlet private var footnoteLabel: UILabel! {
        didSet {
            footnoteLabel.applyFootnoteStyle()
        }
    }

    var footnote: String? {
        get {
            return footnoteLabel.text
        }
        set {
            footnoteLabel.text = newValue
        }
    }

    var separatorColor: UIColor? {
        get {
            return separatorLine.backgroundColor
        }
        set {
            separatorLine.backgroundColor = newValue
        }
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    class func makeFromNib() -> FootnoteView {
        return Bundle.main.loadNibNamed("FootnoteView", owner: self, options: nil)?.first as! FootnoteView
    }
}
