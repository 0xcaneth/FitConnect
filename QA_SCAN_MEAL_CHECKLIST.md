# FitConnect Scan Meal Feature - QA Checklist

## ✅ Pre-Testing Setup
- [ ] Build app successfully without errors
- [ ] Test on iPhone with iOS 17+ (real device preferred)
- [ ] Ensure good lighting conditions for food scanning
- [ ] Have variety of food items ready for testing

## 🔧 Core Functionality Testing

### 1. Firebase Configuration
- [ ] ✅ Firestore settings moved to app startup (before any DB calls)
- [ ] ✅ No duplicate Firestore configuration in MealService
- [ ] ✅ App doesn't crash on startup due to Firebase config issues
- [ ] ✅ Offline persistence enabled and working

### 2. Camera Launch & Permissions
- [ ] ✅ Tapping "Scan Meal" presents real camera UI (not mock)
- [ ] ✅ Camera permission request shows on first use
- [ ] ✅ Permission denied shows settings alert with "Open Settings" button
- [ ] ✅ Camera preview shows live feed when authorized
- [ ] ✅ Flash toggle works (bolt icon changes state)
- [ ] ✅ Back button properly dismisses camera view

### 3. Core ML Integration
- [ ] ✅ `food.mlmodel` loads successfully (check console for loading messages)
- [ ] ✅ Image preprocessing (224x224 resize, normalize) working
- [ ] ✅ Classification runs on background thread
- [ ] ✅ Mock predictions work when model not available
- [ ] ✅ Model gracefully handles missing/corrupt .mlmodel files

### 4. Camera Capture Flow
- [ ] Shutter button responsive with haptic feedback
- [ ] Image capture creates proper UIImage
- [ ] Flash works when enabled during capture
- [ ] Capture disabled during analysis (button shows progress)
- [ ] Multiple rapid taps don't cause crashes

## 🎨 UI/UX Polish & Theme

### 5. Dark Mode & Design System
- [ ] ✅ Full dark mode: backgrounds `#0D0F14`
- [ ] ✅ Accent gradient `#FF6D00→#FF4081` on primary actions
- [ ] ✅ Large rounded corners (12pt) on overlays
- [ ] ✅ Proper safe area insets and notch handling
- [ ] ✅ Consistent FitConnectColors throughout

### 6. Animations & Transitions
- [ ] ✅ Camera view slides up smoothly
- [ ] ✅ Result card fades & scales in elegantly
- [ ] ✅ Confidence ring animates stroke progressively
- [ ] ✅ Low confidence cards pulse/highlight appropriately
- [ ] ✅ Spring animations feel natural (0.6 response, 0.8 damping)

### 7. Result Card Behaviors
- [ ] ✅ Confidence ≥ 80%: Green checkmark, full nutrition, save options
- [ ] ✅ Confidence < 80%: Orange warning, "Not sure? Try again" with rescan button
- [ ] ✅ Circular confidence ring animates from 0 to actual percentage
- [ ] ✅ Low confidence shows orange overlay and warning triangle
- [ ] ✅ Result cards respond to tap with detail sheet

## 🔄 Error Handling & Offline Support

### 8. Network & ML Errors
- [ ] Classification errors show 2-second banner then auto-dismiss
- [ ] Model loading failures fall back to mock predictions
- [ ] Network failures during save show "Will save when online" banner
- [ ] Timeout errors are handled gracefully
- [ ] Multiple retry attempts don't cause memory leaks

### 9. Offline-First Features
- [ ] ✅ Firestore offline persistence working
- [ ] Local queue for failed saves (sync when online)
- [ ] Classification works without internet (local Core ML)
- [ ] Images cached locally until successful upload
- [ ] Offline indicator in UI when appropriate

## 🥗 Food Recognition Testing

### 10. Accuracy & Confidence Testing
Test with these specific foods and verify confidence scores:
- [ ] Apple (expect >85% confidence)
- [ ] Pizza slice (expect >80% confidence)  
- [ ] Mixed salad (expect 60-80% confidence)
- [ ] Unusual/foreign food (expect <60% confidence)
- [ ] Non-food items (expect <30% confidence or "No food detected")

### 11. Edge Cases
- [ ] Very dark lighting conditions
- [ ] Multiple food items in frame
- [ ] Partially obscured food
- [ ] Blurry or motion-blurred images
- [ ] Empty plate or background only

## 💾 Data Persistence & Firebase

### 12. Meal Saving Flow
- [ ] ✅ Images upload to Firebase Storage path: `meal_photos/{userId}/{mealId}/{photoId}`
- [ ] ✅ Meal data saves to Firestore: `/users/{uid}/meals/`
- [ ] Successful save shows green toast "Meal saved to your diary!"
- [ ] Failed saves queue locally for retry
- [ ] Meal includes all nutrition data and confidence score

### 13. Data Validation
- [ ] User authentication check before saving
- [ ] Proper meal type selection (Breakfast/Lunch/Dinner/Snack)
- [ ] Nutrition values are realistic (not negative/extreme)
- [ ] Timestamps are accurate
- [ ] Image URLs are valid and accessible

## 🚀 Performance & Memory

### 14. Performance Testing
- [ ] App remains responsive during analysis (UI doesn't freeze)
- [ ] Memory usage stable after multiple scans
- [ ] Camera session properly cleaned up on dismiss
- [ ] No memory leaks from Core ML model loading
- [ ] Battery drain reasonable during camera use

### 15. Rapid-Fire Testing
- [ ] Multiple quick "Scan Again" attempts don't crash
- [ ] Rapid back/forward navigation works smoothly
- [ ] Concurrent image processing handled properly
- [ ] Camera doesn't get stuck in analyzing state

## 📱 Device-Specific Testing

### 16. Different iPhone Models
- [ ] iPhone 12/13/14 (various screen sizes)
- [ ] iPhone Pro models (different camera systems)
- [ ] iPhone SE (smaller screen, different safe areas)
- [ ] iPad compatibility (if supported)

### 17. iOS Versions
- [ ] iOS 16.6 minimum (app requirement)
- [ ] iOS 17+ (test modern features)
- [ ] iOS 18 beta (if available)

## 🔍 Accessibility & Edge Cases

### 18. Accessibility
- [ ] VoiceOver reads camera controls properly
- [ ] Dynamic Type scaling works on text
- [ ] High contrast mode compatible
- [ ] Haptic feedback works for VoiceOver users

### 19. Edge Cases
- [ ] No network connection during scan
- [ ] App backgrounded during analysis
- [ ] Camera permission revoked mid-session
- [ ] Device storage full (image upload fails)
- [ ] Firebase quota exceeded

## ✅ Final Validation

### 20. End-to-End Success Criteria
- [ ] ✅ NO FREEZES: App never hangs or becomes unresponsive
- [ ] ✅ NO MOCKS: Real camera, real Core ML, real Firebase
- [ ] ✅ PRODUCTION-GRADE: Robust error handling, offline support
- [ ] ✅ CONFIDENCE THRESHOLD: 80%+ shows nutrition, <80% suggests retry
- [ ] ✅ AUTO-DISMISS: Low confidence/errors auto-dismiss after 2 seconds
- [ ] ✅ SAVE SUCCESS: Meals properly saved to `/users/{uid}/meals/`

## 📊 Sample Test Results Log

| Food Item | Confidence | Calories | Action Taken | Notes |
|-----------|------------|----------|--------------|-------|
| Apple     | 87%        | 95       | ✅ Saved    | Perfect detection |
| Pizza     | 81%        | 285      | ✅ Saved    | Good confidence |
| Salad     | 65%        | 150      | ⚠️ Retry    | Low confidence warning |
| Burger    | 79%        | 540      | ⚠️ Retry    | Just below threshold |

## 🎯 Success Metrics
- **Camera Launch**: <2 seconds from tap to preview
- **Classification**: <3 seconds for Core ML prediction
- **Save Complete**: <5 seconds including image upload
- **Error Recovery**: All failures show friendly message and auto-dismiss
- **Memory Usage**: <50MB additional during scanning session

---

**Test Environment**: 
- Device: ________________
- iOS Version: ___________
- Build: _________________
- Date: __________________
- Tester: ________________

**Overall Assessment**: ✅ PASS / ❌ FAIL / ⚠️ NEEDS WORK

**Critical Issues Found**: 
_None_ / _List any blocking issues_

**Recommendations**:
_Any improvements or optimizations needed_