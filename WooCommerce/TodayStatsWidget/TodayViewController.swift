//
//  TodayViewController.swift
//  TodayStatsWidget
//
//  Created by Paolo Musolino on 08/06/2020.
//  Copyright © 2020 Automattic. All rights reserved.
//

import UIKit
import NotificationCenter

final class TodayViewController: UIViewController, NCWidgetProviding {
        
    @IBOutlet private weak var tableView: UITableView!
    
    /// Table Sections to be rendered
    ///
    private var sections: [Section] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        registerTableViewCells()
        sections = [Section(rows: [.example])]
        tableView.reloadData()
    }
        
    func widgetPerformUpdate(completionHandler: (@escaping (NCUpdateResult) -> Void)) {
        // Perform any setup necessary in order to update the view.
        
        // If an error is encountered, use NCUpdateResult.Failed
        // If there's no update required, use NCUpdateResult.NoData
        // If there's an update, use NCUpdateResult.NewData
        
        completionHandler(NCUpdateResult.newData)
    }
 
    func registerTableViewCells() {
        for row in Row.allCases {
            tableView.register(row.type.loadNib(), forCellReuseIdentifier: row.reuseIdentifier)
        }
    }
}

extension TodayViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = sections[indexPath.section].rows[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: row.reuseIdentifier, for: indexPath)
        configure(cell, for: row, at: indexPath)

        return cell
    }
    

}

extension TodayViewController: UITableViewDelegate {
    
}

// MARK: - Cell configuration
//
private extension TodayViewController {
    /// Cells currently configured in the order they appear on screen
    ///
    func configure(_ cell: UITableViewCell, for row: Row, at indexPath: IndexPath) {
        switch cell {
        case let cell as BasicTableViewCell where row == .example:
            configureExample(cell: cell)
        default:
            fatalError()
            break
        }
    }
    
    func configureExample(cell: BasicTableViewCell) {
        cell.textLabel?.text = NSLocalizedString("This is a sample cell", comment: "Label action for removing a link from the editor")
        cell.textLabel?.applyLinkBodyStyle()
    }
}
// MARK: - Private Types
//
private extension TodayViewController {

    struct Section {
        let rows: [Row]
    }

    enum Row: CaseIterable {
        case example

        var type: UITableViewCell.Type {
            switch self {
            case .example:
                return BasicTableViewCell.self
            }
        }

        var reuseIdentifier: String {
            return type.reuseIdentifier
        }
    }
}
