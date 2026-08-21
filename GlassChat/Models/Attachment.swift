import Foundation

enum AttachmentKind: String, Codable {
    case image
    case voice
    case file
}

struct Attachment: Identifiable, Codable, Hashable {
    var id: String
    var kind: AttachmentKind
    var fileName: String
    var duration: TimeInterval? = nil
    var waveform: [Double]? = nil
    var displayName: String? = nil
    var fileSize: Int64? = nil
}
