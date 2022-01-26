import Combine
import Foundation
import UIKit

/// Shows either a data label for store stats (e.g. order/visitor/conversion stats), or a redacted view when data are unavailable.
final class StoreStatsDataOrRedactedView: UIView {
    /// State of store stats data UI.
    enum State {
        /// Store stats data are available, and a label is shown.
        case data
        /// Store stats data are unavailable, and a redacted view is shown.
        case redacted
        /// Store stats data are unavailable due to Jetpack-the-plugin, and a redacted view with Jetpack logo is shown.
        case redactedDueToJetpack
    }

    @Published var state: State = .data
    @Published var data: String?
    @Published var isHighlighted: Bool = false

    private let dataLabel = UILabel()
    private let redactedView = StoreStatsEmptyView()
    private let stackView: UIStackView

    private var subscriptions: Set<AnyCancellable> = []

    init() {
        stackView = UIStackView(arrangedSubviews: [dataLabel, redactedView])
        super.init(frame: .zero)

        configureView()
        configureDataLabel()
        observeStateForUIUpdates()
        observeIsHighlightedForLabelTextColor()
        observeDataForLabelText()
    }

    required convenience init?(coder: NSCoder) {
        self.init()
    }
}

private extension StoreStatsDataOrRedactedView {
    func configureView() {
        translatesAutoresizingMaskIntoConstraints = false

        addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        pinSubviewToAllEdges(stackView)
    }

    func configureDataLabel() {
        dataLabel.font = Constants.statsFont
        dataLabel.textColor = Constants.statsTextColor
    }
}

private extension StoreStatsDataOrRedactedView {
    func observeStateForUIUpdates() {
        $state.sink { [weak self] state in
            self?.updateUI(state: state)
        }.store(in: &subscriptions)
    }

    func updateUI(state: State) {
        let isDataLabelShown = state == .data
        dataLabel.isHidden = isDataLabelShown == false
        redactedView.isHidden = !dataLabel.isHidden
        switch state {
        case .redacted, .redactedDueToJetpack:
            redactedView.showJetpackImage = state == .redactedDueToJetpack
        default:
            break
        }
    }

    func observeDataForLabelText() {
        $data.sink { [weak self] data in
            self?.dataLabel.text = data
        }.store(in: &subscriptions)
    }

    func observeIsHighlightedForLabelTextColor() {
        $isHighlighted.sink { [weak self] isHighlighted in
            self?.dataLabel.textColor = isHighlighted ? Constants.statsHighlightTextColor: Constants.statsTextColor
        }.store(in: &subscriptions)
    }
}

private extension StoreStatsDataOrRedactedView {
    enum Constants {
        static let statsTextColor: UIColor = .text
        static let statsHighlightTextColor: UIColor = .accent
        static let statsFont: UIFont = .font(forStyle: .title3, weight: .semibold)
    }
}

#if DEBUG

import SwiftUI

private struct StoreStatsDataOrRedactedViewRepresentable: UIViewRepresentable {
    private let state: StoreStatsDataOrRedactedView.State
    private let isHighlighted: Bool
    private let data: String?

    init(state: StoreStatsDataOrRedactedView.State, isHighlighted: Bool = false, data: String? = nil) {
        self.state = state
        self.isHighlighted = isHighlighted
        self.data = data
    }

    func makeUIView(context: Context) -> StoreStatsDataOrRedactedView {
        let view = StoreStatsDataOrRedactedView()
        view.state = state
        view.isHighlighted = isHighlighted
        view.data = data
        return view
    }

    func updateUIView(_ uiView: StoreStatsDataOrRedactedView, context: Context) {
        uiView.state = state
        uiView.isHighlighted = isHighlighted
        uiView.data = data
    }
}

struct StoreStatsDataOrRedactedView_Previews: PreviewProvider {
    private static func makeStack() -> some View {
        VStack {
            StoreStatsDataOrRedactedViewRepresentable(state: .data, isHighlighted: false, data: "$32.5")
            StoreStatsDataOrRedactedViewRepresentable(state: .redacted)
            StoreStatsDataOrRedactedViewRepresentable(state: .redactedDueToJetpack, isHighlighted: false)
        }
        .background(Color(UIColor.systemBackground))
    }

    static var previews: some View {
        Group {
            makeStack()
                .previewLayout(.fixed(width: 100, height: 150))
                .previewDisplayName("Light")

            makeStack()
                .previewLayout(.fixed(width: 100, height: 150))
                .environment(\.colorScheme, .dark)
                .previewDisplayName("Dark")

            makeStack()
                .previewLayout(.fixed(width: 100, height: 400))
                .environment(\.sizeCategory, .accessibilityExtraExtraExtraLarge)
                .previewDisplayName("Large Font")
        }
    }
}

#endif
