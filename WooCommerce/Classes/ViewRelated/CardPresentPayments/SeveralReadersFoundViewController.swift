import UIKit

final class SeveralReadersFoundViewController: UIViewController, UITableViewDelegate {

    @IBOutlet private weak var containerView: UIView!

    @IBOutlet private weak var headlineLabel: UILabel!
    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private weak var cancelButton: UIButton!

    @IBOutlet private weak var viewTrailingConstraint: NSLayoutConstraint!
    @IBOutlet private weak var viewBottomConstraint: NSLayoutConstraint!
    @IBOutlet private weak var viewTopConstraint: NSLayoutConstraint!
    @IBOutlet private weak var viewLeadingConstraint: NSLayoutConstraint!

    private var sections = [Section]()

    private var readerIDs = [String]()
    private var onConnect: ((String) -> Void)?
    private var onCancel: (() -> Void)?

    init() {
        super.init(nibName: Self.nibName, bundle: nil)

        modalPresentationStyle = .overFullScreen
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setBackgroundColor()
        registerTableViewCells()
        configureNavigation()
        configureSections()
        configureTable()
        updateViewMargins()
        updateViewAppearances()
    }

    /// Update constraints that vary by size class
    ///
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        /// Handle size class and orientation
        ///
        updateViewMargins()

        /// Handle changes to Light / Dark Appearance
        ///
        if let previousTraits = previousTraitCollection, previousTraits.hasDifferentColorAppearance(comparedTo: traitCollection) {
            updateViewAppearances()
        }
    }

    func configureController(readerIDs: [String], connect: @escaping ((String) -> Void), cancelSearch: @escaping (() -> Void)) {
        self.readerIDs = readerIDs
        onConnect = connect
        onCancel = cancelSearch
    }

    func updateReaderIDs(readerIDs: [String]) {
        self.readerIDs = readerIDs
        configureSections()
        tableView?.reloadData()
    }
}

// MARK: - View Configuration
//
private extension SeveralReadersFoundViewController {
    func setBackgroundColor() {
        containerView.backgroundColor = .tertiarySystemBackground
    }

    func configureNavigation() {
        headlineLabel.text = Localization.headline
        cancelButton.setTitle(Localization.cancel, for: .normal)
        cancelButton.on(.touchUpInside) { [weak self] _ in
            self?.didTapCancel()
        }
    }

    /// Setup the sections in this table view
    ///
    func configureSections() {
        sections = []

        // Prepare a row for each reader
        let readerRows = readerIDs.map { Row.reader($0) }

        sections.append(
            Section(rows: readerRows)
        )

        // Prepare a row for our scanning indicator
        sections.append(
            Section(rows: [.scanning])
        )
    }

    func configureTable() {
        tableView.rowHeight = UITableView.automaticDimension
        tableView.dataSource = self
        tableView.delegate = self
        tableView.reloadData()
    }

    /// Update the overall view's margins depending on the size classes of the device
    /// for its present orientation
    ///
    func updateViewMargins() {
        /// Vertically constrained? Reduce top and bottom constraints
        ///
        if traitCollection.verticalSizeClass == .compact {
            viewTopConstraint.constant = CompactConstraintConstants.top
            viewBottomConstraint.constant = CompactConstraintConstants.bottom
        } else {
            viewTopConstraint.constant = RegularConstraintConstants.top
            viewBottomConstraint.constant = RegularConstraintConstants.bottom
        }

        /// Horizontally unconstrained? Increase leading and trailing constraints
        if traitCollection.horizontalSizeClass == .compact {
            viewLeadingConstraint.constant = CompactConstraintConstants.leading
            viewTrailingConstraint.constant = CompactConstraintConstants.trailing
        } else {
            viewLeadingConstraint.constant = RegularConstraintConstants.leading
            viewTrailingConstraint.constant = RegularConstraintConstants.trailing
        }
    }

    /// Update views that change appearance for light vs. dark mode
    ///
    func updateViewAppearances() {
        cancelButton.applySecondaryButtonStyle()
    }

    /// Register table cells.
    ///
    func registerTableViewCells() {
        tableView.registerNib(for: Row.reader("").type)
        tableView.registerNib(for: Row.scanning.type)
    }

    /// Configure the cell being set up for the given row by `cellForRowAt`
    ///
    func configure(_ cell: UITableViewCell, for row: Row, at indexPath: IndexPath) {
        switch row {
        case .reader(let readerID):
            configureReaderRow(cell: cell, readerID: readerID)
        case .scanning:
            configureScanningRow(cell: cell)
        }
    }

    func configureReaderRow(cell: UITableViewCell, readerID: String) {
        guard let cell = cell as? LabelAndButtonTableViewCell else {
            return
        }
        cell.configure(
            labelText: readerID,
            buttonTitle: Localization.connect,
            didTapButton: {
                self.didTapConnect(readerID: readerID)
            }
        )
        cell.selectionStyle = .none
    }

    func configureScanningRow(cell: UITableViewCell) {
        guard let cell = cell as? ActivitySpinnerAndLabelTableViewCell else {
            return
        }
        cell.configure(labelText: Localization.scanningLabel)
        cell.selectionStyle = .none
    }

    enum CompactConstraintConstants {
        static let top: CGFloat = 47
        static let leading: CGFloat = 47
        static let trailing: CGFloat = -47
        static let bottom: CGFloat = -47
    }

    enum RegularConstraintConstants {
        static let top: CGFloat = 125
        static let leading: CGFloat = 160
        static let trailing: CGFloat = -160
        static let bottom: CGFloat = -197
    }
}

// MARK: - Actions
//
private extension SeveralReadersFoundViewController {
    @objc func didTapConnect(readerID: String) {
        self.dismiss(animated: true, completion: {
            self.onConnect?(readerID)
        })
    }

    @objc func didTapCancel() {
        self.dismiss(animated: true, completion: {
            self.onCancel?()
        })
    }
}

// MARK: - Convenience Methods
//
private extension SeveralReadersFoundViewController {

    func rowAtIndexPath(_ indexPath: IndexPath) -> Row {
        return sections[indexPath.section].rows[indexPath.row]
    }
}

// MARK: - UITableViewDataSource Conformance
//
extension SeveralReadersFoundViewController: UITableViewDataSource {
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

// MARK: - Private Types
//
private struct Section {
    let rows: [Row]
}

private enum Row {
    /// Two or more `.reader` rows have their reader IDs as their associated (String) value
    /// and are used to display the reader IDs and their connect buttons
    ///
    case reader(String)

    /// A single `.scanning` row is used to show that we are actively scanning for
    /// more readers
    ///
    case scanning

    var type: UITableViewCell.Type {
        switch self {
        case .reader:
            return LabelAndButtonTableViewCell.self
        case .scanning:
            return ActivitySpinnerAndLabelTableViewCell.self
        }
    }

    var height: CGFloat {
        return UITableView.automaticDimension
    }

    var reuseIdentifier: String {
        return type.reuseIdentifier
    }
}

// MARK: - Localization
//
private extension SeveralReadersFoundViewController {
    enum Localization {
        static let headline = NSLocalizedString(
            "Several readers found",
            comment: "Title of a modal presenting a list of readers to choose from."
        )

        static let connect = NSLocalizedString(
            "Connect",
            comment: "Button in a cell to allow the user to connect to that reader for that cell"
        )

        static let scanningLabel = NSLocalizedString(
            "Scanning for readers",
            comment: "Label for a cell informing the user that reader scanning is ongoing."
        )

        static let cancel = NSLocalizedString(
            "Cancel",
            comment: "Button to allow the user to close the modal without connecting."
        )
    }
}
