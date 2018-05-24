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

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    class func makeFromNib() -> FootnoteView {
        return Bundle.main.loadNibNamed("FootnoteView", owner: self, options: nil)?.first as! FootnoteView
    }
}

extension FootnoteView {
    func configure(footnoteText: String?, borderColor: UIColor?) {
        footnote = footnoteText
        separatorLine.backgroundColor = borderColor
    }
}
