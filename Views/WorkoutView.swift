import SwiftUI

@available(iOS 16.0, *)
struct WorkoutView: View {
    var body: some View {
        WorkoutDashboardView()
    }
}

#if DEBUG
@available(iOS 16.0, *)
struct WorkoutView_Previews: PreviewProvider {
    static var previews: some View {
        let session = SessionStore.previewStore(isLoggedIn: true)
        session.currentUser?.firstName = "Test User"
        
        return NavigationView {
            WorkoutView()
                .environmentObject(session)
        }
        .preferredColorScheme(.dark)
    }
}
#endif