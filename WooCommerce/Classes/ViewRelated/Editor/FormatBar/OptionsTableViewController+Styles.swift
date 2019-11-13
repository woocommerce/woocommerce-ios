import WordPressEditor

extension OptionsTableViewController {
    func applyDefaultStyles() {
        cellDeselectedTintColor = .brand
        cellBackgroundColor = .listForeground
        cellSelectedBackgroundColor = .listBackground
        view.tintColor = .brand
    }
}
