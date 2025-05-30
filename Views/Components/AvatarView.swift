import SwiftUI

struct AvatarView: View {
    let initials: String
    
    var body: some View {
        Text(initials)
            .font(.title2.bold())
            .foregroundColor(.white)
            .frame(width: 44, height: 44)
            .background(Color.accentColor)
            .clipShape(Circle())
    }
}