import SwiftUI

struct NewClientModalView: View {
    @State private var fullName: String = ""
    @State private var email: String = ""
    @State private var showError: Bool = false
    @State private var showModal: Bool = false
    
    let onCancel: () -> Void
    let onAddClient: (String, String) -> Void
    
    var body: some View {
        ZStack {
            // Semi-opaque black overlay background
            Color.black.opacity(0.7)
                .ignoresSafeArea()
                .onTapGesture {
                    dismissModal()
                }
            
            // Modal Container
            VStack(spacing: 0) {
                Spacer()
                
                VStack(spacing: 0) {
                    // Header with title and cancel button
                    HStack {
                        Spacer()
                        
                        Text("New Client")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.black)
                        
                        Spacer()
                        
                        Button("Cancel") {
                            dismissModal()
                        }
                        .font(.system(size: 18))
                        .foregroundColor(.black)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 32)
                    .padding(.bottom, 40)
                    
                    // Input Fields
                    VStack(spacing: 20) {
                        // Full Name Field
                        TextField("Enter full name", text: $fullName)
                            .font(.system(size: 18))
                            .foregroundColor(.black)
                            .padding(.horizontal, 20)
                            .frame(height: 50)
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(12)
                            .onChange(of: fullName) { _ in
                                if showError {
                                    validateFields()
                                }
                            }
                        
                        // Email Field
                        TextField("Enter email address", text: $email)
                            .font(.system(size: 18))
                            .foregroundColor(.black)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .padding(.horizontal, 20)
                            .frame(height: 50)
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(12)
                            .onChange(of: email) { _ in
                                if showError {
                                    validateFields()
                                }
                            }
                    }
                    .padding(.horizontal, 24)
                    
                    // Error Banner
                    if showError {
                        HStack {
                            Text("Missing or invalid information")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color(hex: "#FF4C4C"))
                        .cornerRadius(12)
                        .padding(.horizontal, 24)
                        .padding(.top, 20)
                        .transition(.scale.combined(with: .opacity))
                    }
                    
                    Spacer()
                    
                    // Add Client Button
                    Button(action: addClient) {
                        Text("Add Client")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 60)
                            .background(
                                LinearGradient(
                                    colors: [Color(hex: "#6B46C1") ?? .purple, Color(hex: "#3C00FF") ?? .indigo],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(30)
                            .opacity(isFormValid ? 1.0 : 0.5)
                    }
                    .disabled(!isFormValid)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                }
                .background(Color.white)
                .cornerRadius(24, corners: [.topLeft, .topRight])
                .frame(maxWidth: .infinity)
                .frame(height: UIScreen.main.bounds.height * 0.8)
                .offset(y: showModal ? 0 : UIScreen.main.bounds.height)
                .animation(.spring(response: 0.6, dampingFraction: 0.8, blendDuration: 0), value: showModal)
            }
        }
        .onAppear {
            withAnimation {
                showModal = true
            }
        }
    }
    
    private var isFormValid: Bool {
        return !fullName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
               !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
               isValidEmail(email)
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    private func validateFields() {
        showError = !isFormValid
    }
    
    private func addClient() {
        if isFormValid {
            onAddClient(fullName.trimmingCharacters(in: .whitespacesAndNewlines), 
                       email.trimmingCharacters(in: .whitespacesAndNewlines))
            dismissModal()
        } else {
            withAnimation(.easeInOut(duration: 0.3)) {
                showError = true
            }
        }
    }
    
    private func dismissModal() {
        withAnimation {
            showModal = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            onCancel()
        }
    }
}

#if DEBUG
struct NewClientModalView_Previews: PreviewProvider {
    static var previews: some View {
        NewClientModalView(
            onCancel: {},
            onAddClient: { _, _ in }
        )
    }
}
#endif
