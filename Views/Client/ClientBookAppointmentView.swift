import SwiftUI
import FirebaseFirestore

@available(iOS 16.0, *)
struct ClientBookAppointmentView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var session: SessionStore
    @EnvironmentObject var appointmentsViewModel: ClientAppointmentsViewModel
    
    @State private var selectedDate = Date()
    @State private var selectedStartTime = Date()
    @State private var duration: TimeInterval = 3600 // 1 hour default
    @State private var notes = ""
    @State private var isBooking = false
    @State private var errorMessage: String?
    @State private var showError = false
    @State private var conflicts: [Appointment] = []
    @State private var showConflictAlert = false
    
    private let durationOptions: [(String, TimeInterval)] = [
        ("30 minutes", 1800),
        ("45 minutes", 2700),
        ("1 hour", 3600),
        ("1.5 hours", 5400)
    ]
    
    var selectedEndTime: Date {
        selectedStartTime.addingTimeInterval(duration)
    }
    
    private var isFormValid: Bool {
        let hasExpertId = session.currentUser?.expertId != nil && !(session.currentUser?.expertId?.isEmpty ?? true)
        return hasExpertId
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                FitConnectColors.backgroundDark.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Date Selection
                        dateSelectionSection
                        
                        // Time Selection
                        timeSelectionSection
                        
                        // Duration Selection
                        durationSelectionSection
                        
                        // Notes Section
                        notesSection
                        
                        // Book Button
                        bookButton
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
            }
            .navigationTitle("Book Appointment")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(FitConnectColors.textSecondary)
                }
            }
            .onAppear {
            }
            .alert("Scheduling Conflict", isPresented: $showConflictAlert) {
                Button("Choose Different Time") { }
            } message: {
                Text("Selected time is unavailable. Please choose a different time slot.")
            }
            .alert("Error", isPresented: $showError) {
                Button("OK") { }
            } message: {
                Text(errorMessage ?? "An error occurred")
            }
            .onChange(of: session.currentUser?.expertId) {
                _ in
            }
        }
    }
    
    private var dateSelectionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Select Date")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(FitConnectColors.textPrimary)
            
            DatePicker(
                "Date",
                selection: $selectedDate,
                in: Date()...,
                displayedComponents: .date
            )
            .datePickerStyle(GraphicalDatePickerStyle())
            .background(FitConnectColors.cardBackground)
            .cornerRadius(12)
            .onChange(of: selectedDate) { _ in
                // Reset time when date changes
                updateStartTime()
            }
        }
        .padding(20)
        .background(FitConnectColors.cardBackground)
        .cornerRadius(12)
    }
    
    private var timeSelectionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Select Time")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(FitConnectColors.textPrimary)
            
            DatePicker(
                "Start Time",
                selection: $selectedStartTime,
                displayedComponents: .hourAndMinute
            )
            .datePickerStyle(WheelDatePickerStyle())
            .background(FitConnectColors.inputBackground)
            .cornerRadius(8)
        }
        .padding(20)
        .background(FitConnectColors.cardBackground)
        .cornerRadius(12)
    }
    
    private var durationSelectionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Duration")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(FitConnectColors.textPrimary)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(durationOptions, id: \.1) { option in
                    Button {
                        duration = option.1
                    } label: {
                        Text(option.0)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(duration == option.1 ? .white : FitConnectColors.textSecondary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .frame(maxWidth: .infinity)
                            .background(
                                duration == option.1 ? FitConnectColors.accentPurple : FitConnectColors.inputBackground
                            )
                            .cornerRadius(8)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .padding(20)
        .background(FitConnectColors.cardBackground)
        .cornerRadius(12)
    }
    
    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Notes (Optional)")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(FitConnectColors.textPrimary)
            
            TextEditor(text: $notes)
                .font(.system(size: 16))
                .foregroundColor(FitConnectColors.textPrimary)
                .background(Color.clear)
                .frame(minHeight: 100)
                .padding(12)
                .background(FitConnectColors.inputBackground)
                .cornerRadius(8)
                .overlay(
                    Group {
                        if notes.isEmpty {
                            HStack {
                                VStack {
                                    Text("Add any specific topics or questions...")
                                        .font(.system(size: 16))
                                        .foregroundColor(FitConnectColors.textTertiary)
                                        .padding(.horizontal, 16)
                                        .padding(.top, 20)
                                    Spacer()
                                }
                                Spacer()
                            }
                            .allowsHitTesting(false)
                        }
                    }
                )
        }
        .padding(20)
        .background(FitConnectColors.cardBackground)
        .cornerRadius(12)
    }
    
    private var bookButton: some View {
        Button {
            Task {
                await bookAppointment()
            }
        } label: {
            HStack {
                if isBooking {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: "calendar.badge.plus")
                        .font(.system(size: 16, weight: .semibold))
                }
                
                Text(isBooking ? "Booking..." : "Book Appointment")
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(isFormValid ? FitConnectColors.accentPurple : FitConnectColors.textTertiary)
            .cornerRadius(12)
        }
        .disabled(!isFormValid || isBooking)
    }
    
    private func updateStartTime() {
        let calendar = Calendar.current
        let now = Date()
        
        // If selected date is today, ensure time is in the future
        if calendar.isDate(selectedDate, inSameDayAs: now) {
            let nextHour = calendar.date(byAdding: .hour, value: 1, to: now) ?? now
            selectedStartTime = max(selectedStartTime, nextHour)
        }
    }
    
    private func bookAppointment() async {
        print("[ClientBookAppointment] Starting booking process...")
        
        guard let clientId = session.currentUserId,
              let expertId = session.currentUser?.expertId, !expertId.isEmpty else {
            print("[ClientBookAppointment] Missing user info - clientId: \(session.currentUserId ?? "nil"), expertId: \(session.currentUser?.expertId ?? "nil")")
            setError("User not logged in or no expert connected")
            return
        }
        
        print("[ClientBookAppointment] User info valid - clientId: \(clientId), expertId: \(expertId)")
        
        isBooking = true
        
        do {
            let startTime = combineDateTime(selectedDate, selectedStartTime)
            let endTime = startTime.addingTimeInterval(duration)
            
            print("[ClientBookAppointment] Appointment times - start: \(startTime), end: \(endTime)")
            
            // Check for conflicts first
            print("[ClientBookAppointment] Checking for conflicts...")
            let conflictingAppointments = try await AppointmentService.shared.checkForConflicts(
                dietitianId: expertId,  
                startTime: startTime,
                endTime: endTime
            )
            
            if !conflictingAppointments.isEmpty {
                print("[ClientBookAppointment] Found \(conflictingAppointments.count) conflicts")
                conflicts = conflictingAppointments
                showConflictAlert = true
                isBooking = false
                return
            }
            
            print("[ClientBookAppointment] No conflicts found, creating appointment...")
            
            // Create the appointment
            let _ = try await AppointmentService.shared.createAppointment(
                dietitianId: expertId,  
                clientId: clientId,
                clientName: session.currentUser?.fullName ?? "Client",
                startTime: startTime,
                endTime: endTime,
                notes: notes.isEmpty ? nil : notes
            )
            
            print("[ClientBookAppointment] Successfully created appointment with ID: ")
            
            await MainActor.run {
                isBooking = false
                dismiss()
            }
            
        } catch let error as AppointmentError {
            print("[ClientBookAppointment] AppointmentError: \(error.localizedDescription)")
            await MainActor.run {
                setError(error.localizedDescription)
                isBooking = false
            }
        } catch {
            print("[ClientBookAppointment] General error: \(error.localizedDescription)")
            await MainActor.run {
                setError("Failed to book appointment: \(error.localizedDescription)")
                isBooking = false
            }
        }
    }
    
    private func setError(_ message: String) {
        errorMessage = message
        showError = true
    }
    
    private func combineDateTime(_ date: Date, _ time: Date) -> Date {
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: date)
        let timeComponents = calendar.dateComponents([.hour, .minute], from: time)
        
        var combined = DateComponents()
        combined.year = dateComponents.year
        combined.month = dateComponents.month
        combined.day = dateComponents.day
        combined.hour = timeComponents.hour
        combined.minute = timeComponents.minute
        
        return calendar.date(from: combined) ?? date
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

#if DEBUG
@available(iOS 16.0, *)
struct ClientBookAppointmentView_Previews: PreviewProvider {
    static var previews: some View {
        ClientBookAppointmentView()
            .environmentObject(SessionStore.previewStore(isLoggedIn: true, role: "client"))
            .environmentObject(ClientAppointmentsViewModel())
            .preferredColorScheme(.dark)
    }
}
#endif