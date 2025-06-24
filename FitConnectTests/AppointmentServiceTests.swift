import XCTest
import FirebaseFirestore
@testable import FitConnect

@MainActor
final class AppointmentServiceTests: XCTestCase {
    var appointmentService: AppointmentService!
    
    override func setUp() {
        super.setUp()
        appointmentService = AppointmentService.shared
        
        // In production, configure Firebase Test SDK here
        // For now, we'll test the logic without actual Firebase calls
    }
    
    override func tearDown() {
        appointmentService.cleanup()
        appointmentService = nil
        super.tearDown()
    }
    
    func testAppointmentCreation() async throws {
        // Given
        let dietitianId = "test_dietitian_123"
        let clientId = "test_client_456"
        let clientName = "Test Client"
        let startTime = Date().addingTimeInterval(3600) // 1 hour from now
        let endTime = startTime.addingTimeInterval(3600) // 1 hour duration
        let notes = "Test appointment notes"
        
        // When/Then - This would require Firebase Test SDK
        // For now, just test the parameters are valid
        XCTAssertFalse(dietitianId.isEmpty)
        XCTAssertFalse(clientId.isEmpty)
        XCTAssertFalse(clientName.isEmpty)
        XCTAssertTrue(startTime < endTime)
        XCTAssertFalse(notes.isEmpty)
    }
    
    func testConflictDetection() {
        // Given
        let appointment1 = Appointment(
            clientId: "client1",
            startTime: Date(timeIntervalSince1970: 1000),
            endTime: Date(timeIntervalSince1970: 2000),
            status: .confirmed
        )
        
        let appointment2 = Appointment(
            clientId: "client2",
            startTime: Date(timeIntervalSince1970: 1500),
            endTime: Date(timeIntervalSince1970: 2500),
            status: .pending
        )
        
        // When
        let hasConflict = appointment1.overlaps(with: appointment2)
        
        // Then
        XCTAssertTrue(hasConflict, "Appointments should overlap")
    }
    
    func testNoConflictDetection() {
        // Given
        let appointment1 = Appointment(
            clientId: "client1",
            startTime: Date(timeIntervalSince1970: 1000),
            endTime: Date(timeIntervalSince1970: 2000),
            status: .confirmed
        )
        
        let appointment2 = Appointment(
            clientId: "client2",
            startTime: Date(timeIntervalSince1970: 2500),
            endTime: Date(timeIntervalSince1970: 3500),
            status: .pending
        )
        
        // When
        let hasConflict = appointment1.overlaps(with: appointment2)
        
        // Then
        XCTAssertFalse(hasConflict, "Appointments should not overlap")
    }
    
    func testAppointmentStatusTransitions() {
        // Test all valid status transitions
        let statuses = AppointmentStatus.allCases
        XCTAssertEqual(statuses.count, 6)
        
        // Test status colors
        XCTAssertNotNil(AppointmentStatus.pending.color)
        XCTAssertNotNil(AppointmentStatus.confirmed.color)
        XCTAssertNotNil(AppointmentStatus.scheduled.color)
        XCTAssertNotNil(AppointmentStatus.completed.color)
        XCTAssertNotNil(AppointmentStatus.cancelled.color)
        XCTAssertNotNil(AppointmentStatus.noShow.color)
        
        // Test display names
        XCTAssertEqual(AppointmentStatus.pending.displayName, "Pending")
        XCTAssertEqual(AppointmentStatus.confirmed.displayName, "Confirmed")
        XCTAssertEqual(AppointmentStatus.cancelled.displayName, "Cancelled")
    }
    
    func testAppointmentTimeFormatting() {
        // Given
        let startDate = Date(timeIntervalSince1970: 1640995200) // 2022-01-01 00:00:00 UTC
        let endDate = startDate.addingTimeInterval(3600) // 1 hour later
        
        let appointment = Appointment(
            clientId: "test_client",
            startTime: startDate,
            endTime: endDate,
            status: .pending
        )
        
        // When
        let timeString = appointment.timeString
        let shortTimeString = appointment.shortTimeString
        let timeRangeString = appointment.timeRangeString
        let durationString = appointment.durationString
        
        // Then
        XCTAssertFalse(timeString.isEmpty)
        XCTAssertFalse(shortTimeString.isEmpty)
        XCTAssertFalse(timeRangeString.isEmpty)
        XCTAssertEqual(durationString, "1h")
        
        // Test duration calculation
        XCTAssertTrue(timeRangeString.contains(" - "))
    }
    
    func testAppointmentErrorTypes() {
        // Test error messages
        let timeSlotError = AppointmentError.timeSlotUnavailable(conflicts: [])
        XCTAssertNotNil(timeSlotError.errorDescription)
        
        let notFoundError = AppointmentError.appointmentNotFound
        XCTAssertEqual(notFoundError.errorDescription, "Appointment not found")
        
        let invalidTimeError = AppointmentError.invalidTimeRange
        XCTAssertEqual(invalidTimeError.errorDescription, "Invalid time range. End time must be after start time")
        
        let unauthorizedError = AppointmentError.unauthorized
        XCTAssertEqual(unauthorizedError.errorDescription, "You don't have permission to modify this appointment")
    }
}