import Foundation
import Combine // For ObservableObject

class TestLocalDietitianVM: ObservableObject {
    @Published var greeting: String = "Test VM is working!"

    init() {
        print("TestLocalDietitianVM initialized")
    }
}