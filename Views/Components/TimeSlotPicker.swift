import SwiftUI

struct TimeSlotPicker: View {
    @Binding var selectedTime: Date
    let selectedDate: Date
    let existingAppointments: [Appointment]
    let startHour: Int = 6  // 6 AM
    let endHour: Int = 20   // 8 PM
    let slotDuration: Int = 30 // 30 minutes
    
    @State private var timeSlots: [TimeSlot] = []
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Available Time Slots")
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(timeSlots, id: \.time) { slot in
                        TimeSlotButton(
                            slot: slot,
                            isSelected: Calendar.current.isDate(slot.time, equalTo: selectedTime, toGranularity: .minute),
                            action: {
                                selectedTime = slot.time
                            }
                        )
                    }
                }
                .padding(.horizontal, 16)
            }
            .padding(.horizontal, -16)
        }
        .onAppear {
            generateTimeSlots()
        }
        .onChange(of: selectedDate) { _ in
            generateTimeSlots()
        }
        .onChange(of: existingAppointments) { _ in
            generateTimeSlots()
        }
    }
    
    private func generateTimeSlots() {
        let calendar = Calendar.current
        var slots: [TimeSlot] = []
        
        // Generate time slots for the selected date
        for hour in startHour..<endHour {
            for minute in stride(from: 0, to: 60, by: slotDuration) {
                var components = calendar.dateComponents([.year, .month, .day], from: selectedDate)
                components.hour = hour
                components.minute = minute
                
                guard let slotTime = calendar.date(from: components) else { continue }
                
                // Check if this slot is available
                let isAvailable = checkSlotAvailability(slotTime)
                let isPast = slotTime < Date()
                
                let slot = TimeSlot(
                    time: slotTime,
                    isAvailable: isAvailable && !isPast,
                    isPast: isPast
                )
                
                slots.append(slot)
            }
        }
        
        timeSlots = slots
    }
    
    private func checkSlotAvailability(_ slotTime: Date) -> Bool {
        let calendar = Calendar.current
        let slotEnd = calendar.date(byAdding: .minute, value: slotDuration, to: slotTime) ?? slotTime
        
        // Check if this slot conflicts with existing appointments
        for appointment in existingAppointments {
            if appointment.status == .cancelled { continue }
            
            let appointmentStart = appointment.startTime.dateValue()
            let appointmentEnd = appointment.endTime.dateValue()
            
            // Check for overlap
            if slotTime < appointmentEnd && slotEnd > appointmentStart {
                return false
            }
        }
        
        return true
    }
}

// MARK: - TimeSlot Model

struct TimeSlot {
    let time: Date
    let isAvailable: Bool
    let isPast: Bool
    
    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: time)
    }
}

// MARK: - TimeSlotButton

struct TimeSlotButton: View {
    let slot: TimeSlot
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(slot.formattedTime)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(textColor)
                
                Circle()
                    .fill(dotColor)
                    .frame(width: 6, height: 6)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(backgroundColor)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(borderColor, lineWidth: 2)
            )
        }
        .disabled(!slot.isAvailable)
        .opacity(slot.isAvailable ? 1.0 : 0.5)
    }
    
    private var textColor: Color {
        if isSelected {
            return .white
        } else if slot.isPast {
            return Color(hex: "#8A8F9B")
        } else if slot.isAvailable {
            return .white
        } else {
            return Color(hex: "#8A8F9B")
        }
    }
    
    private var backgroundColor: Color {
        if isSelected {
            return Color(hex: "#6E56E9")
        } else if slot.isAvailable {
            return Color.black.opacity(0.3)
        } else {
            return Color.gray.opacity(0.2)
        }
    }
    
    private var borderColor: Color {
        if isSelected {
            return Color(hex: "#6E56E9")
        } else {
            return Color.gray.opacity(0.3)
        }
    }
    
    private var dotColor: Color {
        if isSelected {
            return .white
        } else if slot.isAvailable {
            return Color.green
        } else if slot.isPast {
            return Color.gray
        } else {
            return Color.red
        }
    }
}

// MARK: - TimeSlotPicker Preview

#if DEBUG
struct TimeSlotPicker_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color(hex: "#0D0F14").ignoresSafeArea()
            
            VStack {
                TimeSlotPicker(
                    selectedTime: Binding.constant(Date()),
                    selectedDate: Date(),
                    existingAppointments: []
                )
                .padding()
                
                Spacer()
            }
        }
        .preferredColorScheme(.dark)
    }
}
#endif
