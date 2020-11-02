import UIKit


/// ProductTagsDataSource: Data Sources for Product Tags
///
protocol ProductTagsDataSource: UITableViewDataSource {
}

final class LoadingDataSource: NSObject, ProductTagsDataSource {

    private static let cellIdentifier = BasicTableViewCell.reuseIdentifier

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

final class FailureDataSource: NSObject, ProductTagsDataSource {

    private static let cellIdentifier = BasicTableViewCell.reuseIdentifier

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

final class SuggestionsDataSource: NSObject, ProductTagsDataSource {
    private static let cellIdentifier = BasicTableViewCell.reuseIdentifier
    private let suggestions: [String]
    var selectedTags: [String]
    var searchQuery: String

    init(suggestions: [String], selectedTags: [String], searchQuery: String) {
        self.suggestions = suggestions
        self.selectedTags = selectedTags
        self.searchQuery = searchQuery
        super.init()
    }

    private var availableSuggestions: [String] {
        return suggestions.filter({ !selectedTags.contains($0) })
    }

    private var matchedSuggestions: [String] {
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
