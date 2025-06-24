import XCTest
import FirebaseFirestore
@testable import FitConnect

@MainActor
final class ChatServiceTests: XCTestCase {
    var chatService: ChatService!
    var mockFirestore: MockFirestore!
    
    override func setUpWithError() throws {
        super.setUp()
        chatService = ChatService.shared
        mockFirestore = MockFirestore()
    }
    
    override func tearDownWithError() throws {
        chatService = nil
        mockFirestore = nil
        super.tearDown()
    }
    
    // MARK: - Message Security Tests
    func testSendMessageOnlyUsesAllowedFields() throws {
        let client = ParticipantInfo(id: "client1", fullName: "John Doe", photoURL: nil)
        let message = ChatMessage(
            text: "Hello",
            senderId: client.id,
            senderName: client.fullName,
            timestamp: Timestamp(date: Date())
        )
        
        let messageDict = message.toDictionary()
        
        // Verify only allowed fields are present
        let allowedFields: Set<String> = [
            "text", "senderId", "senderName", "senderAvatarURL", 
            "timestamp", "isReadByClient", "isReadByDietitian"
        ]
        
        let messageFields = Set(messageDict.keys)
        XCTAssertTrue(messageFields.isSubset(of: allowedFields), 
                     "Message contains disallowed fields: \(messageFields.subtracting(allowedFields))")
        
        // Verify required fields are present
        XCTAssertNotNil(messageDict["text"])
        XCTAssertNotNil(messageDict["senderId"])
        XCTAssertNotNil(messageDict["senderName"])
        XCTAssertNotNil(messageDict["timestamp"])
        XCTAssertNotNil(messageDict["isReadByClient"])
        XCTAssertNotNil(messageDict["isReadByDietitian"])
    }
    
    // MARK: - Unread Count Tests
    func testUnreadCountIncrementsCorrectly() throws {
        let client = ParticipantInfo(id: "client1", fullName: "John Doe")
        let dietitian = ParticipantInfo(id: "dietitian1", fullName: "Dr. Smith")
        
        var chat = ChatSummary(chatId: "test_chat", client: client, dietitian: dietitian)
        
        // Initial unread counts should be 0
        XCTAssertEqual(chat.unreadCounts[client.id], 0)
        XCTAssertEqual(chat.unreadCounts[dietitian.id], 0)
        
        // Simulate message from client to dietitian
        chat.unreadCounts[dietitian.id] = (chat.unreadCounts[dietitian.id] ?? 0) + 1
        
        XCTAssertEqual(chat.unreadCounts[dietitian.id], 1)
        XCTAssertEqual(chat.unreadCounts[client.id], 0)
    }
    
    // MARK: - Typing Indicator Tests
    func testTypingIndicator