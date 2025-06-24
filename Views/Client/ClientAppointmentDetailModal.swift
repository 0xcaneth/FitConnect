import SwiftUI
import FirebaseFirestore

@available(iOS 16.0, *)
struct ClientAppointmentDetailModal: View {
    @Environment(\.dismiss) private var dismiss
    let appointment: Appointment
    let onCancel: () -> Void
    
    @State private var isCancelling = false
    @State private var showCancelConfirmation = false
    
    var body: some View {
        ZStack {
            // Background overlay with blur
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture {
                    dismiss()
                }
            
            // Modal content
            VStack(spacing: 0) {
                // Header with gradient
                headerView
                
                // Content
                ScrollView {
                    VStack(spacing: 20) {
                        // Dietitian info with glass effect
                        dietitianInfoSection
                        
                        // Appointment details with clean design
                        appointmentDetailsSection
                        
                        // Notes section
                        if let notes = appointment.notes, !notes.isEmpty {
                            notesSection(notes: notes)
                        }
                        
                        // Actions with better spacing
                        if canCancelAppointment {
                            actionsSection
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 24)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(maxHeight: UIScreen.main.bounds.height * 0.8)
            .background(
                // Glass morphism background
                RoundedRectangle(cornerRadius: 28)
                    .fill(Color.black.opacity(0.85))
                    .overlay(
                        RoundedRectangle(cornerRadius: 28)
                            .stroke(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.2), Color.clear],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
            )
            .padding(.horizontal, 16)
            .padding(.top, UIScreen.main.bounds.height * 0.15)
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
    
    private var headerView: some View {
        VStack(spacing: 0) {
            // Drag indicator
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.white.opacity(0.3))
                .frame(width: 36, height: 5)
                .padding(.top, 12)
                .padding(.bottom, 20)
            
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Appointment Details")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text(formatDate(appointment.startTime.dateValue()))
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
                
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white.opacity(0.6))
                        .frame(width: 32, height: 32)
                        .background(Color.white.opacity(0.1))
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 20)
        }
        .background(
            LinearGradient(
                colors: [FitConnectColors.accentBlue.opacity(0.3), Color.clear],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
    
    private var dietitianInfoSection: some View {
        HStack(spacing: 16) {
            // Enhanced avatar with gradient
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [FitConnectColors.accentBlue, FitConnectColors.accentPurple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 64, height: 64)
                
                Image(systemName: "stethoscope")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text("Your Dietitian")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
                
                HStack(spacing: 8) {
                    Circle()
                        .fill(appointment.status.color)
                        .frame(width: 8, height: 8)
                    
                    Text(appointment.status.displayName)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(appointment.status.color)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(appointment.status.color.opacity(0.15))
                        .clipShape(Capsule())
                }
            }
            
            Spacer()
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
        )
    }
    
    private var appointmentDetailsSection: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Appointment Details")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 16)
            
            VStack(spacing: 0) {
                appointmentDetailRow(
                    icon: "clock.fill",
                    title: "Time",
                    value: appointment.timeRangeString,
                    isFirst: true
                )
                
                appointmentDetailRow(
                    icon: "timer",
                    title: "Duration",
                    value: appointment.durationString
                )
                
                appointmentDetailRow(
                    icon: "calendar",
                    title: "Date",
                    value: formatDate(appointment.startTime.dateValue())
                )
                
                if appointment.isUpcoming() {
                    appointmentDetailRow(
                        icon: "hourglass",
                        title: "Starts in",
                        value: timeUntilAppointment(),
                        isLast: true
                    )
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
        )
    }
    
    private func appointmentDetailRow(icon: String, title: String, value: String, isFirst: Bool = false, isLast: Bool = false) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(FitConnectColors.accentBlue.opacity(0.2))
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(FitConnectColors.accentBlue)
                }
                
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                
                Spacer()
                
                Text(value)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            
            if !isLast {
                Rectangle()
                    .fill(Color.white.opacity(0.1))
                    .frame(height: 0.5)
                    .padding(.leading, 72)
            }
        }
    }
    
    private func notesSection(notes: String) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "note.text")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(FitConnectColors.accentBlue)
                
                Text("Notes")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                Spacer()
            }
            
            Text(notes)
                .font(.system(size: 15, weight: .regular))
                .foregroundColor(.white.opacity(0.8))
                .lineSpacing(4)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
        )
    }
    
    private var actionsSection: some View {
        VStack(spacing: 12) {
            Button {
                showCancelConfirmation = true
            } label: {
                HStack(spacing: 10) {
                    if isCancelling {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.9)
                    } else {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 18, weight: .medium))
                    }
                    
                    Text(isCancelling ? "Cancelling..." : "Cancel Appointment")
                        .font(.system(size: 17, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(
                    LinearGradient(
                        colors: [Color.red, Color.red.opacity(0.8)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.red.opacity(0.2), lineWidth: 1)
                )
            }
            .disabled(isCancelling)
            .scaleEffect(isCancelling ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: isCancelling)
            
            Button {
                dismiss()
            } label: {
                Text("Close")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white.opacity(0.1))
                    )
            }
        }
        .padding(.top, 8)
    }
    
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
        
        // Simulate delay for user feedback
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
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
                notes: "This is a sample appointment note for preview purposes.",
                status: .accepted
            ),
            onCancel: {}
        )
        .preferredColorScheme(.dark)
    }
}
#endif