import SwiftUI
import FirebaseFirestore

@available(iOS 16.0, *)
struct RootView: View {
    @EnvironmentObject var session: SessionStore
    @State private var selectedChatId: String? = nil
    @State private var showingChat = false
    
    var body: some View {
        ZStack {
            Group {
                if !session.isAuthenticated {
                    AuthFlowView()
                        .onAppear {
                            print("[RootView] 🔒 Not authenticated, showing AuthFlowView")
                            print("[RootView] 🔍 Debug - isAuthenticated: \(session.isAuthenticated)")
                            print("[RootView] 🔍 Debug - currentUserId: \(session.currentUserId ?? "nil")")
                        }
                } else if session.isLoadingUser {
                    VStack(spacing: 20) {
                        ProgressView("Loading your profile...")
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(1.2)
                        
                        Text("Getting everything ready...")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                        
                        // Debug info in development
                        #if DEBUG
                        VStack(spacing: 4) {
                            Text("Debug Info:")
                                .font(.caption2)
                                .foregroundColor(.gray)
                            Text("Loading User: \(session.isLoadingUser)")
                                .font(.caption2)
                                .foregroundColor(.gray)
                            Text("Is Logged In: \(session.isLoggedIn)")
                                .font(.caption2)
                                .foregroundColor(.gray)
                            Text("Current Role: '\(session.role)'")
                                .font(.caption2)
                                .foregroundColor(.gray)
                            Text("User ID: \(session.currentUserId ?? "nil")")
                                .font(.caption2)
                                .foregroundColor(.gray)
                        }
                        .padding(.top, 20)
                        #endif
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black)
                    .onAppear {
                        print("[RootView] ⏳ Loading user data...")
                        print("[RootView] 🔍 isLoadingUser: \(session.isLoadingUser)")
                        print("[RootView] 🔍 isLoggedIn: \(session.isLoggedIn)")
                    }
                } else if session.isReadyForNavigation && !session.role.isEmpty {
                    Group {
                        if session.role == "client" {
                            ClientTabView()
                                .onAppear {
                                    print("[RootView] 👤 Routing to ClientTabView for client")
                                }
                        } else if session.role == "dietitian" {
                            DietitianHomeTabView()
                                .onAppear {
                                    print("[RootView] 👩‍⚕️ Routing to DietitianHomeTabView for dietitian")
                                }
                        } else {
                            // Unknown role fallback
                            VStack(spacing: 20) {
                                Text("Unknown role: \(session.role)")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                
                                Text("Please contact support or try signing in again.")
                                    .font(.subheadline)
                                    .foregroundColor(.white.opacity(0.8))
                                    .multilineTextAlignment(.center)
                                
                                Button("Sign Out") {
                                    session.signOut()
                                }
                                .padding(.horizontal, 24)
                                .padding(.vertical, 12)
                                .background(Color.red)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(Color.black)
                            .onAppear {
                                print("[RootView] ❓ Unknown role: '\(session.role)'")
                            }
                        }
                    }
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                } else {
                    // Fallback state - should rarely be reached
                    VStack(spacing: 20) {
                        Text("Something went wrong")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Button("Try Again") {
                            session.signOut()
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                        
                        #if DEBUG
                        VStack(spacing: 4) {
                            Text("Debug State:")
                                .font(.caption2)
                                .foregroundColor(.gray)
                            Text("Ready for Nav: \(session.isReadyForNavigation)")
                                .font(.caption2)
                                .foregroundColor(.gray)
                            Text("Role: '\(session.role)'")
                                .font(.caption2)
                                .foregroundColor(.gray)
                        }
                        #endif
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black)
                    .onAppear {
                        print("[RootView] ⚠️ Fallback state reached")
                        print("[RootView] 🔍 isReadyForNavigation: \(session.isReadyForNavigation)")
                        print("[RootView] 🔍 role: '\(session.role)'")
                    }
                }
            }
            
            // Global Error Banner
            if let errorMessage = session.globalError {
                VStack {
                    HStack {
                        Text(errorMessage)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.leading)
                        
                        Spacer()
                        
                        Button(action: session.clearGlobalError) {
                            Image(systemName: "xmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                    .padding()
                    .background(Color.red)
                    .cornerRadius(8)
                    .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                    .padding(.horizontal, 16)
                    .padding(.top, UIApplication.shared.windows.first?.safeAreaInsets.top ?? 44)
                    
                    Spacer()
                }
                .transition(.move(edge: .top).combined(with: .opacity))
                .zIndex(999)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: session.isAuthenticated)
        .animation(.easeInOut(duration: 0.3), value: session.isLoadingUser)
        .animation(.easeInOut(duration: 0.3), value: session.role)
        .onAppear {
            print("[RootView] 🚀 RootView appeared")
            session.updateLastOnline()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            session.updateLastOnline()
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("navigateToChat"))) { notification in
            if let userInfo = notification.userInfo,
               let chatId = userInfo["chatId"] as? String {
                selectedChatId = chatId
                showingChat = true
            }
        }
        .sheet(isPresented: $showingChat) {
            if let chatId = selectedChatId {
                NavigationView {
                    if session.role == "client" {
                        ClientChatDetailView(
                            chatId: chatId,
                            dietitianName: "Dietitian", 
                            dietitianAvatarURL: nil,
                            session: session
                        )
                        .navigationBarHidden(true)
                    } else {
                        let mockClient = ParticipantInfo(id: "temp", fullName: "Client", photoURL: nil)
                        let mockDietitian = ParticipantInfo(id: session.currentUserId ?? "", fullName: "Dietitian", photoURL: nil)
                        let mockChat = ChatSummary(chatId: chatId, client: mockClient, dietitian: mockDietitian)
                        
                        DietitianChatDetailView(
                            viewModel: DietitianChatDetailViewModel(chat: mockChat, currentDietitianId: session.currentUserId ?? "")
                        )
                        .navigationBarHidden(true)
                    }
                }
            }
        }
    }
}

#if DEBUG
@available(iOS 16.0, *)
struct RootView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            RootView()
                .environmentObject(SessionStore.previewStore(isLoggedIn: true, role: "client"))
                .environmentObject(HealthKitManager(sessionStore: SessionStore.previewStore()))
                .preferredColorScheme(.dark)
                .previewDisplayName("Client User")
            
            RootView()
                .environmentObject(SessionStore.previewStore(isLoggedIn: true, role: "dietitian"))
                .environmentObject(HealthKitManager(sessionStore: SessionStore.previewStore()))
                .preferredColorScheme(.dark)
                .previewDisplayName("Dietitian User")
        }
    }
}
#endif
