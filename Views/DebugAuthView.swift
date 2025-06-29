import SwiftUI
import FirebaseAuth
import FirebaseFirestore

@available(iOS 16.0, *)
struct DebugAuthView: View {
    @State private var email = ""
    @State private var debugOutput = ""
    @State private var isLoading = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Debug Auth Issues")
                .font(.title)
                .foregroundColor(.white)
            
            TextField("Enter email to debug", text: $email)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)
            
            Button("Debug User Data") {
                debugUserData()
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)
            .disabled(isLoading)
            
            if isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
            }
            
            ScrollView {
                Text(debugOutput)
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(.white)
                    .padding()
            }
            .background(Color.black.opacity(0.3))
            .cornerRadius(8)
            .padding()
        }
        .background(Color.black)
        .preferredColorScheme(.dark)
    }
    
    private func debugUserData() {
        isLoading = true
        debugOutput = "Starting debug...\n"
        
        Task {
            do {
                // Try to find user by email
                let querySnapshot = try await Firestore.firestore()
                    .collection("users")
                    .whereField("email", isEqualTo: email)
                    .getDocuments()
                
                await MainActor.run {
                    debugOutput += "Found \(querySnapshot.documents.count) documents for email: \(email)\n\n"
                    
                    for document in querySnapshot.documents {
                        debugOutput += "Document ID: \(document.documentID)\n"
                        debugOutput += "Data: \(document.data())\n"
                        
                        if let role = document.data()["role"] as? String {
                            debugOutput += "Role: '\(role)' (type: \(type(of: role)))\n"
                            
                            if let userRole = UserRole(rawValue: role) {
                                debugOutput += "UserRole enum: \(userRole) (\(userRole.displayName))\n"
                            } else {
                                debugOutput += "❌ Cannot parse role '\(role)' as UserRole\n"
                            }
                        } else {
                            debugOutput += "❌ No role field found or not a string\n"
                        }
                        
                        if let isEmailVerified = document.data()["isEmailVerified"] as? Bool {
                            debugOutput += "Email Verified: \(isEmailVerified)\n"
                        }
                        
                        debugOutput += "\n"
                    }
                    
                    isLoading = false
                }
                
            } catch {
                await MainActor.run {
                    debugOutput += "❌ Error: \(error.localizedDescription)\n"
                    isLoading = false
                }
            }
        }
    }
}

#if DEBUG
@available(iOS 16.0, *)
struct DebugAuthView_Previews: PreviewProvider {
    static var previews: some View {
        DebugAuthView()
    }
}
#endif