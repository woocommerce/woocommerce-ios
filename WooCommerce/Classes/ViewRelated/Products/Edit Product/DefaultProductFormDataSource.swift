import UIKit

/// The Product form contains 3 sections: images, primary fields, and details.
final class DefaultProductFormDataSource: NSObject, ProductFormDataSource {

    enum Section {
        case images
        case primaryFields(rows: [PrimaryFieldRow])
        case details(rows: [DetailRow])
    }

    enum PrimaryFieldRow {
        case title
        case description
    }

    enum DetailRow {
        case price
        case shipping
        case inventory
    }

    private let sections: [Section]

    override init() {
        sections = [
            .images,
            .primaryFields(rows: []),
            .details(rows: [])
        ]
        super.init()
    }
}

extension DefaultProductFormDataSource: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let section = sections[section]
        switch section {
        case .images:
            return 0
        case .primaryFields(let rows):
            return rows.count
        case .details(let rows):
            return rows.count
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        fatalError("Not implemented yet")
    }
}
