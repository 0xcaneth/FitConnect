// Views/MessagesView.swift
import SwiftUI

struct MessagesView: View {
  @State private var messages: [ChatMessage] = [
    .init(text: "How was lunch today?", isFromDietitian: true),
    .init(text: "Great, had grilled chicken!", isFromDietitian: false)
  ]
  @State private var newMessage = ""

  var body: some View {
    VStack {
      ScrollView {
        ForEach(messages) { msg in
          ChatBubble(message: msg)
        }
      }
      .padding()

      HStack {
        TextField("Type a message…", text: $newMessage)
          .textFieldStyle(RoundedBorderTextFieldStyle())
        Button {
          guard !newMessage.isEmpty else { return }
          messages.append(.init(text: newMessage, isFromDietitian: false))
          newMessage = ""
        } label: {
          Image(systemName: "paperplane.fill")
        }
      }
      .padding()
    }
    .navigationTitle("Chat")
  }
}

struct ChatMessage: Identifiable {
  let id = UUID()
  let text: String
  let isFromDietitian: Bool
}

struct ChatBubble: View {
  let message: ChatMessage

  var body: some View {
    HStack {
      if !message.isFromDietitian { Spacer() }
      Text(message.text)
        .padding(12)
        .background(message.isFromDietitian ? Color.blue : Color.green)
        .foregroundColor(.white)
        .cornerRadius(12)
      if message.isFromDietitian { Spacer() }
    }
  }
}
