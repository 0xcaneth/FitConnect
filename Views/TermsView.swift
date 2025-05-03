// Views/TermsView.swift
import SwiftUI

struct TermsView: View {
  let onAccept: () -> Void
  let onBack:   () -> Void

  @State private var accepted = false

  private let termsText = """
By using FitConnect’s AI-powered features, you accept that results may not always be entirely accurate ...
(…devam eden koşullar…)
"""

  var body: some View {
    ZStack {
      LinearGradient(
        colors: [Color("PrimaryGradientStart"), Color("PrimaryGradientEnd")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
      )
      .ignoresSafeArea()

      VStack(spacing: 24) {
        HStack {
          Button(action: onBack) {
            Image(systemName: "chevron.left")
              .foregroundColor(.white)
          }
          Spacer()
        }
        .padding()

        Text("Terms & Conditions")
          .font(.largeTitle).bold()
          .foregroundColor(.white)

        ScrollView {
          Text(termsText)
            .foregroundColor(.white.opacity(0.9))
            .padding()
            .background(Color.white.opacity(0.1))
            .cornerRadius(12)
            .padding(.horizontal)
        }

        Toggle("I agree to the Terms & Conditions", isOn: $accepted)
          .toggleStyle(SwitchToggleStyle(tint: .white))
          .foregroundColor(.white)
          .padding(.horizontal, 32)

        Button(action: onAccept) {
          Text("Accept & Continue")
            .bold()
            .frame(maxWidth: .infinity)
            .padding()
            .background(accepted ? Color.white : Color.white.opacity(0.5))
            .foregroundColor(Color("PrimaryGradientStart"))
            .cornerRadius(10)
        }
        .disabled(!accepted)
        .padding(.horizontal, 32)

        Spacer()
      }
    }
  }
}
