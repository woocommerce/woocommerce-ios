import SwiftUI
import UIKit

@MainActor
final class StoreOrderListHeaderView: UIView {
    private var hostedView: (UIView & UIContentView)?
    private(set) var state: StoreOrderListHeaderState?

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    func configure(state: StoreOrderListHeaderState,
                   onFilter: @escaping () -> Void,
                   onTroubleshoot: @escaping () -> Void,
                   onContactSupport: @escaping () -> Void,
                   onRetryCurrency: @escaping () -> Void) {
        self.state = state
        let configuration = UIHostingConfiguration {
            StoreOrderListHeader(state: state,
                                 onFilter: onFilter,
                                 onTroubleshoot: onTroubleshoot,
                                 onContactSupport: onContactSupport,
                                 onRetryCurrency: onRetryCurrency)
        }
        .margins(.all, 0)

        if let hostedView {
            hostedView.configuration = configuration
            superview?.setNeedsLayout()
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
}
