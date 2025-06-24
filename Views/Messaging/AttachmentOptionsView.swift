//
//  AttachmentOptionsView.swift
//  FitConnect
//

import SwiftUI

@available(iOS 16.0, *)
struct AttachmentOptionsView: View {
    let onPhotoSelected: () -> Void
    let onVideoSelected: () -> Void
    let onWorkoutVideoSelected: () -> Void
    let onFileSelected: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            header
            options
        }
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color(hex: "#0D0F14"), Color(hex: "#1A1B25")]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
        .presentationDetents([.height(450)])
        .presentationDragIndicator(.hidden)
    }
    
    // MARK: - Sub-views
    
    private var header: some View {
        HStack {
            Text("Share Content")
                .font(.custom("SFProRounded-Semibold", size: 18))
                .foregroundColor(.white)
            
            Spacer()
            
            Button(action: onCancel) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color(hex: "#0D0F14"), Color(hex: "#1A1B25")]),
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
    
    private var options: some View {
        VStack(spacing: 16) {
            // Featured option - Workout Video
            workoutVideoButton
            
            // Divider
            Rectangle()
                .fill(Color.white.opacity(0.1))
                .frame(height: 1)
                .padding(.horizontal, 20)
            
            optionButton(
                colors: [.blue, .purple],
                systemImage: "photo.fill",
                title: "Photo",
                subtitle: "Share an image from your library",
                action: onPhotoSelected
            )
            
            optionButton(
                colors: [.red, .orange],
                systemImage: "video.fill",
                title: "Video",
                subtitle: "Record a quick video message",
                action: onVideoSelected
            )
            
            optionButton(
                colors: [.orange, .red],
                systemImage: "doc.fill",
                title: "Document",
                subtitle: "Share a file or document",
                action: onFileSelected
            )
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 30)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color(hex: "#0D0F14"), Color(hex: "#1A1B25")]),
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
    
    private var workoutVideoButton: some View {
        Button(action: {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            onWorkoutVideoSelected()
        }) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [FitConnectColors.accentPurple, Color.purple]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: "figure.run")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Workout Video")
                            .font(.custom("SFProRounded-Bold", size: 18))
                            .foregroundColor(.white)
                        
                        // "Featured" badge
                        Text("NEW")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.green)
                            .cornerRadius(4)
                    }
                    
                    Text("Record & share your workout progress")
                        .font(.custom("SFProText-Regular", size: 14))
                        .foregroundColor(FitConnectColors.accentPurple.opacity(0.8))
                    
                    Text("• Up to 60 seconds • Trim & edit • HD quality")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.6))
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(FitConnectColors.accentPurple)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                FitConnectColors.accentPurple.opacity(0.15),
                                FitConnectColors.accentPurple.opacity(0.05)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(FitConnectColors.accentPurple.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
    
    private func optionButton(
        colors: [Color],
        systemImage: String,
        title: String,
        subtitle: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            action()
        }) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: colors),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: systemImage)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.custom("SFProRounded-Semibold", size: 16))
                        .foregroundColor(.white)
                    Text(subtitle)
                        .font(.custom("SFProText-Regular", size: 14))
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.1))
            )
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Helpers
    
    private var globalGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [Color(hex: "#0D0F14"), Color(hex: "#1A1B25")]),
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

#if DEBUG
@available(iOS 16.0, *)
struct AttachmentOptionsView_Previews: PreviewProvider {
    static var previews: some View {
        AttachmentOptionsView(
            onPhotoSelected: {},
            onVideoSelected: {},
            onWorkoutVideoSelected: {},
            onFileSelected: {},
            onCancel: {}
        )
        .preferredColorScheme(.dark)
    }
}
#endif
