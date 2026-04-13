# DailyWrite - App Store Preparation Checklist

## ✅ Completed Today

### 1. App Tracking Transparency ✅
- Added `NSUserTrackingUsageDescription` to Info.plist
- Created `TrackingTransparencyService.swift`
- Requests permission on app launch (delayed by 2 seconds for better UX)
- Supports iOS 14+ tracking authorization

### 2. Info.plist Updated ✅
Added:
- App Tracking Transparency description
- Camera/Photo Library usage descriptions (for future features)
- iCloud container name (`iCloud.com.jiyun.dailywrite`)
- Required device capabilities (armv7, arm64)
- Supported orientations (Portrait only)
- App Transport Security settings

### 3. Privacy Policy ✅
- Created `PRIVACY_POLICY.md`
- Covers data collection, usage, storage, sharing
- Includes user rights and contact information
- **Action Required**: Update email address in Privacy Policy

### 4. Account Deletion ✅
- Implemented in Settings → Account → Delete Account
- Deletes user data, essays, and Firebase Auth account
- Shows confirmation alert before deletion
- Fully localized (English/Korean)

## 📋 Remaining Tasks

### App Store Submission
| Task | Status | Notes |
|------|--------|-------|
| Screenshots (6.7", 6.5", 5.5") | ⬜ | Need iPhone 14 Pro Max, iPhone 8 Plus |
| App Icon (all sizes) | ✅ | Already in Assets.xcassets |
| Privacy Policy URL | ⬜ | Host on website/github |
| Support URL | ⬜ | Could be email or website |
| App Preview (optional) | ⬜ | 15-30 second video |

### Localization Verification
- [ ] Writing Editor headings (제목/부제목)
- [ ] Profile Edit screen
- [ ] Settings menus
- [ ] Writing Archive (글 보관함)

### Before Submitting
1. **Test on real device** (not just simulator)
2. **Verify iCloud backup** works
3. **Test account deletion** end-to-end
4. **Test all auth methods** (Apple, Google, Email)
5. **Check dark mode** appearance
6. **Verify VoiceOver** accessibility
7. **Run on iOS 17** and iOS 18

## 🔗 Privacy Policy Hosting

Options for hosting your Privacy Policy:
1. **GitHub Pages** (free): `https://yourusername.github.io/dailywrite/privacy`
2. **Firebase Hosting** (free tier available)
3. **Personal website** if you have one
4. **GitHub repository** raw file link

## 📧 Contact Information

Update these before App Store submission:
- Privacy Policy email: Replace `[your-email@example.com]`
- Support email/URL
- App Store developer account info

## 🎯 Next Steps

1. Take screenshots on real devices or use Simulator
2. Host Privacy Policy online
3. Add Privacy Policy URL to Firebase Console (App Check)
4. Fill out App Store Connect information
5. Submit for review!

---

**Estimated Time to Submit**: 1-2 hours (after screenshots)
