import Foundation

enum AttachmentKind: String, Codable {
    case image
    case voice
}

struct Attachment: Identifiable, Codable, Hashable {
    var id: String
    var kind: AttachmentKind
    var fileName: String
    var duration: TimeInterval? = nil
    var waveform: [Double]? = nil
}
