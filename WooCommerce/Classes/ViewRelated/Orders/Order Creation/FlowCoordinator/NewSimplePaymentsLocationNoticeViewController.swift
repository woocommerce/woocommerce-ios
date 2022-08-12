import UIKit
import SwiftUI
import WordPressUI

final class NewSimplePaymentsLocationNoticeViewController: UIViewController {
    private let viewModel: NewSimplePaymentsLocationNoticeViewModel

    init() {
        viewModel = NewSimplePaymentsLocationNoticeViewModel()
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupNewSimplePaymentsNoticeView()
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
    }

    func setupNewSimplePaymentsNoticeView() {
        let hostingController = UIHostingController(rootView: viewModel.simplePaymentsNoticeView)
        addChild(hostingController)
        view.addSubview(hostingController.view)
        hostingController.didMove(toParent: self)
        setupConstraints(for: hostingController)
    }

    private func setupConstraints(for hostingController: UIHostingController<DismissableNoticeView>) {
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        hostingController.view.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
        hostingController.view.heightAnchor.constraint(equalToConstant: view.intrinsicContentSize.height + Layout.verticalSpace).isActive = true
        hostingController.view.topAnchor.constraint(equalTo: view.topAnchor, constant: 0).isActive = true
    }
}

/// `BottomSheetViewController` conformance
///
extension NewSimplePaymentsLocationNoticeViewController: DrawerPresentable {
    var collapsedHeight: DrawerHeight {
        return .contentHeight(160)
    }
}

extension NewSimplePaymentsLocationNoticeViewController {
    enum Layout {
        static let verticalSpace: CGFloat = 160
    }
}
