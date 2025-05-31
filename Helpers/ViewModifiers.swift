import SwiftUI

// MARK: - Background Safe Area Modifier
struct BackgroundSafeAreaModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 14.0, *) {
            content.ignoresSafeArea()
        } else {
            content.edgesIgnoringSafeArea(.all)
        }
    }
}

// MARK: - Navigation Title Compatibility Modifier
struct NavigationTitleCompatModifier: ViewModifier {
    let title: String
    
    func body(content: Content) -> some View {
        if #available(iOS 14.0, *) {
            content.navigationTitle(title)
        } else {
            content.navigationBarTitle(Text(title), displayMode: .inline)
        }
    }
}

// MARK: - View Extensions
extension View {
    func backgroundSafeArea() -> some View {
        modifier(BackgroundSafeAreaModifier())
    }
    
    func navigationTitleCompat(_ title: String) -> some View {
        modifier(NavigationTitleCompatModifier(title: title))
    }
}
