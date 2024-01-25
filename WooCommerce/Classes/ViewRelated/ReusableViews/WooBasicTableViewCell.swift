import UIKit


// MARK: - WooBasicTableViewCell

/// A UITableViewCell with bonus purple Woo styling.
///
/// So `BasicTableViewCell` uses springs and struts, causing
/// a different leading margin ("left margin") measurement than
/// a custom cell. Custom cells follow the superview margin. Custom
/// cells set a 20 point leading margin on an iPhone XS Max.
/// But a BasicTableViewCell sets the leading margin to 16 points.
/// So here we are, building a `BasicTableViewCell` as a custom cell,
/// so that the margins match. --- ¯\_(ツ)_/¯ 21.05.2019 tc
///
class WooBasicTableViewCell: UITableViewCell {

    @IBOutlet private(set) weak var bodyLabel: UILabel!
    @IBOutlet private(set) weak var bodyLabelTopMarginConstraint: NSLayoutConstraint!

    public var accessoryImage: UIImage? {
        didSet {
            configureAccessoryView()
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        configureBackground()
        configureSelectionStyle()
        configureLabel()
    }

    override func updateConfiguration(using state: UICellConfigurationState) {
        super.updateConfiguration(using: state)
        updateDefaultBackgroundConfiguration(using: state)
    }

    func configureBackground() {
        configureDefaultBackgroundConfiguration()
    }

    /// Set up the cell selection style
    ///
    func configureSelectionStyle() {
        selectionStyle = .default
    }

    /// Style the label(s)
    ///
    func configureLabel() {
        bodyLabel?.applyBodyStyle()
        bodyLabel?.textColor = .primary
    }

    /// Add the accessoryView image, if any
    ///
    func configureAccessoryView() {
        guard let accessoryImage = accessoryImage else {
            accessoryView = nil
            return
        }

        let accessoryImageView = UIImageView(image: accessoryImage)
        accessoryImageView.tintColor = .primaryButtonBackground
        accessoryView = accessoryImageView
    }

    // MARK: - Side borders used in wider table views when max-width used to ensure readability.

    private var rightBorder: CALayer?
    private var leftBorder: CALayer?
    private var shouldShowSideBorders = false
    private var minimumWidthForSideBorders: CGFloat?

    func showSideBorders(fromWidth minimumWidth: CGFloat) {
        shouldShowSideBorders = true
        minimumWidthForSideBorders = minimumWidth
    }


    override func layoutSubviews() {
        super.layoutSubviews()

        guard shouldShowSideBorders,
              let minimumWidthForSideBorders else {
            return
        }

        guard bounds.width >= minimumWidthForSideBorders else {
            removeSideBorders()
            return
        }

        if leftBorder == nil || rightBorder == nil {
            removeSideBorders() // to prevent any double-border issues!
            addSideBorders()
        }

        leftBorder?.frame = CGRect(x: 0.0,
                                   y: 0.0,
                                   width: Constants.borderWidth,
                                   height: bounds.maxY)

        rightBorder?.frame = CGRect(x: bounds.maxX - Constants.borderWidth,
                                    y: 0.0,
                                    width: Constants.borderWidth,
                                    height: bounds.maxY)
    }

    private func addSideBorders() {
        let leftBorder = CALayer()
        leftBorder.backgroundColor = UIColor.border.cgColor

        let rightBorder = CALayer()
        rightBorder.backgroundColor = UIColor.border.cgColor

        layer.addSublayer(leftBorder)
        layer.addSublayer(rightBorder)
        self.leftBorder = leftBorder
        self.rightBorder = rightBorder
    }

    private func removeSideBorders() {
        leftBorder?.removeFromSuperlayer()
        rightBorder?.removeFromSuperlayer()
        leftBorder = nil
        rightBorder = nil
    }
}

extension WooBasicTableViewCell {
    func applyListSelectorStyle() {
        bodyLabel.applyBodyStyle()
        bodyLabelTopMarginConstraint.constant = 0
    }

    func applyPlainTextStyle() {
        bodyLabel.applyBodyStyle()
        bodyLabelTopMarginConstraint.constant = 8
    }

    func applyActionableStyle() {
        bodyLabel.applyActionableStyle()
        bodyLabelTopMarginConstraint.constant = 8
    }

    func applySecondaryTextStyle() {
        bodyLabel.applySecondaryBodyStyle()
        bodyLabelTopMarginConstraint.constant = 8
    }
}

private extension WooBasicTableViewCell {
    enum Constants {
        static let borderWidth: CGFloat = 0.5
    }
}
