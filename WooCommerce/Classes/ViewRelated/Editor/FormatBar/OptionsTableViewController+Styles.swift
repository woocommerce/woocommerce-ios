import WordPressEditor

extension OptionsTableViewController {
    func applyDefaultStyles() {
        cellDeselectedTintColor = .primary
        cellBackgroundColor = .listForeground(modal: false)
        cellSelectedBackgroundColor = .listBackground
        view.tintColor = .primary
    }
}
