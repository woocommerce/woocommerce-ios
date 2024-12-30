import Foundation
import SwiftUI
import Experiments
import protocol WooFoundation.Analytics


/// Displays the WooCommerce Prologue UI.
///
final class LoginPrologueViewController: UIHostingController<LoginPrologueView> {
    init() {
        super.init(rootView: LoginPrologueView())
        view.backgroundColor = .clear
    }

    @objc required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewWillAppear(_ animated: Bool) {
            super.viewWillAppear(animated)
            navigationController?.setNavigationBarHidden(true, animated: animated)
        }
}

struct LoginPrologueView: View {
    var body: some View {
        return VStack { }
    }
}

#if DEBUG
struct LoginPrologueView_Previews: PreviewProvider {
    static var previews: some View {
        LoginPrologueView()
    }
}
#endif
