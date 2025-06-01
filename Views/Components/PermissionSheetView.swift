import SwiftUI

struct PermissionSheetView: View {
    @Environment(\.dismiss) var dismiss // Use new dismiss environment variable
    
    var body: some View {
        NavigationView { // Sheets often benefit from their own NavigationView for a title bar
            ZStack {
                UnifiedBackground()
                
                VStack(spacing: 32) {
                    Spacer()
                    
                    Image(systemName: "shield.checkered")
                        .font(.system(size: 80, weight: .thin))
                        .foregroundColor(FitConnectColors.accentCyan)
                    
                    VStack(spacing: 16) {
                        Text("Privacy Permission")
                            .font(FitConnectFonts.largeTitle())
                            .foregroundColor(FitConnectColors.textPrimary)
                            .multilineTextAlignment(.center)
                        
                        GlassCard(opacity: 0.15) { // Using GlassCard
                            Text("This helps us improve FitConnect while keeping your personal data completely private. You can change this anytime in Settings.")
                                .font(FitConnectFonts.body)
                                .foregroundColor(FitConnectColors.textPrimary)
                                .multilineTextAlignment(.center)
                                .lineSpacing(4)
                        }
                        .padding(.horizontal, 24)
                    }
                    
                    Spacer()
                    
                    VStack(spacing: 16) {
                        EnhancedPrimaryButton(title: "Allow Tracking") { // Using EnhancedPrimaryButton
                            // Handle permission request
                            dismiss()
                        }
                        
                        Button("Ask Me Later") {
                            dismiss()
                        }
                        .font(FitConnectFonts.body)
                        .foregroundColor(FitConnectColors.textTertiary)
                    }
                    .padding(.horizontal, 24)
                    
                    Spacer().frame(height: 40)
                }
                .padding(.vertical)
            }
            .navigationTitle("Privacy")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(FitConnectColors.textPrimary)
                }
            }
        }
    }
}

struct PermissionSheetView_Previews: PreviewProvider {
    static var previews: some View {
        PermissionSheetView()
            .preferredColorScheme(.dark)
    }
}
