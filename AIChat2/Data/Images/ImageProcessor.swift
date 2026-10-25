import Foundation
import ImageIO
import UniformTypeIdentifiers

nonisolated enum ImageProcessor {
    static func jpeg(from data: Data, croppedTo aspect: Double, maxPixelSize: Int, quality: Double = 0.8) -> Data? {
        guard aspect > 0, let image = downscaled(data, maxPixelSize: maxPixelSize) else { return nil }
        let width = Double(image.width)
        let height = Double(image.height)
        var crop = CGRect(x: 0, y: 0, width: width, height: height)
        if width / height > aspect {
            crop.size.width = (height * aspect).rounded()
            crop.origin.x = ((width - crop.width) / 2).rounded(.down)
        } else {
            crop.size.height = (width / aspect).rounded()
            crop.origin.y = ((height - crop.height) / 2).rounded(.down)
        }
        return image.cropping(to: crop).flatMap { encode($0, quality: quality) }
    }
    
    private static func downscaled(_ data: Data, maxPixelSize: Int) -> CGImage? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixelSize,
            kCGImageSourceShouldCacheImmediately: true
        ]
        return CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary)
    }
    
    private static func encode(_ image: CGImage, quality: Double) -> Data? {
        let output = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(output, UTType.jpeg.identifier as CFString, 1, nil) else {
            return nil
        }
        CGImageDestinationAddImage(destination, image, [kCGImageDestinationLossyCompressionQuality: quality] as CFDictionary)
        return CGImageDestinationFinalize(destination) ? output as Data : nil
    }
}
