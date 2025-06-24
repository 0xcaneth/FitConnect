import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct DebugUserInfoView: View {
    @EnvironmentObject var session: SessionStore
    @State private var userDoc: [String: Any]?
    @State private var isLoading = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Debug User Info")
                .font(.headline)
            
            if isLoading {
                ProgressView("Loading...")
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Session User ID: \(session.currentUserId ?? "nil")")
                    Text("Session Expert ID: \(session.currentUser?.expertId ?? "nil")")
                    Text("Session Email: \(session.currentUser?.email ?? "nil")")
                    
                    if let userDoc = userDoc {
                        Text("Firestore Expert ID: \(userDoc["expertId"] as? String ?? "nil")")
                        Text("Firestore Email: \(userDoc["email"] as? String ?? "nil")")
                        Text("Firestore Role: \(userDoc["role"] as? String ?? "nil")")
                    }
                }
            }
            
            Button("Refresh User Data") {
                refreshUserData()
            }
        }
        .padding()
        .onAppear {
            refreshUserData()
        }
    }
    
    private func refreshUserData() {
        guard let userId = session.currentUserId else { return }
        
        isLoading = true
        
        let db = Firestore.firestore()
        db.collection("users").document(userId).getDocument { snapshot, error in
            DispatchQueue.main.async {
                self.isLoading = false
                
                if let error = error {
                    print("Error fetching user doc: \(error)")
                    return
                }
                
                self.userDoc = snapshot?.data()
                print("User document: \(self.userDoc ?? [:])")
            }
        }
    }
}