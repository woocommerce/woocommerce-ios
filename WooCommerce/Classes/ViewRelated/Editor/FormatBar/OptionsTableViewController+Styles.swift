import WordPressEditor

extension OptionsTableViewController {
    func applyDefaultStyles() {
        cellDeselectedTintColor = StyleManager.wooCommerceBrandColor
        cellBackgroundColor = StyleManager.wooWhite
        cellSelectedBackgroundColor = StyleManager.wooGreyLight
        view.tintColor = StyleManager.wooCommerceBrandColor
    }
}
