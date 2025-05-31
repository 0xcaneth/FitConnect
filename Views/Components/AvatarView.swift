import SwiftUI

struct AvatarView: View {
    let initials: String
    
    var body: some View {
        Text(initials)
            .font(.system(size: 18, weight: .bold))
            .foregroundColor(FitConnectColors.gradientBottom) 
            .frame(width: 50, height: 50)
            .background(
                Circle()
                    .fill(Color.white)
                    .shadow(
                        color: .black.opacity(0.15),
                        radius: 6,
                        x: 0,
                        y: 3
                    )
            )
    }
}
