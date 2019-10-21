import UIKit

class TwoColumnLabelView: UIView {
    @IBOutlet private var leftColumn: UILabel!
    @IBOutlet private var rightColumn: UILabel!

    enum Mode {
        case body
        case title
    }

    var mode: Mode = .body {
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
            leftColumn.applyHeadlineStyle()
            rightColumn.applyHeadlineStyle()
        }
    }

    required init?(coder aDecoder: NSCoder) {
        // initializers don't call property observers,
        // so don't set the default for mode here.
        super.init(coder: aDecoder)
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        mode = .body  // trigger the property observer
    }

    class func makeFromNib() -> TwoColumnLabelView {
        return Bundle.main.loadNibNamed("TwoColumnLabelView", owner: self, options: nil)?.first as! TwoColumnLabelView
    }
}
