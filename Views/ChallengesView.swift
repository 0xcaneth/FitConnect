import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct ChallengeCardView: View {
    let challenge: Challenge
    @EnvironmentObject var session: SessionStore

    @State private var joinedChallenge: UserChallenge? = nil
    @State private var isJoined: Bool = false

    private func checkIfUserJoined() {
        // challenge.id Optional olduğu için guard let ile devam et.
        guard !session.currentUserId.isEmpty, let challengeId = challenge.id else { return }
        let userId = session.currentUserId // Artık güvenle kullanabiliriz
        
        let db = Firestore.firestore()
        db.collection("userChallenges").document(userId).collection("challenges").document(challengeId).getDocument { documentSnapshot, error in
            if let document = documentSnapshot, document.exists {
                self.joinedChallenge = try? document.data(as: UserChallenge.self)
                self.isJoined = true
            } else {
                self.isJoined = false
                self.joinedChallenge = nil
            }
        }
    }
    
    private func joinChallenge() {
        // challenge.id Optional olduğu için guard let ile devam et.
        guard !session.currentUserId.isEmpty, let challengeId = challenge.id else {
            print("Error: User not logged in or challenge ID missing.")
            return
        }
        let userId = session.currentUserId // Artık güvenle kullanabiliriz

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
                    self.checkIfUserJoined()
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

            if isJoined, let currentProgress = joinedChallenge?.progressValue {
                 ProgressView(value: currentProgress, total: challenge.targetValue)
                     .progressViewStyle(LinearProgressViewStyle(tint: Color(hex: "#6E56E9")))
                     .padding(.vertical, 4)
                Text("Progress: \(Int(currentProgress)) / \(Int(challenge.targetValue)) \(challenge.unit.displayName)")
                     .font(.system(size: 10, design: .rounded))
                     .foregroundColor(Color(hex: "#8A8F9B"))
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
            checkIfUserJoined()
        }
    }
}

struct ChallengesView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var session: SessionStore
    @State private var activeChallenges: [Challenge] = []
    @State private var isLoading: Bool = true

    private func fetchChallengesFromFirestore() {
        isLoading = true
        let db = Firestore.firestore()
        db.collection("challenges")
          .order(by: "createdAt", descending: true)
          .getDocuments { snapshot, error in
            isLoading = false
            if let error = error {
                print("Error fetching challenges: \(error.localizedDescription)")
                return
            }
            guard let documents = snapshot?.documents else {
                print("No challenge documents found")
                self.activeChallenges = []
                return
            }
            
            self.activeChallenges = documents.compactMap { document -> Challenge? in
                do {
                    return try document.data(as: Challenge.self)
                } catch {
                    print("Error decoding challenge: \(error)")
                    return nil
                }
            }
        }
    }

    var body: some View {
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
        .onAppear {
            fetchChallengesFromFirestore()
        }
    }
}

#if DEBUG
struct ChallengesView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ChallengesView()
                .environmentObject(SessionStore(forPreview: true))
        }
        .preferredColorScheme(.dark)
    }
}
#endif
