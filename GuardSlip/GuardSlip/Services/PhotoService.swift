import UIKit
import Combine

// MARK: - Protocol

protocol PhotoServiceProtocol {
    func compressImage(_ image: UIImage, quality: PhotoQuality) -> Data?
    func createThumbnail(_ image: UIImage, size: CGSize) -> Data?
}

// MARK: - Implementation

final class PhotoService: PhotoServiceProtocol {
    
    private static let defaultThumbnailSize = CGSize(width: 200, height: 200)
    
    func compressImage(_ image: UIImage, quality: PhotoQuality) -> Data? {
        image.jpegData(compressionQuality: quality.compressionQuality)
    }
    
    func createThumbnail(_ image: UIImage, size: CGSize = defaultThumbnailSize) -> Data? {
        let aspectWidth = size.width / image.size.width
        let aspectHeight = size.height / image.size.height
        let scaleFactor = min(aspectWidth, aspectHeight)
        
        let scaledSize = CGSize(
            width: image.size.width * scaleFactor,
            height: image.size.height * scaleFactor
        )
        
        let renderer = UIGraphicsImageRenderer(size: scaledSize)
        let thumbnail = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: scaledSize))
        }
        
        return thumbnail.jpegData(compressionQuality: 0.8)
    }
}
