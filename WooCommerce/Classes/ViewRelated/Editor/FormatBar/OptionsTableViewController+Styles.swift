import WordPressEditor

extension OptionsTableViewController {
    func applyDefaultStyles() {
        cellDeselectedTintColor = .brand
        cellBackgroundColor = .listForeground
        cellSelectedBackgroundColor = StyleManager.wooGreyLight
        view.tintColor = .brand
    }
}
