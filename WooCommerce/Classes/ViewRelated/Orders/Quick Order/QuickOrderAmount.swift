import Foundation
import SwiftUI
import Combine

/// Hosting controller that wraps an `QuickOrderAmount` view.
///
final class QuickOrderAmountHostingController: UIHostingController<QuickOrderAmount> {

    /// References to keep the Combine subscriptions alive within the lifecycle of the object.
    ///
    private var subscriptions: Set<AnyCancellable> = []

    /// Presents notices in the current modal presentation context
    ///
    private lazy var modalNoticePresenter: NoticePresenter = {
        let presenter = DefaultNoticePresenter()
        presenter.presentingViewController = self
        return presenter
    }()

    init(viewModel: QuickOrderAmountViewModel) {
        super.init(rootView: QuickOrderAmount(viewModel: viewModel))

        // Needed because a `SwiftUI` cannot be dismissed when being presented by a UIHostingController
        rootView.dismiss = { [weak self] in
            self?.dismiss(animated: true, completion: nil)
        }

        // Observe the present notice intent and set it back to `nil` after presented.
        viewModel.$presentNotice
            .compactMap { $0 }
            .sink { [weak self] notice in

                // To prevent keyboard to hide the notice
                self?.view.endEditing(true)

                switch notice {
                case .error:
                    self?.modalNoticePresenter.enqueue(notice: .init(title: QuickOrderAmount.Localization.error, feedbackType: .error))
                }

                // Nullify the presentation intent.
                viewModel.presentNotice = nil
            }
            .store(in: &subscriptions)

        // Set presentation delegate to track the user dismiss flow event
        presentationController?.delegate = self
    }

    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

/// Intercepts to the dismiss drag gesture.
///
extension QuickOrderAmountHostingController: UIAdaptivePresentationControllerDelegate {
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        rootView.viewModel.userDidCancelFlow()
    }
}

/// View that receives an arbitrary amount for creating a quick order order.
///
struct QuickOrderAmount: View {

    /// Set this closure with UIKit dismiss code. Needed because we need access to the UIHostingController `dismiss` method.
    ///
    var dismiss: (() -> Void) = {}

    /// Keeps track of the current content scale due to accessibility changes
    ///
    @ScaledMetric private var scale: CGFloat = 1.0

    /// ViewModel to drive the view content
    ///
    @ObservedObject private(set) var viewModel: QuickOrderAmountViewModel

    var body: some View {
        VStack(alignment: .center, spacing: Layout.mainVerticalSpacing) {

            Spacer()

            // Instructions Label
            Text(Localization.instructions)
                .secondaryBodyStyle()

            // Amount Textfield
            TextField(viewModel.amountPlaceholder, text: $viewModel.amount)
                .font(.system(size: Layout.amountFontSize(scale: scale), weight: .bold, design: .default))
                .foregroundColor(Color(.text))
                .multilineTextAlignment(.center)
                .keyboardType(.decimalPad)

            Spacer()

            // Done button
            Button(Localization.buttonTitle) {
                viewModel.createQuickOrderOrder()
            }
            .buttonStyle(PrimaryLoadingButtonStyle(isLoading: viewModel.loading))
            .disabled(viewModel.shouldDisableDoneButton)
        }
        .padding()
        .navigationTitle(Localization.title)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(Localization.cancelTitle, action: {
                    dismiss()
                    viewModel.userDidCancelFlow()
                })
            }
        }
    }
}

// MARK: Constants
private extension QuickOrderAmount {
    enum Localization {
        static let title = NSLocalizedString("Take Payment", comment: "Title for the quick order screen")
        static let instructions = NSLocalizedString("Enter Amount", comment: "Short instructions label in the quick order screen")
        static let buttonTitle = NSLocalizedString("Done", comment: "Title for the button to confirm the amount in the quick order screen")
        static let cancelTitle = NSLocalizedString("Cancel", comment: "Title for the button to cancel the quick order screen")
        static let error = NSLocalizedString("There was an error creating the order", comment: "Notice text after failing to create a quick order order.")
    }

    enum Layout {
        static let mainVerticalSpacing: CGFloat = 8
        static func amountFontSize(scale: CGFloat) -> CGFloat {
            56 * scale
        }
    }
}
