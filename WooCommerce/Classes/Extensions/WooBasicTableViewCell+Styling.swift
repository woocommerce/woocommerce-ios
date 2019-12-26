import UIKit

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
}
