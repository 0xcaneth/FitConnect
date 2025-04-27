// Views/TermsView.swift
import SwiftUI

struct TermsView: View {
    @State private var accepted = false

    // Uzun “Terms & Conditions” metni
    private let termsText = """
    By using FitConnect’s AI-powered features, you accept that results may not always be entirely accurate, as they are generated using computer vision and machine learning technology.

    The accuracy of FitConnect’s assessments and recommendations can be influenced by factors such as the quality of input data and the inherent limitations of these technologies.

    It is essential for you to exercise your own discretion and not rely solely on FitConnect’s results for making critical decisions, especially in determining whether something is edible or not. When it comes to matters like dietary choices or health-related decisions, we advise you to consult a qualified professional.
    """

    var body: some View {
        ZStack {
            // Arka plan gradyan
            LinearGradient(
                gradient: Gradient(colors: [Color("PrimaryGradientStart"), Color("PrimaryGradientEnd")]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 16) {
                // Başlık ve Back butonu
                HStack {
                    Button(action: { /* pop back */ }) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.white)
                            .font(.title2)
                    }
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 20)

                Text("Terms & Conditions")
                    .font(.largeTitle).bold()
                    .foregroundColor(.white)
                    .padding(.bottom, 8)

                // Scrollable metin kutusu
                ScrollView {
                    Text(termsText)
                        .font(.body)
                        .foregroundColor(.white.opacity(0.9))
                        .padding()
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(12)
                        .padding(.horizontal, 16)
                }

                // Onay toggle’ı
                Toggle(isOn: $accepted) {
                    Text("I agree to the Terms & Conditions")
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 16)

                // Continue butonu—sadece onaylıysa aktif
                NavigationLink {
                    LoginView()
                } label: {
                    Text("Accept & Continue")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(accepted ? Color.white : Color.white.opacity(0.5))
                        .foregroundColor(Color("PrimaryGradientStart"))
                        .cornerRadius(10)
                        .padding(.horizontal, 32)
                }
                .disabled(!accepted)

                Spacer()
            }
        }
    }
}

struct TermsView_Previews: PreviewProvider {
    static var previews: some View {
        TermsView()
    }
}
