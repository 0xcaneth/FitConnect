import SwiftUI
import FirebaseFirestore

@available(iOS 16.0, *)
struct ClientAppointmentDetailModal: View {
    @Environment(\.dismiss) private var dismiss
    let appointment: Appointment
    let onCancel: () -> Void
    
    @State private var isCancelling = false
    @State private var showCancelConfirmation = false
    @State private var animationPhase: CGFloat = 0
    
    var body: some View {
        ZStack {
            // Ultra-premium background overlay
            Color.black.opacity(0.9)
                .ignoresSafeArea()
                .onTapGesture {
                    dismiss()
                }
            
            // Main modal content
            VStack(spacing: 0) {
                // Ultra-modern header
                premiumDetailHeader
                
                // Content sections
                ScrollView {
                    VStack(spacing: 28) {
                        // Hero appointment section
                        heroAppointmentInfo
                            .scaleEffect(animationPhase)
                            .opacity(animationPhase)
                            .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1), value: animationPhase)
                        
                        // Detailed info cards
                        appointmentDetailsGrid
                            .scaleEffect(animationPhase)
                            .opacity(animationPhase)
                            .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2), value: animationPhase)
                        
                        // Notes section
                        if let notes = appointment.notes, !notes.isEmpty {
                            premiumNotesDisplay(notes: notes)
                                .scaleEffect(animationPhase)
                                .opacity(animationPhase)
                                .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.3), value: animationPhase)
                        }
                        
                        // Action buttons
                        if canCancelAppointment {
                            premiumActionButtons
                                .scaleEffect(animationPhase)
                                .opacity(animationPhase)
                                .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.4), value: animationPhase)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 20)
                }
            }
            .frame(maxHeight: UIScreen.main.bounds.height * 0.9)
            .background(
                RoundedRectangle(cornerRadius: 32)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 32)
                            .stroke(
                                LinearGradient(
                                    colors: [.white.opacity(0.4), .clear],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
            )
            .padding(16)
            .shadow(color: .black.opacity(0.3), radius: 25, x: 0, y: 15)
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.8)) {
                animationPhase = 1
            }
        }
        .alert("Cancel Appointment", isPresented: $showCancelConfirmation) {
            Button("Keep Appointment", role: .cancel) { }
            Button("Cancel Appointment", role: .destructive) {
                cancelAppointment()
            }
        } message: {
            Text("Are you sure you want to cancel this appointment? This action cannot be undone and you may need to reschedule.")
        }
    }
    
    private var canCancelAppointment: Bool {
        // Allow cancellation for pending, accepted appointments that haven't started yet
        return (appointment.status == .pending || appointment.status == .accepted) && appointment.isUpcoming()
    }
    
    // MARK: - Premium Header
    private var premiumDetailHeader: some View {
        VStack(spacing: 16) {
            // Drag indicator
            RoundedRectangle(cornerRadius: 3)
                .fill(.white.opacity(0.4))
                .frame(width: 40, height: 6)
                .padding(.top, 16)
            
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Appointment Details")
                        .font(.system(size: 28, weight: .black, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    .white,
                                    FitConnectColors.accentBlue.opacity(0.9),
                                    FitConnectColors.accentPurple.opacity(0.8)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                    
                    Text(formatDate(appointment.startTime.dateValue()))
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
                
                Button {
                    dismiss()
                } label: {
                    ZStack {
                        Circle()
                            .fill(.white.opacity(0.1))
                            .frame(width: 44, height: 44)
                            .overlay(
                                Circle()
                                    .stroke(.white.opacity(0.3), lineWidth: 1)
                            )
                        
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                .buttonStyle(PremiumPressStyle())
            }
            .padding(.horizontal, 24)
        }
        .padding(.bottom, 24)
        .background(
            LinearGradient(
                colors: [
                    FitConnectColors.accentBlue.opacity(0.15),
                    .clear
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
    
    // MARK: - Hero Appointment Info
    private var heroAppointmentInfo: some View {
        VStack(spacing: 24) {
            // Main appointment time display
            VStack(spacing: 12) {
                Text(appointment.timeRangeString)
                    .font(.system(size: 36, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                
                Text(appointment.durationString)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white.opacity(0.8))
            }
            
            // Status and countdown
            HStack(spacing: 16) {
                // Status badge
                Text(appointment.status.displayName)
                    .font(.system(size: 14, weight: .black, design: .rounded))
                    .foregroundColor(appointment.status.color)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(appointment.status.color.opacity(0.25))
                            .overlay(
                                Capsule()
                                    .stroke(appointment.status.color.opacity(0.5), lineWidth: 1)
                            )
                    )
                
                Spacer()
                
                // Countdown if upcoming
                if appointment.isUpcoming() {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Starts in")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                        
                        Text(timeUntilAppointment())
                            .font(.system(size: 16, weight: .bold, design: .monospaced))
                            .foregroundColor(FitConnectColors.accentBlue)
                    }
                }
            }
            
            // Dietitian card with premium styling
            HStack(spacing: 20) {
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    FitConnectColors.accentBlue.opacity(0.4),
                                    FitConnectColors.accentBlue.opacity(0.1)
                                ],
                                center: .center,
                                startRadius: 10,
                                endRadius: 50
                            )
                        )
                        .frame(width: 80, height: 80)
                        .overlay(
                            Circle()
                                .stroke(FitConnectColors.accentBlue.opacity(0.5), lineWidth: 2)
                        )
                    
                    Image(systemName: "stethoscope")
                        .font(.system(size: 32, weight: .semibold))
                        .foregroundColor(FitConnectColors.accentBlue)
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("Your Dietitian")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text("Professional nutrition consultation")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                    
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.green)
                        
                        Text("Verified Expert")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.green)
                    }
                }
                
                Spacer()
            }
        }
        .padding(32)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(
                    LinearGradient(
                        colors: [
                            .white.opacity(0.08),
                            .white.opacity(0.03)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(.white.opacity(0.15), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 6)
    }
    
    // MARK: - Details Grid
    private var appointmentDetailsGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 16) {
            premiumDetailCard(
                icon: "calendar.circle.fill",
                iconColor: FitConnectColors.accentPurple,
                title: "Date",
                value: formatDate(appointment.startTime.dateValue())
            )
            
            premiumDetailCard(
                icon: "clock.circle.fill",
                iconColor: FitConnectColors.accentBlue,
                title: "Duration",
                value: appointment.durationString
            )
            
            if appointment.isUpcoming() {
                premiumDetailCard(
                    icon: "hourglass.circle.fill",
                    iconColor: .orange,
                    title: "Countdown",
                    value: timeUntilAppointment()
                )
                
                premiumDetailCard(
                    icon: "bell.circle.fill",
                    iconColor: .green,
                    title: "Reminder",
                    value: "15 min before"
                )
            }
        }
    }
    
    private func premiumDetailCard(icon: String, iconColor: Color, title: String, value: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 28, weight: .medium))
                .foregroundColor(iconColor)
            
            VStack(spacing: 4) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white.opacity(0.7))
                
                Text(value)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(iconColor.opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Notes Display
    private func premiumNotesDisplay(notes: String) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "note.text.badge.plus")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.orange)
                
                Text("Appointment Notes")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Spacer()
            }
            
            Text(notes)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white.opacity(0.85))
                .lineSpacing(6)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 4)
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(.orange.opacity(0.4), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
    
    // MARK: - Action Buttons
    private var premiumActionButtons: some View {
        VStack(spacing: 16) {
            Button {
                showCancelConfirmation = true
            } label: {
                HStack(spacing: 16) {
                    if isCancelling {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.9)
                    } else {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 20, weight: .bold))
                    }
                    
                    Text(isCancelling ? "Cancelling..." : "Cancel Appointment")
                        .font(.system(size: 18, weight: .black, design: .rounded))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(
                            LinearGradient(
                                colors: [.red, .red.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .shadow(color: .red.opacity(0.4), radius: 15, x: 0, y: 8)
                .scaleEffect(isCancelling ? 0.98 : 1.0)
            }
            .buttonStyle(PremiumPressStyle())
            .disabled(isCancelling)
            
            Button {
                dismiss()
            } label: {
                Text("Close")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.white.opacity(0.8))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(.white.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(.white.opacity(0.3), lineWidth: 1)
                            )
                    )
            }
            .buttonStyle(PremiumPressStyle())
        }
        .padding(.top, 8)
    }
    
    // MARK: - Helper Methods
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        if Calendar.current.isDateInToday(date) {
            return "Today"
        } else if Calendar.current.isDateInTomorrow(date) {
            return "Tomorrow"
        } else {
            formatter.dateFormat = "EEEE, MMMM d, yyyy"
            return formatter.string(from: date)
        }
    }
    
    private func timeUntilAppointment() -> String {
        let now = Date()
        let appointmentTime = appointment.startTime.dateValue()
        let interval = appointmentTime.timeIntervalSince(now)
        
        if interval < 0 {
            return "Started"
        }
        
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        
        if hours > 24 {
            let days = hours / 24
            return "\(days) day\(days == 1 ? "" : "s")"
        } else if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes) minute\(minutes == 1 ? "" : "s")"
        }
    }
    
    private func cancelAppointment() {
        isCancelling = true
        onCancel()
        
        // Smooth dismissal after cancellation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            dismiss()
        }
    }
}

#if DEBUG
@available(iOS 16.0, *)
struct ClientAppointmentDetailModal_Previews: PreviewProvider {
    static var previews: some View {
        ClientAppointmentDetailModal(
            appointment: Appointment(
                clientId: "client123",
                startTime: Date().addingTimeInterval(3600),
                endTime: Date().addingTimeInterval(7200),
                notes: "This is a sample appointment note for preview purposes. Let's discuss my current diet plan and how we can improve it for better results.",
                status: .accepted
            ),
            onCancel: {}
        )
        .preferredColorScheme(.dark)
    }
}
#endif