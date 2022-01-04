import Foundation
import SwiftUI
import Combine

/// Hosting controller that wraps an `SimplePaymentsAmount` view.
///
final class SimplePaymentsAmountHostingController: UIHostingController<SimplePaymentsAmount> {

    /// References to keep the Combine subscriptions alive within the lifecycle of the object.
    ///
    private var subscriptions: Set<AnyCancellable> = []

    /// Presents notices in the current modal presentation context
    ///
    private lazy var modalNoticePresenter: NoticePresenter = {
        let presenter = DefaultNoticePresenter()
        presenter.presentingViewController = self.navigationController ?? self
        return presenter
    }()

    /// Presents notices at the system level, currently uses the main tab-bar as source view controller.
    ///
    private let systemNoticePresenter: NoticePresenter

    init(viewModel: SimplePaymentsAmountViewModel,
         presentNoticePublisher: AnyPublisher<SimplePaymentsNotice, Never>,
         systemNoticePresenter: NoticePresenter = ServiceLocator.noticePresenter) {
        self.systemNoticePresenter = systemNoticePresenter
        super.init(rootView: SimplePaymentsAmount(viewModel: viewModel))

        // Needed because a `SwiftUI` cannot be dismissed when being presented by a UIHostingController
        rootView.dismiss = { [weak self] in
            self?.dismiss(animated: true, completion: nil)
        }

        // Observe the present notice intent.
        presentNoticePublisher
            .compactMap { $0 }
            .sink { [weak self] notice in

                switch notice {
                case .created:
                    self?.systemNoticePresenter.enqueue(notice: .init(title: SimplePaymentsAmount.Localization.created, feedbackType: .success))
                case .completed:
                    self?.systemNoticePresenter.enqueue(notice: .init(title: SimplePaymentsAmount.Localization.completed, feedbackType: .success))
                case .error(let description):
                    self?.modalNoticePresenter.enqueue(notice: .init(title: description, feedbackType: .error))
                }
            }
            .store(in: &subscriptions)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Needed to present IPP collect amount alerts, which are displayed in UIKit view controllers.
        rootView.rootViewController = navigationController

        // Set presentation delegate to track the user dismiss flow event
        if let navigationController = navigationController {
            navigationController.presentationController?.delegate = self
        } else {
            presentationController?.delegate = self
        }
    }

    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

/// Intercepts to the dismiss drag gesture.
///
extension SimplePaymentsAmountHostingController: UIAdaptivePresentationControllerDelegate {
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        rootView.viewModel.userDidCancelFlow()
    }

    func presentationControllerShouldDismiss(_ presentationController: UIPresentationController) -> Bool {
        !rootView.viewModel.disableViewActions
    }
}

/// View that receives an arbitrary amount for creating a simple payments order.
///
struct SimplePaymentsAmount: View {

    /// Set this closure with UIKit dismiss code. Needed because we need access to the UIHostingController `dismiss` method.
    ///
    var dismiss: (() -> Void) = {}

    /// Needed because IPP capture payments depend on a UIViewController for providing user feedback.
    ///
    weak var rootViewController: UIViewController?

    /// Keeps track of the current content scale due to accessibility changes
    ///
    @ScaledMetric private var scale: CGFloat = 1.0

    /// ViewModel to drive the view content
    ///
    @ObservedObject private(set) var viewModel: SimplePaymentsAmountViewModel

    var body: some View {
        VStack(alignment: .center, spacing: Layout.mainVerticalSpacing) {

            Spacer()

            // Instructions Label
            Text(Localization.instructions)
                .secondaryBodyStyle()

            ZStack(alignment: .center) {
                // Hidden input text field
                BindableTextfield("", text: $viewModel.amount)
                    .keyboardType(.decimalPad)
                    .focused()
                    .opacity(0)

                // Visible & formatted label
                Text(viewModel.formattedAmmount)
                    .font(.system(size: Layout.amountFontSize(scale: scale), weight: .bold))
                    .foregroundColor(Color(viewModel.amountTextColor))
            }
            .fixedSize()

            Spacer()

            // Done button
            Button(Localization.buttonTitle) {
                viewModel.createSimplePaymentsOrder()
            }
            .buttonStyle(PrimaryLoadingButtonStyle(isLoading: viewModel.loading))
            .disabled(viewModel.shouldDisableDoneButton)

            LazyNavigationLink(destination: summaryView(), isActive: $viewModel.navigateToSummary) {
                EmptyView()
            }
        }
        .padding()
        .navigationTitle(Localization.title)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                // Cancel button set to disabled state until get the result from `createSimplePaymentsOrder` operation
                Button(Localization.cancelTitle, action: {
                    dismiss()
                    viewModel.userDidCancelFlow()
                })
            }
        }
        .disabled(viewModel.disableViewActions)
        .wooNavigationBarStyle()
    }

    /// Returns a `SimplePaymentsSummary` instance when the view model is available.
    ///
    private func summaryView() -> some View {
        Group {
            if let summaryViewModel = viewModel.summaryViewModel {
                SimplePaymentsSummary(dismiss: dismiss, rootViewController: rootViewController, viewModel: summaryViewModel)
            }
            EmptyView()
        }
    }
}

// MARK: Constants
private extension SimplePaymentsAmount {
    enum Localization {
        static let title = NSLocalizedString("Take Payment", comment: "Title for the simple payments screen")
        static let instructions = NSLocalizedString("Enter Amount", comment: "Short instructions label in the simple payments screen")
        static let cancelTitle = NSLocalizedString("Cancel", comment: "Title for the button to cancel the simple payments screen")
        static let created = NSLocalizedString("🎉 Order created", comment: "Notice text after creating a simple payment order")
        static let completed = NSLocalizedString("🎉 Order completed", comment: "Notice text after completing a simple payment order")
        static let buttonTitle = NSLocalizedString("Next", comment: "Title for the button to confirm the amount in the simple payments screen")
    }

    enum Layout {
        static let mainVerticalSpacing: CGFloat = 8
        static func amountFontSize(scale: CGFloat) -> CGFloat {
            56 * scale
        }
    }
}

/// Representation of possible notices that can be displayed
///
enum SimplePaymentsNotice: Equatable {
    case created
    case completed
    case error(String)
}
