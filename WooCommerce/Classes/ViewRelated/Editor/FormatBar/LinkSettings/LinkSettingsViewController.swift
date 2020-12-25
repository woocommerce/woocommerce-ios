import UIKit
import Yosemite

struct LinkSettings {
    var url: String
    var text: String
    var openInNewWindow: Bool
    var isNewLink: Bool

    init(url: String, text: String, openInNewWindow: Bool, isNewLink: Bool) {
        self.url = url
        self.text = text
        self.openInNewWindow = openInNewWindow
        self.isNewLink = isNewLink
    }
}

enum LinkAction {
    case insert
    case update
    case remove
    case cancel
}

/// Allows the user to update the settings for a link text.
///
final class LinkSettingsViewController: UIViewController {
    typealias LinkCallback = (_ action: LinkAction, _ settings: LinkSettings) -> ()

    private var linkSettings: LinkSettings

    /// Table Sections to be rendered
    ///
    private var sections = [Section]()
    private let callback: LinkCallback?

    @IBOutlet private weak var tableView: UITableView!

    init(linkSettings: LinkSettings, callback: @escaping LinkCallback) {
        self.linkSettings = linkSettings
        self.callback = callback
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureNavigation()
        configureMainView()
        configureTableView()
        configureSections()
        registerTableViewCells()
        updateNavigation()
    }
}

// MARK: Actions
//
private extension LinkSettingsViewController {
    func editURL() {
        let placeholder = NSLocalizedString("Please enter a URL", comment: "Placeholder for editing the URL of a text link")
        let navigationTitle = NSLocalizedString("URL", comment: "Navigation bar title for editing the URL of a text link")
        let textViewController = TextViewViewController(text: linkSettings.url,
                                                        placeholder: placeholder,
                                                        navigationTitle: navigationTitle,
                                                        keyboardType: .URL,
                                                        autocapitalizationType: .none) { [weak self] text in
                                                            self?.linkSettings.url = text ?? ""
                                                            self?.updateUI()
                                                            self?.navigationController?.popViewController(animated: true)
        }
        navigationController?.pushViewController(textViewController, animated: true)
    }

    func editTitle() {
        let placeholder = NSLocalizedString("Please enter some text", comment: "Placeholder for editing the text of a text link")
        let navigationTitle = NSLocalizedString("Link Text", comment: "Navigation bar title for editing the text of a text link")
        let textViewController = TextViewViewController(text: linkSettings.text,
                                                        placeholder: placeholder,
                                                        navigationTitle: navigationTitle) { [weak self] text in
                                                            self?.linkSettings.text = text ?? ""
                                                            self?.updateUI()
                                                            self?.navigationController?.popViewController(animated: true)
        }
        navigationController?.pushViewController(textViewController, animated: true)
    }

    func editOpenInNewWindow(value: Bool) {
        linkSettings.openInNewWindow = value
    }

    func removeLink() {
        callback?(.remove, linkSettings)
    }
}

// MARK: Updates
//
private extension LinkSettingsViewController {
    func updateUI() {
        updateNavigation()
        tableView.reloadData()
    }

    func updateNavigation() {
        navigationItem.rightBarButtonItem?.isEnabled = linkSettings.url.isEmpty == false
    }
}

// MARK: Navigation Actions
//
private extension LinkSettingsViewController {
    @objc func insertLink() {
        callback?(.insert, linkSettings)
    }

    @objc func updateLink() {
        callback?(.update, linkSettings)
    }

    @objc func cancelChanges() {
        callback?(.cancel, linkSettings)
    }
}

// MARK: - UITableViewDelegate Conformance
//
extension LinkSettingsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        switch rowAtIndexPath(indexPath) {
        case .url:
            editURL()
        case .text:
            editTitle()
        case .removeLink:
            removeLink()
        default:
            break
        }
    }
}

// MARK: - UITableViewDataSource Conformance
//
extension LinkSettingsViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].rows.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = rowAtIndexPath(indexPath)
        let cell = tableView.dequeueReusableCell(withIdentifier: row.reuseIdentifier, for: indexPath)
        configure(cell, for: row, at: indexPath)

        return cell
    }
}

// MARK: - Convenience Methods
//
private extension LinkSettingsViewController {
    func rowAtIndexPath(_ indexPath: IndexPath) -> Row {
        return sections[indexPath.section].rows[indexPath.row]
    }
}

private extension LinkSettingsViewController {
    private func configureNavigation() {
        title = NSLocalizedString("Link Settings", comment: "Title for screen in editor that allows to configure link options")
        let insertTitle = NSLocalizedString("Insert", comment: "Label action for inserting a link on the editor")
        let updateTitle = NSLocalizedString("Update", comment: "Label action for updating a link on the editor")

        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelChanges))

        if linkSettings.isNewLink {
            navigationItem.rightBarButtonItem = UIBarButtonItem(title: insertTitle, style: .done, target: self, action: #selector(insertLink))
        } else {
            navigationItem.rightBarButtonItem = UIBarButtonItem(title: updateTitle, style: .done, target: self, action: #selector(updateLink))
        }
    }

    func configureMainView() {
        view.backgroundColor = .listBackground
    }

    func configureTableView() {
        tableView.rowHeight = UITableView.automaticDimension
        tableView.backgroundColor = .listBackground

        tableView.delegate = self
        tableView.dataSource = self
    }

    func configureSections() {
        let optionalRemoveLinkSection = linkSettings.isNewLink ? []: [Section(title: nil, rows: [.removeLink])]
        sections = [Section(title: nil, rows: [.url, .text, .openInNewWindow])]
            + optionalRemoveLinkSection
    }

    func registerTableViewCells() {
        for row in Row.allCases {
            tableView.registerNib(for: row.type)
        }
    }

    /// Cells currently configured in the order they appear on screen.
    ///
    func configure(_ cell: UITableViewCell, for row: Row, at indexPath: IndexPath) {
        switch cell {
        case let cell as TitleAndValueTableViewCell where row == .url:
            configureURL(cell: cell)
        case let cell as TitleAndValueTableViewCell where row == .text:
            configureText(cell: cell)
        case let cell as SwitchTableViewCell where row == .openInNewWindow:
            configureOpenInNewWindow(cell: cell)
        case let cell as BasicTableViewCell where row == .removeLink:
            configureRemoveLink(cell: cell)
        default:
            fatalError()
        }
    }

    func configureURL(cell: TitleAndValueTableViewCell) {
        let title = NSLocalizedString("URL", comment: "URL text field placeholder")
        let value = linkSettings.url
        cell.updateUI(title: title, value: value)
        cell.accessoryType = .disclosureIndicator
    }

    func configureText(cell: TitleAndValueTableViewCell) {
        let title = NSLocalizedString("Link Text", comment: "Label for the text of a link in the editor")
        let value = linkSettings.text
        cell.updateUI(title: title, value: value)
        cell.accessoryType = .disclosureIndicator
    }

    func configureOpenInNewWindow(cell: SwitchTableViewCell) {
        cell.title = NSLocalizedString("Open in a new Window/Tab", comment: "Label for the description of openening a link using a new window")
        cell.isOn = linkSettings.openInNewWindow
        cell.onChange = { [weak self] value in
            self?.editOpenInNewWindow(value: value)
        }
    }

    func configureRemoveLink(cell: BasicTableViewCell) {
        cell.textLabel?.text = NSLocalizedString("Remove Link", comment: "Label action for removing a link from the editor")
        cell.textLabel?.textColor = .error
    }
}

// MARK: - Private Types
//
private extension LinkSettingsViewController {
    enum Constants {
        static let rowHeight = CGFloat(44)
    }

    struct Section {
        let title: String?
        let rows: [Row]
    }

    enum Row: CaseIterable {
        case url
        case text
        case openInNewWindow
        case removeLink

        var type: UITableViewCell.Type {
            switch self {
            case .url:
                return TitleAndValueTableViewCell.self
            case .text:
                return TitleAndValueTableViewCell.self
            case .openInNewWindow:
                return SwitchTableViewCell.self
            case .removeLink:
                return BasicTableViewCell.self
            }
        }

        var reuseIdentifier: String {
            return type.reuseIdentifier
        }
    }
}
