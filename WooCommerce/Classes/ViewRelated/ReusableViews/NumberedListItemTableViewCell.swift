import UIKit

class NumberedListItemTableViewCell: UITableViewCell {
    struct ViewModel {
        let itemNumber: String?
        let itemText: String?
    }

    @IBOutlet private weak var numberLabel: UILabel!
    @IBOutlet private weak var itemTextLabel: UILabel!

    private var viewModel: ViewModel?

    func configure(viewModel: ViewModel) {
        self.viewModel = viewModel
        numberLabel.text = viewModel.itemNumber
        itemTextLabel.text = viewModel.itemText
    }
}
