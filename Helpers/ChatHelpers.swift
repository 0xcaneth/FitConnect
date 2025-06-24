import Foundation

enum ChatHelpers {
    static func generateChatId(userId1: String, userId2: String) -> String {
        let sortedIds = [userId1, userId2].sorted()
        return "chat_\(sortedIds[0])_\(sortedIds[1])"
    }
}
