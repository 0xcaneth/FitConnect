import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct ChallengeCardView: View {
    let challenge: Challenge
    @State private var joinedChallenge: UserChallenge? = nil
    @State private var isJoined: Bool = false
    @State private var listenerRegistration: ListenerRegistration?
    @EnvironmentObject var session: SessionStore

    private func setupChallengeListener() {
        removeChallengeListener()

        guard let userId = session.currentUserId, !userId.isEmpty, let challengeId = challenge.id else {
            print("[ChallengeCardView] User not logged in, userId is empty, or challenge ID missing for listener.")
            self.isJoined = false
            self.joinedChallenge = nil
            return
        }

        let db = Firestore.firestore()
        let challengeDocRef = db.collection("userChallenges").document(userId).collection("challenges").document(challengeId)

        self.listenerRegistration = challengeDocRef.addSnapshotListener { documentSnapshot, error in
            if let error = error {
                print("[ChallengeCardView] Error listening to user challenge document \(challengeId): \(error.localizedDescription)")
                return
            }

            if let document = documentSnapshot, document.exists {
                print("[ChallengeCardView] Raw Firestore data update for user challenge \(challengeId): \(String(describing: document.data()))")
                do {
                    self.joinedChallenge = try document.data(as: UserChallenge.self)
                    self.isJoined = true
                    print("[ChallengeCardView] Successfully decoded UserChallenge update: \(String(describing: self.joinedChallenge))")
                } catch let decodeError {
                    print("[ChallengeCardView] Error decoding UserChallenge update for \(challengeId): \(decodeError)")
                    self.isJoined = true
                    self.joinedChallenge = nil
                }
            } else {
                print("[ChallengeCardView] User challenge document \(challengeId) no longer exists or user hasn't joined.")
                self.isJoined = false
                self.joinedChallenge = nil
            }
        }
    }

    private func removeChallengeListener() {
        self.listenerRegistration?.remove()
        self.listenerRegistration = nil
        print("[ChallengeCardView] Listener removed.")
    }

    private func joinChallenge() {
        guard let userId = session.currentUserId, !userId.isEmpty, let challengeId = challenge.id else {
            print("Error: User not logged in, userId is empty, or challenge ID missing.")
            return
        }

        let db = Firestore.firestore()
        let userChallengeRef = db.collection("userChallenges").document(userId).collection("challenges").document(challengeId)

        let newUserChallenge = UserChallenge(
            challengeId: challengeId,
            userId: userId,
            progressValue: 0.0,
            isCompleted: false,
            completedDate: nil,
            joinedDate: Timestamp(date: Date()),
            lastUpdated: Timestamp(date: Date()),
            challengeTitle: challenge.title,
            challengeDescription: challenge.description,
            challengeTargetValue: challenge.targetValue,
            challengeUnit: challenge.unit.rawValue
        )

        do {
            try userChallengeRef.setData(from: newUserChallenge) { error in
                if let error = error {
                    print("Error joining challenge \(challenge.title): \(error.localizedDescription)")
                } else {
                    print("Successfully joined challenge: \(challenge.title)")
                    self.isJoined = true
                    self.setupChallengeListener()
                }
            }
        } catch let error {
            print("Error encoding UserChallenge or setting data: \(error.localizedDescription)")
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(challenge.title)
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundColor(.white)

            Text(challenge.description)
                .font(.system(size: 14, design: .rounded))
                .foregroundColor(Color(hex: "#B0B3BA"))
                .lineLimit(2)

            HStack {
                Text("Goal: \(Int(challenge.targetValue)) \(challenge.unit.displayName)")
                    .font(.system(size: 12, design: .rounded))
                    .foregroundColor(Color(hex: "#8A8F9B"))
                Spacer()
                Text("\(challenge.durationDays) days")
                    .font(.system(size: 12, design: .rounded))
                    .foregroundColor(Color(hex: "#8A8F9B"))
            }

            if isJoined, let currentProgress = joinedChallenge?.progressValue, let target = joinedChallenge?.challengeTargetValue, target > 0 {
                 let clampedProgress = min(currentProgress, target)
                 ProgressView(value: clampedProgress, total: target)
                     .progressViewStyle(LinearProgressViewStyle(tint: Color(hex: "#6E56E9")))
                     .padding(.vertical, 4)
                Text("Progress: \(Int(currentProgress)) / \(Int(target)) \(joinedChallenge?.challengeUnit ?? challenge.unit.displayName)")
                     .font(.system(size: 10, design: .rounded))
                     .foregroundColor(Color(hex: "#8A8F9B"))
            } else if isJoined {
                Text("Progress information unavailable or target is zero.")
                    .font(.system(size: 10, design: .rounded))
                    .foregroundColor(Color.orange)
            }

            Button(action: {
                if !isJoined {
                    joinChallenge()
                } else {
                    print("Already joined or action for joined challenge: \(challenge.title)")
                }
            }) {
                Text(isJoined ? "Joined (View Progress)" : "Join Challenge")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity)
                    .background(isJoined ? Color.gray.opacity(0.7) : Color(hex: "#6E56E9"))
                    .cornerRadius(8)
            }
            .disabled(isJoined && joinedChallenge == nil)
            .padding(.top, 8)
        }
        .padding()
        .background(Color(hex: "#1C1E25"))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
        )
        .onAppear {
            setupChallengeListener()
        }
        .onDisappear {
            removeChallengeListener()
        }
    }
}

@available(iOS 16.0, *)
struct ChallengesView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var session: SessionStore
    @State private var activeChallenges: [Challenge] = []
    @State private var isLoading: Bool = true

    private func fetchChallengesFromFirestore() {
        isLoading = true
        let db = Firestore.firestore()
        
        db.collection("challenges")
            .whereField("isActive", isEqualTo: true)
            .order(by: "title")
            .getDocuments { snapshot, error in
                DispatchQueue.main.async {
                    self.isLoading = false
                    
                    if let error = error {
                        print("[ChallengesView] Error fetching challenges: \(error.localizedDescription)")
                        if self.activeChallenges.isEmpty {
                            print("[ChallengesView] No cached challenges available")
                        }
                        return
                    }
                    
                    guard let documents = snapshot?.documents else {
                        print("[ChallengesView] No challenges found in Firestore")
                        self.activeChallenges = []
                        return
                    }
                    
                    self.activeChallenges = documents.compactMap { document in
                        do {
                            var challenge = try document.data(as: Challenge.self)
                            challenge.id = document.documentID
                            return challenge
                        } catch {
                            print("[ChallengesView] Error decoding challenge \(document.documentID): \(error)")
                            return nil
                        }
                    }
                    
                    print("[ChallengesView] Successfully loaded \(self.activeChallenges.count) challenges from Firebase")
                }
            }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "#0D0F14").ignoresSafeArea()

                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.5)
                } else if activeChallenges.isEmpty {
                    VStack {
                        Text("No Active Challenges")
                            .font(.system(size: 20, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                        Text("Check back later for new challenges!")
                            .font(.system(size: 16, design: .rounded))
                            .foregroundColor(Color(hex: "#B0B3BA"))
                    }
                } else {
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 16) {
                            ForEach(activeChallenges) { challenge in
                                ChallengeCardView(challenge: challenge)
                                    .environmentObject(session)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Challenges")
            .navigationBarTitleDisplayMode(.large)
        }
        .onAppear {
            fetchChallengesFromFirestore()
        }
    }
}

#if DEBUG
@available(iOS 16.0, *)
struct ChallengesView_Previews: PreviewProvider {
    static var previews: some View {
        ChallengesView()
            .environmentObject(SessionStore.previewStore())
            .preferredColorScheme(.dark)
    }
}
#endif