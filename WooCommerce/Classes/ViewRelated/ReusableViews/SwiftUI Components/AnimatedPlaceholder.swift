import SwiftUI
import WordPressUI // For GhostStyle defaults

struct AnimatedPlaceholder: View {
    @State var animate: Bool = false

    var body: some View {
        Rectangle()
            .fill(animate ? Color(.listForeground(modal: false)) : Color(.ghostCellAnimationEndColor))
            .aspectRatio(Constants.landscapeFourThirds, contentMode: .fit)
            .animation(.easeInOut(duration: GhostStyle.Defaults.beatDuration)
                .repeatForever(autoreverses: true), value: animate)
            .onAppear {
                animate.toggle()
            }
            .padding(Constants.placeholderPadding)
    }

    private enum Constants {
        static var landscapeFourThirds: CGFloat = 4/3
        static var placeholderPadding: CGFloat = 8
    }
}

struct AnimatedPlaceholder_Previews: PreviewProvider {
    static var previews: some View {
        AnimatedPlaceholder(animate: true)
    }
}
