import SwiftUI

@MainActor
final class StoreOrderListFooterView: UIView {
    private let fillsAvailableHeight: Bool

    init(fillsAvailableHeight: Bool = false) {
        self.fillsAvailableHeight = fillsAvailableHeight
        super.init(frame: .zero)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func setContent<Content: View>(_ content: Content) {
        subviews.forEach { $0.removeFromSuperview() }

        let hostedView = UIHostingConfiguration { content }
        .margins(.all, 0)
        .makeContentView()
        hostedView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(hostedView)
        NSLayoutConstraint.activate([
            hostedView.leadingAnchor.constraint(equalTo: leadingAnchor),
            hostedView.trailingAnchor.constraint(equalTo: trailingAnchor),
            hostedView.topAnchor.constraint(equalTo: topAnchor),
            hostedView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    func show(in tableView: UITableView) {
        frame.size = fittedSize(in: tableView)
        tableView.tableFooterView = self
    }

    func updateHeight(in tableView: UITableView) {
        guard tableView.tableFooterView === self else { return }
        let size = fittedSize(in: tableView)
        guard frame.size != size else { return }
        frame.size = size
        tableView.tableFooterView = self
    }

    private func fittedSize(in tableView: UITableView) -> CGSize {
        let width = tableView.bounds.width
        let contentSize = systemLayoutSizeFitting(CGSize(width: width, height: 0),
                                                  withHorizontalFittingPriority: .required,
                                                  verticalFittingPriority: .fittingSizeLevel)
        guard fillsAvailableHeight else {
            return CGSize(width: width, height: contentSize.height)
        }

        let availableHeight = tableView.bounds.height - tableView.adjustedContentInset.top - tableView.adjustedContentInset.bottom
            - (tableView.tableHeaderView?.frame.height ?? 0)
        return CGSize(width: width, height: max(contentSize.height, availableHeight))
    }
}
