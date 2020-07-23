import UIKit
import Yosemite
import WordPressUI

/// ProductTagsViewController: Displays the list of ProductTag associated to the active Site and to the specific product.
///
final class ProductTagsViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    private let ghostTableView = UITableView()
    @IBOutlet weak var textView: UITextView!


    private var product: Product

    private let viewModel: ProductTagsViewModel

    // Completion callback
    //
    typealias Completion = (_ tags: [ProductTag]) -> Void
    private let onCompletion: Completion

    init(product: Product, completion: @escaping Completion) {
        self.product = product
        self.viewModel = ProductTagsViewModel(product: product)
        onCompletion = completion
        super.init(nibName: type(of: self).nibName, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        configureNavigationBar()
        configureMainView()
        configureTextView()
        configureTableView()
        configureGhostTableView()
        configureViewModel()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        textView.becomeFirstResponder()
    }

}

// MARK: - View Configuration
//
private extension ProductTagsViewController {

    func configureNavigationBar() {
        title = NSLocalizedString("Tags", comment: "Product Tags navigation title")

        removeNavigationBackBarButtonText()
    }

    func configureMainView() {
        view.backgroundColor = .listBackground
    }

    func configureTextView() {
        textView.delegate = self
        textView.autocorrectionType = .yes
        textView.autocapitalizationType = .none
        textView.font = .body
        textView.textColor = .text
        textView.isScrollEnabled = false
        // Padding already provided by readable margins
        // Don't add extra padding so text aligns with suggestions
        textView.textContainer.lineFragmentPadding = 0
        textView.textContainerInset = UIEdgeInsets(top: 11, left: 0, bottom: 11, right: 0)
        textView.accessibilityLabel = NSLocalizedString("Add new tags, separated by commas.",
                                                        comment: "Voiceover accessibility label for the tags field in product tags.")
        textView.accessibilityIdentifier = "add-tags"
    }

    func configureTableView() {
        registerTableViewCells()
        tableView.dataSource = self
        tableView.delegate = self

        tableView.backgroundColor = .listBackground
        tableView.removeLastCellSeparator()
    }

    func configureGhostTableView() {
        view.addSubview(ghostTableView)
        ghostTableView.isHidden = true
        ghostTableView.translatesAutoresizingMaskIntoConstraints = false
        ghostTableView.pinSubviewToAllEdges(view)
        ghostTableView.backgroundColor = .listBackground
        ghostTableView.removeLastCellSeparator()
    }

    /// Registers all of the available TableViewCells
    ///
    func registerTableViewCells() {
        tableView.register(BasicTableViewCell.loadNib(), forCellReuseIdentifier: BasicTableViewCell.reuseIdentifier)
        ghostTableView.register(BasicTableViewCell.loadNib(), forCellReuseIdentifier: BasicTableViewCell.reuseIdentifier)
    }
}

// MARK: - Synchronize Tags
//
private extension ProductTagsViewController {
    func configureViewModel() {
        viewModel.performFetch()
        viewModel.observeTagListStateChanges { [weak self] syncState in
            switch syncState {
            case .initialized:
                break
            case .syncing:
                self?.displayGhostTableView()
            case let .failed(retryToken):
                self?.removeGhostTableView()
                self?.displaySyncingErrorNotice(retryToken: retryToken)
            case .synced:
                self?.removeGhostTableView()
            }
        }
    }
}

// MARK: - Placeholders & Errors
//
private extension ProductTagsViewController {

    /// Renders ghost placeholder categories.
    ///
    func displayGhostTableView() {
        let placeholderTagsPerSection = [3]
        let options = GhostOptions(displaysSectionHeader: true,
                                   reuseIdentifier: BasicTableViewCell.reuseIdentifier,
                                   rowsPerSection: placeholderTagsPerSection)
        ghostTableView.displayGhostContent(options: options,
                                           style: .wooDefaultGhostStyle)
        ghostTableView.isHidden = false
    }

    /// Removes ghost  placeholder categories.
    ///
    func removeGhostTableView() {
        tableView.reloadData()
        ghostTableView.removeGhostContent()
        ghostTableView.isHidden = true
    }

    /// Displays the Sync Error Notice.
    ///
    func displaySyncingErrorNotice(retryToken: ProductTagsViewModel.RetryToken) {
        let message = NSLocalizedString("Unable to load tags", comment: "Load Product Tags Action Failed")
        let actionTitle = NSLocalizedString("Retry", comment: "Retry Action")
        let notice = Notice(title: message, feedbackType: .error, actionTitle: actionTitle) { [weak self] in
            self?.viewModel.retryTagSynchronization(retryToken: retryToken)
        }

        ServiceLocator.noticePresenter.enqueue(notice: notice)
    }
}

// MARK: - UITableViewDataSource Conformance
//
extension ProductTagsViewController: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.sections[section].rows.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = viewModel.sections[indexPath.section].rows[indexPath.row]

        let cell = tableView.dequeueReusableCell(withIdentifier: row.reuseIdentifier, for: indexPath)
        configure(cell, for: row, at: indexPath)

        return cell
    }
}

// MARK: - UITableViewDelegate Conformance
//
extension ProductTagsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

// MARK: - Support for UITableViewDataSource
//
private extension ProductTagsViewController {
    /// Configure cellForRowAtIndexPath:
    ///
    func configure(_ cell: UITableViewCell, for row: ProductTagsViewModel.Row, at indexPath: IndexPath) {
        switch cell {
        case let cell as BasicTableViewCell:
            configureTag(cell: cell, indexPath: indexPath)
        default:
            fatalError("Unidentified product slug row type")
        }
    }

    func configureTag(cell: BasicTableViewCell, indexPath: IndexPath) {
        cell.textLabel?.text = viewModel.fetchedTags[indexPath.row].name
    }
}

// MARK: - Text & Input Handling

extension ProductTagsViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        guard textView.markedTextRange == nil else {
            // Don't try to normalize if we're still in multistage input
            return
        }
        normalizeText()
        updateSuggestions()
    }

    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        let original = textView.text as NSString
        if range.length == 0,
            range.location == original.length,
            text == ",",
            partialTag.isEmpty {
            // Don't allow a second comma if the last tag is blank
            return false
        } else if
            range.length == 1 && text == "", // Deleting last character
            range.location > 0, // Not at the beginning
            range.location + range.length == original.length, // At the end
            original.substring(with: NSRange(location: range.location - 1, length: 1)) == "," // Previous is a comma
        {
            // Delete the comma as well
            textView.text = original.substring(to: range.location - 1) + original.substring(from: range.location + range.length)
            textView.selectedRange = NSRange(location: range.location - 1, length: 0)
            textViewDidChange(textView)
            return false
        } else if range.length == 0, // Inserting
            text == ",", // a comma
            range.location == original.length // at the end
        {
            // Append a space
            textView.text = original.replacingCharacters(in: range, with: ", ")
            textViewDidChange(textView)
            return false
        } else if text == "\n", // return
            range.location == original.length, // at the end
            !partialTag.isEmpty // with some (partial) tag typed
        {
            textView.text = original.replacingCharacters(in: range, with: ", ")
            textViewDidChange(textView)
            return false
        } else if text == "\n" // return anywhere else
            {
                return false
        }
        return true
    }

    fileprivate func normalizeText() {
        // Remove any space before a comma, and allow one space at most after.
        let regexp = try! NSRegularExpression(pattern: "\\s*(,(\\s|(\\s(?=\\s)))?)\\s*", options: [])
        let text = textView.text ?? ""
        let range = NSRange(location: 0, length: (text as NSString).length)
        textView.text = regexp.stringByReplacingMatches(in: text, options: [], range: range, withTemplate: "$1")
    }

    /// Normalize tags for initial set up.
    ///
    /// The algorithm here differs slightly as we don't want to interpret the last tag as a partial one.
    ///
    fileprivate func normalizeInitialTags(tags: [String]) -> String {
        var tags = tags.filter({ !$0.isEmpty })
        tags.append("")
        return tags.joined(separator: ", ")
    }

    fileprivate func updateSuggestions() {
        //TODO: to be implemented
//        dataSource.selectedTags = completeTags
//        dataSource.searchQuery = partialTag
//        reloadTableData()
    }
}


// MARK: - Tag tokenization

/*
 There are two different "views" of the tag list:

 1. For completion purposes, everything before the last comma is a "completed"
    tag, and will not appear again in suggestions. The text after the last comma
    (or the whole text if there is no comma) will be interpreted as a partially
    typed tag (parialTag) and used to filter suggestions.

 2. The above doesn't apply when it comes to reporting back the tag list, and so
    we use `allTags` for all the tags in the text view. In this case the last
    part of text is considered as a complete tag as well.

 */
private extension ProductTagsViewController {
    static func extractTags(from string: String) -> [String] {
        return string.components(separatedBy: ",")
            .map({ $0.trimmingCharacters(in: .whitespacesAndNewlines) })
    }

    var tagsInField: [String] {
        return ProductTagsViewController.extractTags(from: "") //TODO: textView.text
    }

    var partialTag: String {
        return tagsInField.last ?? ""
    }

    var completeTags: [String] {
        return Array(tagsInField.dropLast())
    }

    var allTags: [String] {
        return tagsInField.filter({ !$0.isEmpty })
    }

    func complete(tag: String) {
        var tags = completeTags
        tags.append(tag)
        tags.append("")
        textView.text = tags.joined(separator: ", ")
        updateSuggestions()
    }
}
