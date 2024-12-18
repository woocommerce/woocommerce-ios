import Foundation
import class WordPressShared.EmailFormatValidator
import Yosemite
import WooFoundation
import Combine

enum ReceiptEmailResult {
    case success(Order)
    case failure(Error)
    case canceled
}

final class ReceiptEmailViewModel: ObservableObject {
    @Published var email: String = ""
    @Published private(set) var state: PrimaryLoadingButtonStyle.State = .idle

    private var order: Order
    private let stores: StoresManager
    private let emailValidator: (String) -> Bool
    private let onResult: (ReceiptEmailResult) -> Void

    init(order: Order,
         stores: StoresManager = ServiceLocator.stores,
         emailValidator: @escaping (String) -> Bool = EmailFormatValidator.validate,
         onResult: @escaping (ReceiptEmailResult) -> Void) {
        self.order = order
        self.stores = stores
        self.emailValidator = emailValidator
        self.onResult = onResult
    }

    var isEmailValid: Bool {
        emailValidator(email)
    }

    func sendReceipt() {
        let email = email
        let action = ReceiptAction.sendReceipt(order: order, email: email) { [weak self] result in
            DispatchQueue.main.async {
                guard let self else { return }
                self.state = .idle
                switch result {
                case let .success(order):
                    self.order = order
                    self.state = .success
                case let .failure(error):
                    DDLogError("Sending email receipt failed: \(error.localizedDescription)")
                    self.onResult(.failure(error))
                }
            }
        }

        state = .loading
        stores.dispatch(action)
    }

    func onDisappear() {
        switch state {
        case .success:
            onResult(.success(order))
        default:
            onResult(.canceled)
        }
    }
}
