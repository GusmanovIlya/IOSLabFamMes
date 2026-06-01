import Foundation

public enum RoomKind: String, Codable, Sendable {
    case directChat
    case groupChat
    case sharedNote
}
