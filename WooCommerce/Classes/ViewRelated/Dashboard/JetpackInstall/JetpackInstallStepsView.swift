import SwiftUI

struct JetpackInstallStepsView: View {
    // Closure invoked when Done button is tapped
    private let dismissAction: () -> Void

    private let siteURL: String

    init(siteURL: String, dismissAction: @escaping () -> Void) {
        self.siteURL = siteURL
        self.dismissAction = dismissAction
    }
    
    var body: some View {
        Text("Hello, World!")
    }
}

struct JetpackInstallStepsView_Previews: PreviewProvider {
    static var previews: some View {
        JetpackInstallStepsView(siteURL: "automattic.com", dismissAction: {})
            .preferredColorScheme(.light)
            .previewLayout(.fixed(width: 414, height: 780))
    }
}
