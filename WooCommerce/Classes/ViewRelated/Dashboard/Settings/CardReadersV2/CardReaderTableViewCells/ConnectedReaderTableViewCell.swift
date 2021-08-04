import UIKit

final class ConnectedReaderTableViewCell: UITableViewCell {
    struct ViewModel {
        let name: String?
        let batteryLevel: String?
    }

    @IBOutlet private weak var nameLabel: UILabel!
    @IBOutlet private weak var batteryLevelLabel: UILabel!

    private var viewModel: ViewModel?

    func configure(viewModel: ViewModel) {
        self.viewModel = viewModel
        nameLabel.text = viewModel.name
        batteryLevelLabel.text = viewModel.batteryLevel
    }
}
