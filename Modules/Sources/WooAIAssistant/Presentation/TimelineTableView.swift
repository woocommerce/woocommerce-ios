import SwiftUI
import UIKit

/// UITableView host for the chat transcript. Native diffable updates and self-sizing
/// rows preserve scroll position as new content lands.
struct TimelineTableView: UIViewControllerRepresentable {

    let messages: [ChatMessage]
    let streamingState: AssistantConversation.StreamingState
    @Binding var isNearBottom: Bool
    let scrollToBottomTrigger: Int
    let confirmationHandler: AssistantConfirmationHandler
    let externalNavigation: AssistantExternalNavigationProviding
    let externalViews: AssistantExternalViewProviding

    func makeCoordinator() -> Coordinator {
        Coordinator(isNearBottom: $isNearBottom)
    }

    func makeUIViewController(context: Context) -> TimelineTableViewController {
        let controller = TimelineTableViewController()
        controller.onIsNearBottomChange = { value in
            context.coordinator.update(isNearBottom: value)
        }
        controller.confirmationHandler = confirmationHandler
        controller.externalNavigation = externalNavigation
        controller.externalViews = externalViews
        return controller
    }

    func updateUIViewController(_ controller: TimelineTableViewController, context: Context) {
        // Refresh hosted env values; the parent rebuilds them on every re-eval.
        controller.confirmationHandler = confirmationHandler
        controller.externalNavigation = externalNavigation
        controller.externalViews = externalViews
        controller.apply(messages: messages, streamingState: streamingState)
        if context.coordinator.lastTrigger != scrollToBottomTrigger {
            context.coordinator.lastTrigger = scrollToBottomTrigger
            controller.scrollToLatest(animated: true)
        }
    }

    @MainActor
    final class Coordinator {
        var lastTrigger: Int = 0
        private let isNearBottomBinding: Binding<Bool>

        init(isNearBottom: Binding<Bool>) {
            self.isNearBottomBinding = isNearBottom
        }

        func update(isNearBottom value: Bool) {
            guard isNearBottomBinding.wrappedValue != value else { return }
            // Defer one tick so the binding write does not collide with an in-flight render pass.
            DispatchQueue.main.async {
                if self.isNearBottomBinding.wrappedValue != value {
                    self.isNearBottomBinding.wrappedValue = value
                }
            }
        }
    }
}

enum TimelineSection: Hashable {
    case timeline
}

/// Stable per-row identity. Banner reason is part of the hash so a different reason
/// becomes a row replacement, not a reconfigure.
enum TimelineRowID: Hashable {
    case message(UUID)
    case typingIndicator
    case errorBanner(String)
    case outcomeUnknownBanner(String)
}

@MainActor
final class TimelineTableViewController: UIViewController {

    var onIsNearBottomChange: ((Bool) -> Void)?
    var confirmationHandler: AssistantConfirmationHandler = AssistantConfirmationHandler()
    var externalNavigation: AssistantExternalNavigationProviding = NoOpExternalNavigation()
    var externalViews: AssistantExternalViewProviding = EmptyExternalViews()

    private lazy var tableView: UITableView = {
        let table = UITableView(frame: .zero, style: .plain)
        table.separatorStyle = .none
        table.backgroundColor = .clear
        table.keyboardDismissMode = .interactive
        table.allowsSelection = false
        // No estimatedRowHeight: a non-zero estimate reserves phantom space before self-sizing.
        table.rowHeight = UITableView.automaticDimension
        table.contentInsetAdjustmentBehavior = .automatic
        // Top inset gives the first row breathing room without depending on cell padding.
        table.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 0, right: 0)
        table.showsVerticalScrollIndicator = true
        table.register(TimelineHostingCell.self, forCellReuseIdentifier: TimelineHostingCell.reuseID)
        table.translatesAutoresizingMaskIntoConstraints = false
        return table
    }()

    private var dataSource: UITableViewDiffableDataSource<TimelineSection, TimelineRowID>!
    private var messagesByID: [UUID: ChatMessage] = [:]
    private var lastIsNearBottom: Bool = true

    /// While the merchant is actively dragging, defer snapshot applies. Otherwise
    /// streaming bursts reflow content under the finger and read as jitter.
    private var isDraggingScrollView = false {
        didSet {
            guard !isDraggingScrollView, hasPendingApply else { return }
            applyPendingIfNeeded()
        }
    }
    private var hasPendingApply = false
    private var pendingMessages: [ChatMessage] = []
    private var pendingStreamingState: AssistantConversation.StreamingState = .idle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        tableView.delegate = self
        configureDataSource()
    }

    private func configureDataSource() {
        dataSource = UITableViewDiffableDataSource<TimelineSection, TimelineRowID>(
            tableView: tableView
        ) { [weak self] tableView, indexPath, rowID in
            guard let self else { return UITableViewCell() }
            return self.cell(for: rowID, at: indexPath, in: tableView)
        }
        // .fade so new rows opacity-fade in instead of growing from zero height.
        dataSource.defaultRowAnimation = .fade
    }

    private func cell(for rowID: TimelineRowID,
                      at indexPath: IndexPath,
                      in table: UITableView) -> UITableViewCell {
        guard let cell = table.dequeueReusableCell(withIdentifier: TimelineHostingCell.reuseID,
                                                   for: indexPath) as? TimelineHostingCell else {
            return UITableViewCell()
        }
        cell.configure(with: rowID,
                       messagesByID: messagesByID,
                       confirmationHandler: confirmationHandler,
                       externalNavigation: externalNavigation,
                       externalViews: externalViews)
        return cell
    }

    func apply(messages: [ChatMessage],
               streamingState: AssistantConversation.StreamingState) {
        // Defer while dragging; apply the latest values once the finger lifts.
        guard !isDraggingScrollView else {
            pendingMessages = messages
            pendingStreamingState = streamingState
            hasPendingApply = true
            return
        }
        applyNow(messages: messages, streamingState: streamingState)
    }

    private func applyPendingIfNeeded() {
        guard hasPendingApply else { return }
        hasPendingApply = false
        applyNow(messages: pendingMessages, streamingState: pendingStreamingState)
    }

    private func applyNow(messages: [ChatMessage],
                          streamingState: AssistantConversation.StreamingState) {
        // Detect content changes for existing ids so we reconfigure rather than replace
        // (replacement would reset SwiftUI @State).
        let previous = messagesByID
        var changedIDs: [UUID] = []
        for message in messages {
            if let prev = previous[message.id], prev != message {
                changedIDs.append(message.id)
            }
        }

        var nextByID: [UUID: ChatMessage] = [:]
        nextByID.reserveCapacity(messages.count)
        for message in messages {
            nextByID[message.id] = message
        }
        messagesByID = nextByID

        var snapshot = NSDiffableDataSourceSnapshot<TimelineSection, TimelineRowID>()
        snapshot.appendSections([.timeline])

        let messageRows = messages.map { TimelineRowID.message($0.id) }
        snapshot.appendItems(messageRows, toSection: .timeline)

        if MessageListView.shouldShowLoadingIndicator(messages: messages, streamingState: streamingState) {
            snapshot.appendItems([.typingIndicator], toSection: .timeline)
        }

        switch streamingState {
        case .failed(let reason):
            snapshot.appendItems([.errorBanner(reason)], toSection: .timeline)
        case .outcomeUnknown(let reason):
            snapshot.appendItems([.outcomeUnknownBanner(reason)], toSection: .timeline)
        case .idle, .sending, .streaming:
            break
        }

        let changedRowIDs = changedIDs.map { TimelineRowID.message($0) }

        // Insertions animate (.fade); reconfigures snap without animation so cells
        // do not crossfade old content into new during streaming reflow.
        let oldIDs = Set(dataSource.snapshot().itemIdentifiers)
        let newIDs = Set(snapshot.itemIdentifiers)
        let hasStructuralChanges = oldIDs != newIDs

        // Capture before apply so a content-grow that flips isAtOrNearBottom false
        // does not pre-empt the auto-stick.
        let stickToBottom = lastIsNearBottom

        if hasStructuralChanges {
            if !changedRowIDs.isEmpty {
                snapshot.reconfigureItems(changedRowIDs)
            }
            dataSource.apply(snapshot, animatingDifferences: true) { [weak self] in
                self?.afterApply(stickToBottom: stickToBottom)
            }
        } else if !changedRowIDs.isEmpty {
            snapshot.reconfigureItems(changedRowIDs)
            UIView.performWithoutAnimation {
                dataSource.apply(snapshot, animatingDifferences: false) { [weak self] in
                    self?.afterApply(stickToBottom: stickToBottom)
                }
            }
        }
    }

    private func afterApply(stickToBottom: Bool) {
        if stickToBottom {
            scrollToLatest(animated: false)
        }
        // contentSize changes from cell reflow do not fire scrollViewDidScroll,
        // so re-evaluate near-bottom explicitly after every apply.
        let nearBottom = isAtOrNearBottom(tableView)
        if nearBottom != lastIsNearBottom {
            lastIsNearBottom = nearBottom
            onIsNearBottomChange?(nearBottom)
        }
    }

    func scrollToLatest(animated: Bool) {
        guard tableView.numberOfSections > 0 else { return }
        tableView.layoutIfNeeded()
        let target = max(0, tableView.contentSize.height
            + tableView.adjustedContentInset.bottom
            - tableView.bounds.height)
        tableView.setContentOffset(CGPoint(x: 0, y: target), animated: animated)
    }
}

extension TimelineTableViewController: UITableViewDelegate {

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let near = isAtOrNearBottom(scrollView)
        if near != lastIsNearBottom {
            lastIsNearBottom = near
            onIsNearBottomChange?(near)
        }
    }

    /// True when content fits in the viewport, or the merchant is within 80pt of the bottom.
    fileprivate func isAtOrNearBottom(_ scrollView: UIScrollView) -> Bool {
        let viewportHeight = scrollView.bounds.height
            - scrollView.adjustedContentInset.top
            - scrollView.adjustedContentInset.bottom
        if scrollView.contentSize.height <= viewportHeight {
            return true
        }
        let distance = scrollView.contentSize.height
            + scrollView.adjustedContentInset.bottom
            - scrollView.contentOffset.y
            - scrollView.bounds.height
        return distance < 80
    }

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        isDraggingScrollView = true
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        // Apply deferred snapshots the moment the finger lifts. Deceleration is fine to update through.
        isDraggingScrollView = false
    }
}

/// Reusable cell that swaps UIHostingConfiguration content per row.
final class TimelineHostingCell: UITableViewCell {

    static let reuseID = "TimelineHostingCell"

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        selectionStyle = .none
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with rowID: TimelineRowID,
                   messagesByID: [UUID: ChatMessage],
                   confirmationHandler: AssistantConfirmationHandler,
                   externalNavigation: AssistantExternalNavigationProviding,
                   externalViews: AssistantExternalViewProviding) {
        // The .margins(.all, 0) / .minSize(height: 1) / .background(.clear) trio
        // stops the host from being squeezed and prevents phantom min-size before
        // the cell self-sizes. The .frame on the SwiftUI root must live inside the
        // closure because that is the layer the cell measures.
        switch rowID {
        case .message(let id):
            let message = messagesByID[id]
            contentConfiguration = UIHostingConfiguration {
                if let message {
                    MessageBubble(message: message)
                        // Fresh @State per message so cell reuse does not bleed reveal flags.
                        .id(message.id)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, AssistantSpacing.large)
                        .padding(.vertical, AssistantSpacing.small)
                        .environment(\.assistantConfirmationHandler, confirmationHandler)
                        .environment(\.assistantExternalNavigation, externalNavigation)
                        .environment(\.assistantExternalViews, externalViews)
                } else {
                    Color.clear.frame(height: 0)
                }
            }
            .margins(.all, 0)
            .minSize(height: 1)
            .background(Color.clear)
        case .typingIndicator:
            contentConfiguration = UIHostingConfiguration {
                TypingIndicator()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, AssistantSpacing.large)
                    .padding(.vertical, AssistantSpacing.small)
            }
            .margins(.all, 0)
            .minSize(height: 1)
            .background(Color.clear)
        case .errorBanner(let reason):
            contentConfiguration = UIHostingConfiguration {
                ErrorBanner(reason: reason)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, AssistantSpacing.large)
                    .padding(.vertical, AssistantSpacing.small)
            }
            .margins(.all, 0)
            .minSize(height: 1)
            .background(Color.clear)
        case .outcomeUnknownBanner(let reason):
            contentConfiguration = UIHostingConfiguration {
                OutcomeUnknownBanner(reason: reason)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, AssistantSpacing.large)
                    .padding(.vertical, AssistantSpacing.small)
            }
            .margins(.all, 0)
            .minSize(height: 1)
            .background(Color.clear)
        }
    }
}

private struct NoOpExternalNavigation: AssistantExternalNavigationProviding {
    func openOrder(orderID: Int64) {}
    func openProduct(productID: Int64) {}
    func openProductVariation(productID: Int64, variationID: Int64) {}
    func openCustomer(customerID: Int64) {}
    func openAnalyticsHub(payload: AnyCodableJSON) {}
}

private struct EmptyExternalViews: AssistantExternalViewProviding {}
