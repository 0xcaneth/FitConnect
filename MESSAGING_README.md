# FitConnect Messaging System

A clean, robust one-to-one messaging system for FitConnect iOS app, enabling secure communication between clients and their assigned dietitians.

## Features

- **Text Messages**: Send and receive text messages in real-time
- **Photo Messages**: Share photos with automatic upload to Firebase Storage
- **Video Messages**: Share videos up to 1 minute in length
- **Snap Messages**: Send disappearing photos that can only be viewed once
- **Real-time Updates**: Live message streaming using Firestore listeners
- **Secure Communication**: Only matched client-dietitian pairs can message each other

## Architecture

### Models (`Models/MessageModels.swift`)
- `Message`: Core message model supporting all message types
- `MessageType`: Enum defining text, photo, video, and snap message types
- `ConversationPreview`: Model for conversation list previews with unread counts

### Services (`Services/MessagingService.swift`)
- `MessagingService`: Main service handling all messaging operations
- Firebase Firestore integration for message storage
- Firebase Storage integration for media uploads
- Real-time message streaming with AsyncThrowingStream
- Automatic permission validation based on client-dietitian relationships

### Views

#### Client Side
- `ClientChatListView`: List of conversations for clients
- `ClientChatDetailView`: Individual chat view for clients

#### Dietitian Side
- `DietitianMessagesListView`: List of client conversations for dietitians
- `DietitianChatDetailView`: Individual chat view with clients

#### Shared Components
- `MessageBubbleView`: Renders different message types with proper styling
- `ConversationRowView`: Row component for conversation lists
- `CameraCaptureView`: Camera integration for photo/snap capture
- `VideoRecorderView`: Video recording functionality

## Firestore Structure

### Messages Collection