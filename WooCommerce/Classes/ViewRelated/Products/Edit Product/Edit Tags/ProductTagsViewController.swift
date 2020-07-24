import UIKit
import Yosemite


/// ProductTagsViewController: Displays the list of ProductTag associated to the active Site and to the specific product.
///
final class ProductTagsViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var textView: UITextView!
    @IBOutlet var separatorView: UIView!

    private var product: Product

    private let originalTags: [String]

    private var fetchedTags: [ProductTag] {
        try? resultController.performFetch()
        return resultController.fetchedObjects
    }

    private var dataSource: ProductTagsDataSource = LoadingDataSource() {
        didSet {
            tableView.dataSource = dataSource
            tableView.reloadData()
        }
    }

    private lazy var resultController: ResultsController<StorageProductTag> = {
        let storageManager = ServiceLocator.storageManager
        let predicate = NSPredicate(format: "siteID = %ld", self.product.siteID)
        let descriptor = NSSortDescriptor(keyPath: \StorageProductTag.name, ascending: true)
        return ResultsController<StorageProductTag>(storageManager: storageManager, matching: predicate, sortedBy: [descriptor])
    }()

    /// Keyboard management
    ///
    private lazy var keyboardFrameObserver: KeyboardFrameObserver = KeyboardFrameObserver { [weak self] keyboardFrame in
        self?.handleKeyboardFrameUpdate(keyboardFrame: keyboardFrame)
    }


    // Completion callback
    //
    typealias Completion = (_ tags: [ProductTag]) -> Void
    private let onCompletion: Completion

    init(product: Product, completion: @escaping Completion) {
        self.product = product
        originalTags = product.tags.map { $0.name }
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
        configureSeparator()
        configureTableView()
        startListeningToNotifications()

        textView.text = normalizeInitialTags(tags: originalTags)
        textViewDidChange(textView)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        textView.becomeFirstResponder()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        updateSuggestions()
        loadTags()
    }

    override func viewWillDisappear(_ animated: Bool) {
           super.viewWillDisappear(animated)
           textView.resignFirstResponder()
       }
}

// MARK: - View Configuration
//
private extension ProductTagsViewController {

    func configureNavigationBar() {
        title = Strings.title

        removeNavigationBackBarButtonText()
        configureRightBarButtomitemAsSave()
    }

    func configureRightBarButtomitemAsSave() {
        navigationItem.setRightBarButton(UIBarButtonItem(title: Strings.saveButton,
                                                         style: .done,
                                                         target: self,
                                                         action: #selector(addTagsRemotely)),
                                         animated: true)
        navigationItem.rightBarButtonItem?.isEnabled = true
    }

    func configureRightButtonItemAsSpinner() {
        let activityIndicator = UIActivityIndicatorView(style: .white)
        activityIndicator.hidesWhenStopped = true
        activityIndicator.startAnimating()

        let rightBarButton = UIBarButtonItem(customView: activityIndicator)

        navigationItem.setRightBarButton(rightBarButton, animated: true)
        navigationItem.rightBarButtonItem?.isEnabled = false
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
        textView.accessibilityLabel = Strings.accessibilityLabel
        textView.accessibilityIdentifier = "add-tags"
    }

    func configureSeparator() {
        separatorView.backgroundColor = .divider
    }

    func configureTableView() {
        registerTableViewCells()
        // The datasource will be dinamically assigned on variable `datasource`
        tableView.delegate = self

        tableView.backgroundColor = .listBackground
        tableView.removeLastCellSeparator()
    }

    /// Registers all of the available TableViewCells
    ///
    func registerTableViewCells() {
        tableView.register(BasicTableViewCell.loadNib(), forCellReuseIdentifier: BasicTableViewCell.reuseIdentifier)
    }
}

// MARK: - Navigation actions handling
//
extension ProductTagsViewController {

    override func shouldPopOnBackButton() -> Bool {
        if hasUnsavedChanges() {
            presentBackNavigationActionSheet()
            return false
        }
        return true
    }

    func hasUnsavedChanges() -> Bool {
        return product.tags.sorted() != mergeTags(tags: allTags, fetchedTags: fetchedTags).sorted()
    }

    override func shouldPopOnSwipeBack() -> Bool {
        return shouldPopOnBackButton()
    }

    private func presentBackNavigationActionSheet() {
        UIAlertController.presentDiscardChangesActionSheet(viewController: self, onDiscard: { [weak self] in
            self?.navigationController?.popViewController(animated: true)
        })
    }
}

// MARK: - Keyboard management
//
private extension ProductTagsViewController {
    /// Registers for all of the related Notifications
    ///
    func startListeningToNotifications() {
        keyboardFrameObserver.startObservingKeyboardFrame()
    }
}

extension ProductTagsViewController: KeyboardScrollable {
    var scrollable: UIScrollView {
        return tableView
    }
}

// MARK: - Synchronize Tags
//
private extension ProductTagsViewController {
    func loadTags() {
        dataSource = LoadingDataSource()

        let action = ProductTagAction.synchronizeAllProductTags(siteID: product.siteID) { [weak self] error in
            guard error == nil else {
                self?.tagsFailedLoading()
                return
            }

            if let tagNames = self?.fetchedTags.map({ $0.name }) {
                self?.tagsLoaded(tags: tagNames)
            }
        }
        ServiceLocator.stores.dispatch(action)
    }

    func tagsLoaded(tags: [String]) {
        dataSource = SuggestionsDataSource(suggestions: tags,
                                           selectedTags: completeTags,
                                           searchQuery: partialTag)
    }

    @objc func addTagsRemotely() {
        textView.resignFirstResponder()
        configureRightButtonItemAsSpinner()

        let action = ProductTagAction.addProductTags(siteID: product.siteID, tags: allTags) { [weak self] (result) in
            guard let self = self else {
                return
            }
            self.configureRightBarButtomitemAsSave()
            switch result {
            case .success:
                let mergedTags = self.mergeTags(tags: self.allTags, fetchedTags: self.fetchedTags)
                self.onCompletion(mergedTags)
            case .failure(let error):
                self.displayErrorAlert(error: error)
            }
        }
        ServiceLocator.stores.dispatch(action)
    }

}

// MARK: Error handling
//
private extension ProductTagsViewController {
    func displayErrorAlert(error: Error?) {
        let alertController = UIAlertController(title: Strings.errorAlertTitle,
                                                message: error?.localizedDescription,
                                                preferredStyle: .alert)
        let cancel = UIAlertAction(title: Strings.okErrorAlertButton,
                                   style: .cancel,
                                   handler: nil)
        alertController.addAction(cancel)
        present(alertController, animated: true)
    }

    func tagsFailedLoading() {
        DDLogError("Error loading product tags")
        dataSource = FailureDataSource()
        UIApplication.shared.keyWindow?.endEditing(true)
        let errorMessage = Strings.errorLoadingTags
        let notice = Notice(title: errorMessage, feedbackType: .error)
        ServiceLocator.noticePresenter.enqueue(notice: notice)
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
        return ProductTagsViewController.extractTags(from: textView.text)
    }

    var partialTag: String {
        return tagsInField.last ?? ""
    }

    var completeTags: [String] {
        return Array(tagsInField.dropLast())
    }

    var allTags: [String] {
        let tags = tagsInField.filter({ !$0.isEmpty })
        return tags
    }

    func complete(tag: String) {
        var tags = completeTags
        tags.append(tag)
        tags.append("")
        textView.text = tags.joined(separator: ", ")
        updateSuggestions()
    }

    func mergeTags(tags: [String], fetchedTags: [ProductTag]) -> [ProductTag] {
        var finalTags: [ProductTag] = []
        for tag in tags {
            for fetchedTag in fetchedTags {
                if tag.lowercased() == fetchedTag.name.lowercased() {
                    finalTags.append(fetchedTag)
                }
            }
        }
        return finalTags
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

    private func normalizeText() {
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
    private func normalizeInitialTags(tags: [String]) -> String {
        var tags = tags.filter({ !$0.isEmpty })
        tags.append("")
        return tags.joined(separator: ", ")
    }

    private func updateSuggestions() {
        dataSource.selectedTags = completeTags
        dataSource.searchQuery = partialTag
        tableView.reloadData()
    }
}

extension ProductTagsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        switch tableView.dataSource {
        case is FailureDataSource:
            loadTags()
        case is LoadingDataSource:
            return
        case is SuggestionsDataSource:
            suggestionTapped(cell: tableView.cellForRow(at: indexPath))
        default:
            assertionFailure("Unexpected data source")
        }
    }

    private func suggestionTapped(cell: UITableViewCell?) {
        guard let tag = cell?.textLabel?.text else {
            return
        }
        complete(tag: tag)
    }
}

// MARK: - Data Sources

private protocol ProductTagsDataSource: UITableViewDataSource {
    var selectedTags: [String] { get set }
    var searchQuery: String { get set }
}

private class LoadingDataSource: NSObject, ProductTagsDataSource {
    var selectedTags = [String]()
    var searchQuery = ""

    static let cellIdentifier = BasicTableViewCell.reuseIdentifier
    typealias Cell = BasicTableViewCell

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: LoadingDataSource.cellIdentifier, for: indexPath)

        cell.textLabel?.text = NSLocalizedString("Loading...", comment: "Loading tags in Product Tags screen")
        cell.selectionStyle = .none
        return cell
    }
}

private class FailureDataSource: NSObject, ProductTagsDataSource {
    var selectedTags = [String]()
    var searchQuery = ""

    static let cellIdentifier = BasicTableViewCell.reuseIdentifier
    typealias Cell = BasicTableViewCell

    func numberOfSections(in tableView: UITableView) -> Int {
        return 0
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: FailureDataSource.cellIdentifier, for: indexPath)
        cell.textLabel?.textColor = .text
        cell.backgroundColor = .listForeground
        return cell
    }
}

private class SuggestionsDataSource: NSObject, ProductTagsDataSource {
    static let cellIdentifier = BasicTableViewCell.reuseIdentifier
    let suggestions: [String]

    init(suggestions: [String], selectedTags: [String], searchQuery: String) {
        self.suggestions = suggestions
        self.selectedTags = selectedTags
        self.searchQuery = searchQuery
        super.init()
    }

    var selectedTags: [String]
    var searchQuery: String

    var availableSuggestions: [String] {
        return suggestions.filter({ !selectedTags.contains($0) })
    }

    var matchedSuggestions: [String] {
        guard !searchQuery.isEmpty else {
            return availableSuggestions
        }
        return availableSuggestions.filter({ $0.localizedStandardContains(searchQuery) })
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return matchedSuggestions.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: SuggestionsDataSource.cellIdentifier, for: indexPath)
        let match = matchedSuggestions[indexPath.row]
        cell.textLabel?.attributedText = highlight(searchQuery, in: match, font: cell.textLabel?.font ?? UIFont())
        return cell
    }

    func highlight(_ search: String, in string: String, font: UIFont) -> NSAttributedString {
        let highlighted = NSMutableAttributedString(string: string)
        let range = (string as NSString).localizedStandardRange(of: search)
        guard range.location != NSNotFound else {
            return highlighted
        }

        let font = UIFont.systemFont(ofSize: font.pointSize, weight: .bold)
        highlighted.setAttributes([.font: font], range: range)
        return highlighted
    }
}

// MARK: - Constants!
//
private extension ProductTagsViewController {
    enum Strings {
        static let title = NSLocalizedString("Tags",
                                             comment: "Product Tags navigation title")
        static let saveButton = NSLocalizedString("Save",
                                                  comment: "Add Product Tags. Save button title in navbar.")
        static let accessibilityLabel = NSLocalizedString("Add new tags, separated by commas.",
                                                          comment: "Voiceover accessibility label for the tags field in product tags.")
        static let errorLoadingTags = NSLocalizedString("Couldn't load tags.",
                                                        comment: "Error message when tag loading failed")
        static let errorAlertTitle = NSLocalizedString("Cannot Add Tags",
                                                       comment: "Title of the alert when there is an error adding new product tags.")
        static let okErrorAlertButton = NSLocalizedString("OK",
                                                          comment: "Dismiss button on the alert when there is an error creating new product tags.")
    }
}
