import UIKit
import Vision

protocol TrackingNumberImageDetectionResult {
    var string: String { get }
}

class TrackingNumberImageDetectionResultsViewController: UIViewController {
    // MARK: subviews
    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.tableFooterView = UIView(frame: .zero)
        return tableView
    }()

    private lazy var imageView: UIImageView = {
        return UIImageView(image: image)
    }()

    // MARK: init properties
    private let image: UIImage
    private let results: [TrackingNumberImageDetectionResult]

    typealias OnResultSelection = (_ string: String) -> ()
    private let onResultSelection: OnResultSelection

    init(image: UIImage, results: [TrackingNumberImageDetectionResult], onResultSelection: @escaping OnResultSelection) {
        self.image = image
        self.results = results
        self.onResultSelection = onResultSelection
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = NSLocalizedString("Tap the correct number", comment: "")

        view.backgroundColor = UIColor.white

        let stackView = UIStackView(arrangedSubviews: [imageView, tableView])
        view.addSubview(stackView)
        view.pinSubviewToAllEdges(stackView)

        configure(imageView: imageView)
        configure(tableView: tableView)
        configure(stackView: stackView)
    }
}

private extension TrackingNumberImageDetectionResultsViewController {
    func configure(stackView: UIStackView) {
        stackView.axis = .vertical
        stackView.translatesAutoresizingMaskIntoConstraints = false
    }

    func configure(imageView: UIImageView) {
        imageView.image = image
        imageView.contentMode = .scaleAspectFit
    }

    func configure(tableView: UITableView) {
        let cells = [StatusListTableViewCell.self]
        for cell in cells {
            tableView.register(cell.loadNib(), forCellReuseIdentifier: cell.reuseIdentifier)
        }
        tableView.dataSource = self
        tableView.delegate = self
    }
}

extension TrackingNumberImageDetectionResultsViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return results.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: StatusListTableViewCell.reuseIdentifier,
                                                       for: indexPath) as? StatusListTableViewCell else {
                                                        fatalError()
        }
        let result = results[indexPath.row]
        cell.textLabel?.text = result.string
        return cell
    }
}

extension TrackingNumberImageDetectionResultsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let result = results[indexPath.row]
        onResultSelection(result.string)
    }
}
