# 🧠 FitConnect - AI-Powered Diet & Fitness Companion 📱🥗💪

Welcome to **FitConnect**, your all-in-one AI-powered diet & fitness coaching app!  
This mobile app connects **dietitians** and **clients** through smart health tracking, nutrition analysis, and seamless communication.

---

## 🚀 Features Overview

### 👨‍🍳 For Clients:
- 📸 **Food Vision AI** – Snap a photo of your meal and get instant nutrition insights with our custom-trained CoreML model.
- 🍱 **Log Meals & Scan Nutrition** – Easily record or detect meals and track calories & macros.
- 🏃 **Apple Health Integration** – Sync real-time data: steps, calories, water intake, weight, BMI, and more.
- 🎬 **Workout Clip Sharing** – Record and share temporary workout clips with your dietitian.
- 💬 **Chat with Your Dietitian** – Exchange messages, photos, videos, and even one-time "snap" messages.
- 📊 **Personal Progress Dashboard** – Visual analytics of your nutrition and activity data.

### 🧑‍⚕️ For Dietitians:
- 🗂 **Client Management System** – View client stats, track progress, and access meal logs & analytics.
- 📆 **Appointment Scheduler** – Accept or reject booking requests from clients in real-time.
- 📲 **Messaging System** – Communicate securely with clients, organized by latest activity.
- 🧾 **QR Match System** – Connect with clients quickly via QR code pairing.
- 📉 **Client Data Visualization** – Real-time charts for steps, calories burned, water intake, and more.

---

## 📸 Tech Stack

| Layer | Tools |
|------|-------|
| **Frontend** | `SwiftUI`, `Combine`, `CoreML`, `HealthKit` |
| **Backend** | `Firebase Authentication`, `Firestore`, `Firebase Storage`, `Cloud Functions` |
| **AI/ML** | `Classifier CoreML Model` trained on food images |
| **Others** | `Firebase App Check`, `Push Notifications`, `QR Code Generator` |

---

## ⚙️ Architecture

```
Client <-> Firestore <-> Dietitian
       ↘︎        ↑        ↙︎
    Firebase Auth | Cloud Functions
       ↘︎        ↓        ↙︎
     Storage ⬌ HealthKit ⬌ CoreML
```

---

## 🧪 Core Functionalities

- ✅ Real-time sync with Firestore for all messages, meals, and analytics.
- ✅ 24-hour auto-expiry for media content using Cloud Functions.
- ✅ Role-based access for dietitians vs clients.
- ✅ Advanced UI with dynamic analytics panels, onboarding screens, and interactive views.

---

## 🔐 Privacy & Security

- 🔒 All user data is securely stored in Firebase.
- 🕵️‍♂️ App Check is enabled to ensure only verified apps can access the backend.
- 📜 GDPR-compliant structure for health and nutrition data.

---

## 📱 Screenshots

Will be added soon!

---

## 🧭 How to Run the App

1. Clone the repo  
```bash
git clone https://github.com/0xcaneth/FitConnect.git
```

2. Open with Xcode (Version 15+ recommended)

3. Set up your `GoogleService-Info.plist`

4. Run on iOS device or simulator 🚀

---

## 📅 Roadmap

- [x] CoreML food detection system  
- [x] Apple Health integration  
- [x] Realtime chat and snap system  
- [x] Dietitian-client matching with QR  
- [ ] Multi-language support 🌍  
- [ ] AI meal plan generator 🤖  
- [ ] Notification scheduling 🔔  

---

## 📬 Contact

Got questions or feedback?  
Reach out at: me@mehmetcanirmak.com / canacar193@gmail.com

---

## 🌟 Give Us a Star!

If you like this project, consider giving it a ⭐️ on GitHub and sharing it with others!

---

> "Empowering health through technology." – *The FitConnect Team*
