import UIKit

final class ConnectedReaderTableViewCell: UITableViewCell {
    struct ViewModel {
        let name: String?
        let batteryLevel: String?
        let softwareVersion: String?
    }

    @IBOutlet private weak var nameLabel: UILabel!
    @IBOutlet private weak var batteryLevelLabel: UILabel!
    @IBOutlet private weak var softwareVersionLabel: UILabel!

    private var viewModel: ViewModel?

    override func awakeFromNib() {
        styleSoftwareVersionLabel()
    }

    func configure(viewModel: ViewModel) {
        self.viewModel = viewModel
        nameLabel.text = viewModel.name
        batteryLevelLabel.text = viewModel.batteryLevel
        softwareVersionLabel.text = viewModel.softwareVersion
    }
}

private extension ConnectedReaderTableViewCell {
    func styleSoftwareVersionLabel() {
        softwareVersionLabel.lineBreakMode = .byCharWrapping
        softwareVersionLabel.numberOfLines = 0
    }
}
