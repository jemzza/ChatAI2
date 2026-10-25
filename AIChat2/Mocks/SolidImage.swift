#if DEBUG
import UIKit

enum SolidImage {
    static func jpeg(hue: Double, size: CGSize = CGSize(width: 240, height: 320)) -> Data? {
        let image = UIGraphicsImageRenderer(size: size).image { context in
            UIColor(hue: hue, saturation: 0.35, brightness: 0.55, alpha: 1).setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
        return image.jpegData(compressionQuality: 0.8)
    }
}
#endif
