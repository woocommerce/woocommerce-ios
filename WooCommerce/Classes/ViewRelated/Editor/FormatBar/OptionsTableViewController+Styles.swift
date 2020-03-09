import WordPressEditor

extension OptionsTableViewController {
    func applyDefaultStyles() {
        cellDeselectedTintColor = .primary
        cellBackgroundColor = .listForeground
        cellSelectedBackgroundColor = .listBackground
        view.tintColor = .primary
    }
}
