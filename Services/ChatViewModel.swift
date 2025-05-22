// ViewModels/ChatViewModel.swift

import SwiftUI

@MainActor
class ChatViewModel: ObservableObject {
  @Published var messages: [ChatMessage] = []
  @Published var draft = ""

  private var listener: ListenerRegistration?
  private let service = ChatService()

  func start() {
    guard listener == nil else { return }
    listener = service.listen { [weak self] msgs in
      self?.messages = msgs
    }
  }

  func stop() {
    listener?.remove()
    listener = nil
  }

  func send() {
    guard let uid = Auth.auth().currentUser?.uid,
          !draft.trimmingCharacters(in: .whitespaces).isEmpty else { return }
    service.send(text: draft, from: uid)
    draft = ""
  }
}
