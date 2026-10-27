import UIKit

@MainActor
class BasicTableViewCell: UITableViewCell {

    override func awakeFromNib() {
        super.awakeFromNib()
        // UIKit loads view nibs on the main actor; NSObject's callback is nonisolated.
        MainActor.assumeIsolated { configureAfterNibLoad() }
    }

    private func configureAfterNibLoad() {
        configureBackground()
        textLabel?.applyBodyStyle()
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        textLabel?.applyBodyStyle()
        textLabel?.textAlignment = .natural
        accessibilityIdentifier = nil
    }

    override func updateConfiguration(using state: UICellConfigurationState) {
        super.updateConfiguration(using: state)
        updateDefaultBackgroundConfiguration(using: state)
    }
}


private extension BasicTableViewCell {
    func configureBackground() {
        configureDefaultBackgroundConfiguration()
    }
}
