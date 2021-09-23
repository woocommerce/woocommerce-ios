import Foundation
import SwiftUI

extension UIImage {
    static func composite(images: [UIImage]) -> UIImage? {
        guard let firstImage = images.first else {
            return nil
        }
        let size = firstImage.size
        let rect = CGRect(origin: .zero, size: size)
        UIGraphicsBeginImageContext(size)

        for image in images {
            image.draw(in: rect)
        }

        let result = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return result
    }

    private static func softwareUpdateProgressFill(progress: CGFloat) -> UIImage? {
        assert(progress >= 0 && progress <= 1)
        let progress = progress.clamped(to: 0...1)

        let rect = CGRect(x: 0, y: 0, width: Constants.size, height: Constants.size)
        let clippingRect = CGRect(x: 0, y: (1 - progress) * Constants.size, width: Constants.size, height: Constants.size)
        UIGraphicsBeginImageContext(rect.size)
        defer { UIGraphicsEndImageContext() }

        guard let context = UIGraphicsGetCurrentContext() else {
            return nil
        }
        context.setFillColor(Constants.progressColor.cgColor)
        context.clip(to: clippingRect)
        context.addEllipse(in: rect.insetBy(dx: Constants.borderWidth, dy: Constants.borderWidth))
        context.drawPath(using: .fill)

        return UIGraphicsGetImageFromCurrentImageContext()
    }

    static func softwareUpdateProgress(progress: CGFloat) -> UIImage {
        let symbol: UIImage = progress == 1 ? .cardReaderUpdateProgressCheckmark : .cardReaderUpdateProgressArrow

        return .composite(images: [
            .cardReaderUpdateProgressBackground,
            .softwareUpdateProgressFill(progress: progress),
            symbol
        ].compactMap { $0 }) ?? .init()
    }
}

private enum Constants {
    static let size: CGFloat = 91
    static let borderWidth: CGFloat = 2
    static let progressColor: UIColor = .softwareUpdateProgressFill
}

struct UpdateProgressImage_Previews: PreviewProvider {
    struct UpdateProgressImage: View {
        @State var complete: CGFloat = 0.5

        var body: some View {
            VStack {
                if let image = UIImage.softwareUpdateProgress(progress: complete) {
                    Image(uiImage: image)
                }
                Slider(value: $complete, in: 0...1)
            }
        }
    }
    static var previews: some View {
        UpdateProgressImage()
            .padding()
    }
}
