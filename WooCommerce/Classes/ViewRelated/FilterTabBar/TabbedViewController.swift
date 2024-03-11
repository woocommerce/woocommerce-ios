import UIKit

// NOTE: this file is adapted from WPiOS at the following path:
// https://github.com/wordpress-mobile/WordPress-iOS/blob/c67f3b6205c1bc40085b390ec5e46faf5e281df9/
// WordPress/Classes/ViewRelated/Reader/Manage/TabbedViewController.swift

/// Contains multiple Child View Controllers with a Filter Tab Bar to switch between them.
class TabbedViewController: UIViewController {

    struct TabbedItem: FilterTabBarItem {
        let title: String
        let viewController: UIViewController
        let accessibilityIdentifier: String
    }

    /// The selected view controller
    var selection: Int {
        set {
            tabBar.setSelectedIndex(newValue)
        }
        get {
            return tabBar.selectedIndex
        }
    }

    private var items: [TabbedItem]
    private let onDismiss: (() -> Void)?

    private var customTabBarView: UIView?

    private(set) lazy var tabBar: FilterTabBar = {
        let bar = FilterTabBar()
        configureFilterTabBar(bar)
        bar.tabSizingStyle = .equalWidths
        bar.translatesAutoresizingMaskIntoConstraints = false
        bar.addTarget(self, action: #selector(changedItem(sender:)), for: .valueChanged)
        return bar
    }()

    private lazy var tabBarStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        return stackView
    }()

    private lazy var stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        return stackView
    }()

    init(items: [TabbedItem], tabSizingStyle: FilterTabBar.TabSizingStyle, onDismiss: (() -> Void)? = nil) {
        self.items = items
        self.onDismiss = onDismiss
        super.init(nibName: nil, bundle: nil)
        tabBar.items = items
        tabBar.tabSizingStyle = tabSizingStyle

        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(donePressed))

        tabBarStackView.addArrangedSubview(tabBar)
        stackView.addArrangedSubview(tabBarStackView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc func donePressed() {
        onDismiss?()
        dismiss(animated: true, completion: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(stackView)
        view.pinSubviewToAllEdges(stackView)

        configureChildViewControllers()
        setInitialChild()
    }

    private func setInitialChild() {
        updateVisibleChildViewController(at: selection)
    }

    @objc func changedItem(sender: FilterTabBar) {
        updateVisibleChildViewController(at: sender.selectedIndex)
        selection = sender.selectedIndex
    }

    func addCustomViewToTabBar(_ customView: UIView) {
        tabBarStackView.addArrangedSubview(customView)
        customTabBarView = customView
    }

    func removeCustomViewFromTabBar() {
        guard let customTabBarView else {
            return
        }
        tabBarStackView.removeArrangedSubview(customTabBarView)
        customTabBarView.removeFromSuperview()
        self.customTabBarView = nil
    }

    func appendToTabBar(_ tab: TabbedItem) {
        // Setup child view controller
        items.append(tab)
        tabBar.items = items
        addChild(tab.viewController)
        stackView.addArrangedSubview(tab.viewController.view)
        tab.viewController.didMove(toParent: self)
        tab.viewController.view.isHidden = true

        // Set the appended tab as selected
        let tabPosition = items.count-1
        selection = tabPosition
        updateVisibleChildViewController(at: tabPosition)
    }

    func replaceTab(at index: Int, with newTab: TabbedItem) {
        let oldTab = items[index]
        stackView.removeArrangedSubview(oldTab.viewController.view)
        oldTab.viewController.removeFromParent()
        oldTab.viewController.view.removeFromSuperview()
        items.remove(at: index)

        appendToTabBar(newTab)
    }
}

private extension TabbedViewController {
    func configureFilterTabBar(_ filterTabBar: FilterTabBar) {
        filterTabBar.backgroundColor = .systemColor(.secondarySystemGroupedBackground)
        filterTabBar.tintColor = .primary
        filterTabBar.selectedTitleColor = .primary
        filterTabBar.deselectedTabColor = .textSubtle
        filterTabBar.dividerColor = .systemColor(.separator)
    }

    func configureChildViewControllers() {
        items.map { $0.viewController }.forEach { viewController in
            addChild(viewController)
            stackView.addArrangedSubview(viewController.view)
            viewController.didMove(toParent: self)
            viewController.view.isHidden = true
        }
    }
}

private extension TabbedViewController {
    func updateVisibleChildViewController(at selectedTabIndex: Int) {
        items.map { $0.viewController }.forEach { viewController in
            viewController.view.isHidden = true
        }
        items[safe: selectedTabIndex]?.viewController.view.isHidden = false
    }
}
