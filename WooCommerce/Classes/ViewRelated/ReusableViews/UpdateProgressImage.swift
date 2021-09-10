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
        let rect = CGRect(x: 0, y: 0, width: 91, height: 91)
        let clippingRect = CGRect(x: 0, y: (1 - progress) * 91, width: 91, height: 91)
        UIGraphicsBeginImageContext(rect.size)
        defer { UIGraphicsEndImageContext() }

        guard let context = UIGraphicsGetCurrentContext() else {
            return nil
        }
        context.setFillColor(red: 0.498, green: 0.329, blue: 0.702, alpha: 1)
        context.clip(to: clippingRect)
        context.addEllipse(in: rect.insetBy(dx: 2, dy: 2))
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
