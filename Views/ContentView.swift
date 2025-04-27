import SwiftUI

struct ContentView: View {
  @EnvironmentObject var session: SessionStore

  var body: some View {
    Group {
      if session.user != nil {
        FeaturesView()      // ya da ana dashboard’un
      } else {
        SplashView()        // ilk splash → sonra login akışı
      }
    }
  }
}
