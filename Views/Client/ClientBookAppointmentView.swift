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
    @State private var animationPhase: CGFloat = 0
    
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
        return hasExpertId && selectedDate >= Date().startOfDay
    }
    
    var body: some View {
        ZStack {
            RadialGradient(
                colors: [
                    FitConnectColors.backgroundDark,
                    Color.black.opacity(0.98),
                    Color.black
                ],
                center: .topTrailing,
                startRadius: 100,
                endRadius: 800
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                modernBookingHeader
                
                ScrollView {
                    LazyVStack(spacing: 32) {
                        premiumDateSelectionCard
                            .scaleEffect(animationPhase)
                            .opacity(animationPhase)
                            .animation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.1), value: animationPhase)
                        
                        premiumTimeSelectionCard
                            .scaleEffect(animationPhase)
                            .opacity(animationPhase)
                            .animation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.2), value: animationPhase)
                        
                        premiumDurationCard
                            .scaleEffect(animationPhase)
                            .opacity(animationPhase)
                            .animation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.3), value: animationPhase)
                        
                        premiumNotesCard
                            .scaleEffect(animationPhase)
                            .opacity(animationPhase)
                            .animation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.4), value: animationPhase)
                        
                        premiumBookingButton
                            .scaleEffect(animationPhase)
                            .opacity(animationPhase)
                            .animation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.5), value: animationPhase)
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 20)
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) {
                animationPhase = 1.0
            }
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
        .onChange(of: session.currentUser?.expertId) { _ in
        }
    }
    
    private var modernBookingHeader: some View {
        VStack(spacing: 0) {
            RoundedRectangle(cornerRadius: 3)
                .fill(.white.opacity(0.4))
                .frame(width: 40, height: 6)
                .padding(.top, 16)
                .padding(.bottom, 20)
            
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(.white.opacity(0.8))
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(.ultraThinMaterial)
                        .overlay(
                            Capsule()
                                .stroke(.white.opacity(0.2), lineWidth: 1)
                        )
                )
                
                Spacer()
                
                VStack(spacing: 6) {
                    Text("Book Appointment")
                        .font(.system(size: 28, weight: .black, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    .white,
                                    FitConnectColors.accentPurple.opacity(0.9),
                                    FitConnectColors.accentBlue.opacity(0.8)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                    
                    Text("With Your Dietitian")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
                
                Color.clear
                    .frame(width: 80, height: 40)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .background(
            LinearGradient(
                colors: [
                    FitConnectColors.accentPurple.opacity(0.15),
                    .clear
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
    
    private var premiumDateSelectionCard: some View {
        VStack(alignment: .leading, spacing: 24) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(FitConnectColors.accentPurple.opacity(0.2))
                        .frame(width: 44, height: 44)
                        .overlay(
                            Circle()
                                .stroke(FitConnectColors.accentPurple.opacity(0.4), lineWidth: 1)
                        )
                    
                    Image(systemName: "calendar")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(FitConnectColors.accentPurple)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Select Date")
                        .font(.system(size: 22, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text("Choose your preferred appointment date")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                }
                
                Spacer()
            }
            
            DatePicker(
                "Date",
                selection: $selectedDate,
                in: Date()...,
                displayedComponents: .date
            )
            .datePickerStyle(GraphicalDatePickerStyle())
            .background(.clear)
            .colorScheme(.dark)
            .onChange(of: selectedDate) { _ in
                updateStartTime()
            }
        }
        .padding(28)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(
                            LinearGradient(
                                colors: [.white.opacity(0.3), .clear],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
        .shadow(color: .black.opacity(0.2), radius: 15, x: 0, y: 8)
    }
    
    private var premiumTimeSelectionCard: some View {
        VStack(alignment: .leading, spacing: 24) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(FitConnectColors.accentBlue.opacity(0.2))
                        .frame(width: 44, height: 44)
                        .overlay(
                            Circle()
                                .stroke(FitConnectColors.accentBlue.opacity(0.4), lineWidth: 1)
                        )
                    
                    Image(systemName: "clock.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(FitConnectColors.accentBlue)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Select Time")
                        .font(.system(size: 22, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text("Pick your preferred time slot")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                }
                
                Spacer()
                
                Text(formatTime(selectedStartTime))
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(FitConnectColors.accentBlue.opacity(0.3))
                            .overlay(
                                Capsule()
                                    .stroke(FitConnectColors.accentBlue.opacity(0.5), lineWidth: 1)
                            )
                    )
            }
            
            DatePicker(
                "Start Time",
                selection: $selectedStartTime,
                displayedComponents: .hourAndMinute
            )
            .datePickerStyle(WheelDatePickerStyle())
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(.white.opacity(0.1), lineWidth: 1)
                    )
            )
            .colorScheme(.dark)
        }
        .padding(28)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(
                            LinearGradient(
                                colors: [.white.opacity(0.3), .clear],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
        .shadow(color: .black.opacity(0.2), radius: 15, x: 0, y: 8)
    }
    
    private var premiumDurationCard: some View {
        VStack(alignment: .leading, spacing: 24) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(.green.opacity(0.2))
                        .frame(width: 44, height: 44)
                        .overlay(
                            Circle()
                                .stroke(.green.opacity(0.4), lineWidth: 1)
                        )
                    
                    Image(systemName: "timer")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.green)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Duration")
                        .font(.system(size: 22, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text("How long should your appointment be?")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                }
                
                Spacer()
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                ForEach(durationOptions, id: \.1) { option in
                    Button {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                            duration = option.1
                        }
                    } label: {
                        VStack(spacing: 8) {
                            Text(option.0.components(separatedBy: " ").first ?? "")
                                .font(.system(size: 20, weight: .black, design: .rounded))
                                .foregroundColor(duration == option.1 ? .white : .white.opacity(0.6))
                            
                            Text(option.0.components(separatedBy: " ").dropFirst().joined(separator: " "))
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(duration == option.1 ? .white.opacity(0.8) : .white.opacity(0.4))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(
                                    duration == option.1 ?
                                    LinearGradient(
                                        colors: [.green, .green.opacity(0.8)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ) :
                                    LinearGradient(
                                        colors: [.white.opacity(0.08), .white.opacity(0.04)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(
                                            duration == option.1 ? 
                                                .green.opacity(0.5) : 
                                                .white.opacity(0.1),
                                            lineWidth: 1
                                        )
                                )
                        )
                        .shadow(
                            color: duration == option.1 ? .green.opacity(0.3) : .clear,
                            radius: duration == option.1 ? 8 : 0,
                            x: 0,
                            y: duration == option.1 ? 4 : 0
                        )
                        .scaleEffect(duration == option.1 ? 1.02 : 1.0)
                    }
                    .buttonStyle(PremiumPressStyle())
                }
            }
        }
        .padding(28)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(
                            LinearGradient(
                                colors: [.white.opacity(0.3), .clear],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
        .shadow(color: .black.opacity(0.2), radius: 15, x: 0, y: 8)
    }
    
    private var premiumNotesCard: some View {
        VStack(alignment: .leading, spacing: 24) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(.orange.opacity(0.2))
                        .frame(width: 44, height: 44)
                        .overlay(
                            Circle()
                                .stroke(.orange.opacity(0.4), lineWidth: 1)
                        )
                    
                    Image(systemName: "note.text")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.orange)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Notes")
                        .font(.system(size: 22, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text("Any specific topics or questions? (Optional)")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                }
                
                Spacer()
            }
            
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 16)
                    .fill(.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(.white.opacity(0.15), lineWidth: 1)
                    )
                    .frame(minHeight: 100)
                
                TextEditor(text: $notes)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                    .background(.clear)
                    .padding(16)
                    .scrollContentBackground(.hidden)
                
                if notes.isEmpty {
                    VStack(alignment: .leading) {
                        Text("Add any specific topics, dietary restrictions,")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.4))
                        Text("goals, or questions you'd like to discuss...")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.4))
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 24)
                    .allowsHitTesting(false)
                }
            }
        }
        .padding(28)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(
                            LinearGradient(
                                colors: [.white.opacity(0.3), .clear],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
        .shadow(color: .black.opacity(0.2), radius: 15, x: 0, y: 8)
    }
    
    private var premiumBookingButton: some View {
        Button {
            Task {
                await bookAppointment()
            }
        } label: {
            HStack(spacing: 16) {
                if isBooking {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.9)
                } else {
                    Image(systemName: "calendar.badge.plus")
                        .font(.system(size: 20, weight: .bold))
                }
                
                VStack(spacing: 4) {
                    Text(isBooking ? "Booking Appointment..." : "Book Appointment")
                        .font(.system(size: 20, weight: .black, design: .rounded))
                    
                    if !isBooking {
                        Text("\(formatDate(selectedDate)) at \(formatTime(selectedStartTime))")
                            .font(.system(size: 14, weight: .semibold))
                            .opacity(0.8)
                    }
                }
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        isFormValid ?
                        LinearGradient(
                            colors: [FitConnectColors.accentPurple, FitConnectColors.accentBlue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ) :
                        LinearGradient(
                            colors: [.gray.opacity(0.4), .gray.opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .shadow(
                color: isFormValid ? FitConnectColors.accentPurple.opacity(0.4) : .clear,
                radius: isFormValid ? 20 : 0,
                x: 0,
                y: isFormValid ? 10 : 0
            )
            .scaleEffect(isFormValid ? 1.0 : 0.95)
            .opacity(isFormValid ? 1.0 : 0.6)
        }
        .buttonStyle(PremiumPressStyle())
        .disabled(!isFormValid || isBooking)
        .padding(.horizontal, 4)
    }
    
    private func updateStartTime() {
        let calendar = Calendar.current
        let now = Date()
        
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
            
            let _ = try await AppointmentService.shared.createAppointment(
                dietitianId: expertId,  
                clientId: clientId,
                clientName: session.currentUser?.fullName ?? "Client",
                startTime: startTime,
                endTime: endTime,
                notes: notes.isEmpty ? nil : notes
            )
            
            print("[ClientBookAppointment] Successfully created appointment")
            
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
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        if Calendar.current.isDateInToday(date) {
            return "Today"
        } else if Calendar.current.isDateInTomorrow(date) {
            return "Tomorrow"
        } else {
            formatter.dateFormat = "MMM d"
            return formatter.string(from: date)
        }
    }
}

struct PremiumPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .brightness(configuration.isPressed ? -0.05 : 0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

extension Date {
    var startOfDay: Date {
        return Calendar.current.startOfDay(for: self)
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