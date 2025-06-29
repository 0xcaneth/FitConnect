import SwiftUI
import GoogleSignIn

struct GoogleSignInButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image("GoogleIcon")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 20, height: 20)
                
                Text("Continue with Google")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(Color.clear)
            .overlay(
                RoundedRectangle(cornerRadius: 28)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color(hex: "#00E0FF") ?? .cyan,
                                Color(hex: "#6A00FF") ?? .purple
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        lineWidth: 2
                    )
            )
        }
    }
}

struct ModernGoogleLogo: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.white)
                .frame(width: 20, height: 20)
            
            ZStack {
                Path { path in
                    let center = CGPoint(x: 10, y: 10)
                    let outerRadius: CGFloat = 8.5
                    let innerRadius: CGFloat = 5.5
                    
                    path.addArc(center: center, radius: outerRadius, startAngle: .degrees(45), endAngle: .degrees(315), clockwise: false)
                    
                    path.addLine(to: CGPoint(x: 18.5, y: 8))
                    path.addLine(to: CGPoint(x: 14, y: 8))
                    path.addLine(to: CGPoint(x: 14, y: 12))
                    path.addLine(to: CGPoint(x: 16, y: 12))
                    
                    path.addArc(center: center, radius: innerRadius, startAngle: .degrees(315), endAngle: .degrees(45), clockwise: true)
                    path.closeSubpath()
                }
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.26, green: 0.52, blue: 0.96), 
                            Color(red: 0.13, green: 0.69, blue: 0.30)  
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                
                Path { path in
                    let center = CGPoint(x: 10, y: 10)
                    let radius: CGFloat = 8.5
                    path.move(to: center)
                    path.addArc(center: center, radius: radius, startAngle: .degrees(315), endAngle: .degrees(45), clockwise: false)
                    path.closeSubpath()
                }
                .fill(Color(red: 0.92, green: 0.26, blue: 0.21)) 
                
                Path { path in
                    let center = CGPoint(x: 10, y: 10)
                    let radius: CGFloat = 8.5
                    path.move(to: center)
                    path.addArc(center: center, radius: radius, startAngle: .degrees(45), endAngle: .degrees(135), clockwise: false)
                    path.closeSubpath()
                }
                .fill(Color(red: 0.99, green: 0.73, blue: 0.02)) 
                
                Path { path in
                    let center = CGPoint(x: 10, y: 10)
                    let radius: CGFloat = 8.5
                    path.move(to: center)
                    path.addArc(center: center, radius: radius, startAngle: .degrees(135), endAngle: .degrees(225), clockwise: false)
                    path.closeSubpath()
                }
                .fill(Color(red: 0.13, green: 0.69, blue: 0.30)) 
                
                Path { path in
                    let center = CGPoint(x: 10, y: 10)
                    let radius: CGFloat = 8.5
                    path.move(to: center)
                    path.addArc(center: center, radius: radius, startAngle: .degrees(225), endAngle: .degrees(315), clockwise: false)
                    path.closeSubpath()
                }
                .fill(Color(red: 0.26, green: 0.52, blue: 0.96)) 
                
                Circle()
                    .fill(Color.white)
                    .frame(width: 11, height: 11)
                
                Rectangle()
                    .fill(Color.white)
                    .frame(width: 4, height: 2)
                    .offset(x: 3, y: 1)
            }
            .frame(width: 20, height: 20)
            .clipShape(Circle())
        }
    }
}

struct SimplifiedGoogleLogo: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.white)
                .frame(width: 20, height: 20)
            
            ZStack {
                ForEach(0..<4, id: \.self) { index in
                    Path { path in
                        let center = CGPoint(x: 10, y: 10)
                        let radius: CGFloat = 7.5
                        let startAngle = Double(index * 90 - 45)
                        let endAngle = startAngle + 90
                        
                        path.move(to: center)
                        path.addArc(center: center, radius: radius, startAngle: .degrees(startAngle), endAngle: .degrees(endAngle), clockwise: false)
                        path.closeSubpath()
                    }
                    .fill(googleColors[index])
                }
                
                Circle()
                    .fill(Color.white)
                    .frame(width: 8, height: 8)
                
                Rectangle()
                    .fill(Color.white)
                    .frame(width: 8, height: 3)
                    .offset(x: 2.5, y: 0)
                
                Rectangle()
                    .fill(googleColors[0]) 
                    .frame(width: 3, height: 1.5)
                    .offset(x: 4, y: 0.75)
            }
        }
    }
    
    private var googleColors: [Color] {
        [
            Color(red: 0.26, green: 0.52, blue: 0.96), 
            Color(red: 0.13, green: 0.69, blue: 0.30), 
            Color(red: 0.99, green: 0.73, blue: 0.02), 
            Color(red: 0.92, green: 0.26, blue: 0.21)  
        ]
    }
}

#if DEBUG
struct GoogleSignInButton_Previews: PreviewProvider {
    static var previews: some View {
        GoogleSignInButton(action: {})
            .padding()
            .background(Color.black)
            .preferredColorScheme(.dark)
    }
}
#endif