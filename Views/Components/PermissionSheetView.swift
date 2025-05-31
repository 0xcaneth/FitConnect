import SwiftUI

struct PermissionSheetView: View {
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ZStack {
            UnifiedBackground()
            
            VStack(spacing: 32) {
                Spacer()
                
                Image(systemName: "shield.checkered")
                    .font(.system(size: 80, weight: .thin))
                    .foregroundColor(FitConnectColors.accentColor)
                
                VStack(spacing: 16) {
                    Text("Privacy Permission")
                        .font(FitConnectFonts.largeTitle())
                        .foregroundColor(FitConnectColors.textPrimary)
                        .multilineTextAlignment(.center)
                    
                    UnifiedCard {
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
                    UnifiedPrimaryButton("Allow Tracking") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    
                    Button("Ask Me Later") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .font(FitConnectFonts.body)
                    .foregroundColor(FitConnectColors.textTertiary)
                }
                .padding(.horizontal, 24)
                
                Spacer().frame(height: 40)
            }
        }
        .navigationTitleCompat("Privacy")
    }
}
