import SwiftUI
import FirebaseFirestore

struct EditPostView: View {
    let post: FeedPost
    @EnvironmentObject var session: SessionStore
    @Environment(\.presentationMode) var presentationMode
    
    @State private var editedContent: String = ""
    @State private var isUpdating: Bool = false
    @State private var showingAlert: Bool = false
    @State private var alertMessage: String = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "#0D0F14").ignoresSafeArea()
                
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Edit your \(post.type.displayName.lowercased())")
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                        
                        ZStack(alignment: .topLeading) {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(hex: "#1C1E25").opacity(0.7))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(
                                            LinearGradient(
                                                gradient: Gradient(colors: [Color(hex: "#4A00E0"), Color(hex: "#00D4FF")]),
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            ),
                                            lineWidth: 1.5
                                        )
                                )
                                .frame(minHeight: 120)

                            if editedContent.isEmpty {
                                Text("Enter your content...")
                                    .font(.system(size: 16, design: .rounded))
                                    .foregroundColor(Color(hex: "#6A6A6A"))
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                                    .allowsHitTesting(false)
                            }
                            
                            TextEditor(text: $editedContent)
                                .font(.system(size: 16, design: .rounded))
                                .foregroundColor(.white)
                                .background(Color.clear)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .frame(minHeight: 120)
                        }
                    }
                    
                    Spacer()
                }
                .padding(20)
            }
            .navigationTitle("Edit Post")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(Color(hex: "#B0B3BA"))
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        updatePost()
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(canSave() ? Color(hex: "#6E56E9") : Color(hex: "#B0B3BA"))
                    .disabled(!canSave() || isUpdating)
                }
            }
        }
        .onAppear {
            editedContent = post.content
        }
        .alert("Update Status", isPresented: $showingAlert) {
            Button("OK") {
                if alertMessage.contains("Success") {
                    presentationMode.wrappedValue.dismiss()
                }
            }
        } message: {
            Text(alertMessage)
        }
    }
    
    private func canSave() -> Bool {
        let trimmedContent = editedContent.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmedContent.isEmpty && trimmedContent != post.content
    }
    
    private func updatePost() {
        guard let postId = post.id else { return }
        
        isUpdating = true
        let db = Firestore.firestore()
        
        db.collection("feed").document(postId).updateData([
            "content": editedContent.trimmingCharacters(in: .whitespacesAndNewlines)
        ]) { error in
            DispatchQueue.main.async {
                self.isUpdating = false
                
                if let error = error {
                    self.alertMessage = "Failed to update post: \(error.localizedDescription)"
                    self.showingAlert = true
                } else {
                    self.alertMessage = "Post updated successfully!"
                    self.showingAlert = true
                }
            }
        }
    }
}

#if DEBUG
struct EditPostView_Previews: PreviewProvider {
    static var previews: some View {
        let mockPost = FeedPost(
            authorId: "user1",
            authorName: "John Doe",
            authorPhotoURL: nil,
            type: .motivation,
            content: "Stay motivated!",
            imageURL: nil,
            timestamp: Timestamp(date: Date()),
            likes: []
        )
        
        EditPostView(post: mockPost)
            .environmentObject(SessionStore())
            .preferredColorScheme(.dark)
    }
}
#endif
