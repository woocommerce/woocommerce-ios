import XCTest
@testable import WooCommerce

// UITableViewCell+Helpers: Unit Tests
//
final class UITableView_HelpersTests: XCTestCase {

    let tableView = UITableView()
    let emptyTableView = UITableView()
    let tableViewWithoutRows = UITableView()
    
    override func setUp() {
        super.setUp()
        tableView.dataSource = self
        emptyTableView.dataSource = self
        tableViewWithoutRows.dataSource = self
        tableView.reloadData()
    }
    
    func testLastIndexPathWorksLikeExpected() {
        let lastIndexPath = tableView.lastIndexPath()
        XCTAssertEqual(lastIndexPath, IndexPath(row: 7, section: 1))
    }
    
    func testLastIndexPathWithNoSectionsAndRowsReturnNil() {
        let lastIndexPath = emptyTableView.lastIndexPath()
        XCTAssertNil(lastIndexPath)
    }
    
    func testLastIndexPathWithOnlyNoRowsReturnNil() {
        let lastIndexPath = tableViewWithoutRows.lastIndexPath()
        XCTAssertNil(lastIndexPath)
    }

    
}


extension UITableView_HelpersTests: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        switch tableView {
        case self.tableView:
            return 2
        case tableViewWithoutRows:
            return 1
        default:
            return 0
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch tableView {
        case self.tableView:
            return 8
        default:
            return 0
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return UITableViewCell()
    }
}
