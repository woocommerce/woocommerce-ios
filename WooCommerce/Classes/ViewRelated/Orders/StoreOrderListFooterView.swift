import SwiftUI

@MainActor
final class StoreOrderListFooterView: UIView {
    private let fillsAvailableHeight: Bool
    private var hostedView: (UIView & UIContentView)?

    init(fillsAvailableHeight: Bool = false) {
        self.fillsAvailableHeight = fillsAvailableHeight
        super.init(frame: .zero)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func setContent<Content: View>(_ content: Content) {
        let configuration = UIHostingConfiguration { content }
            .margins(.all, 0)

        if let hostedView {
            hostedView.configuration = configuration
            return
        }

        let hostedView = configuration.makeContentView()
        hostedView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(hostedView)
        NSLayoutConstraint.activate([
            hostedView.leadingAnchor.constraint(equalTo: leadingAnchor),
            hostedView.trailingAnchor.constraint(equalTo: trailingAnchor),
            hostedView.topAnchor.constraint(equalTo: topAnchor),
            hostedView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        self.hostedView = hostedView
    }

    func show(in tableView: UITableView) {
        guard tableView.tableFooterView !== self else {
            updateHeight(in: tableView)
            return
        }

        UIView.performWithoutAnimation {
            frame.size = fittedSize(in: tableView)
            layoutIfNeeded()
            tableView.tableFooterView = self
        }
    }

    func updateHeight(in tableView: UITableView) {
        guard tableView.tableFooterView === self else { return }
        let size = fittedSize(in: tableView)
        guard frame.size != size else { return }
        UIView.performWithoutAnimation {
            frame.size = size
            layoutIfNeeded()
            tableView.tableFooterView = self
        }
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
