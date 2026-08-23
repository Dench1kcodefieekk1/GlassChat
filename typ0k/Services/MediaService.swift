import UIKit

enum MediaService {
    static var directory: URL {
        let directory = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("GlassChat/Media", isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    static func save(_ data: Data, extension ext: String) -> String {
        let name = "\(UUID().uuidString).\(ext)"
        try? data.write(to: directory.appendingPathComponent(name))
        return name
    }

    static func move(from url: URL, extension ext: String) -> String {
        let name = "\(UUID().uuidString).\(ext)"
        try? FileManager.default.moveItem(at: url, to: directory.appendingPathComponent(name))
        return name
    }

    static func url(for fileName: String) -> URL {
        directory.appendingPathComponent(fileName)
    }

    static func exists(_ fileName: String) -> Bool {
        FileManager.default.fileExists(atPath: url(for: fileName).path)
    }

    static func image(for fileName: String) -> UIImage? {
        UIImage(contentsOfFile: url(for: fileName).path)
    }

    static func delete(_ fileName: String) {
        try? FileManager.default.removeItem(at: url(for: fileName))
    }

    static func deleteAll() {
        let files = (try? FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)) ?? []
        for file in files {
            try? FileManager.default.removeItem(at: file)
        }
    }

    static func totalBytes() -> Int64 {
        let files = (try? FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: [.fileSizeKey])) ?? []
        return files.reduce(Int64(0)) { total, file in
            let size = (try? file.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
            return total + Int64(size)
        }
    }

    static func downscale(_ image: UIImage, maxDimension: CGFloat = 1600) -> UIImage {
        let size = image.size
        let largest = max(size.width, size.height)
        guard largest > maxDimension else { return image }
        let scale = maxDimension / largest
        let newSize = CGSize(width: (size.width * scale).rounded(), height: (size.height * scale).rounded())
        return image.preparingThumbnail(of: newSize) ?? image
    }
}

final class ImageCache {
    static let shared = ImageCache()
    private var cache: [String: UIImage] = [:]

    func image(for fileName: String) -> UIImage? {
        if let cached = cache[fileName] { return cached }
        guard let image = MediaService.image(for: fileName) else { return nil }
        cache[fileName] = image
        return image
    }

    func clear() {
        cache.removeAll()
    }
}
