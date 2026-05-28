# Firebase Phone Auth (OTP) Setup

This guide helps you fix OTP timeout and verification issues when using Firebase Phone Authentication in development.

---

## 1. SHA-1 and SHA-256 fingerprints (most common fix)

Firebase uses your app’s signing certificates to validate requests. If the **debug** keystore fingerprints are missing in Firebase, OTP will fail (e.g. `invalid-app-credential` or no SMS).

### Get debug keystore fingerprints

**Windows (PowerShell):**

```powershell
cd $env:USERPROFILE\.android
keytool -list -v -keystore debug.keystore -alias androiddebugkey -storepass android -keypass android
```

**macOS/Linux:**

```bash
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
```

Copy the **SHA-1** and **SHA-256** lines from the output.

### Add them in Firebase Console

1. Open [Firebase Console](https://console.firebase.google.com/) → your project.
2. **Project settings** (gear) → **Your apps**.
3. Select your Android app (package `com.sribeesonline.sribees_mobile`).
4. Click **Add fingerprint** and paste **SHA-1**, then add **SHA-256** the same way.
5. Download the updated **google-services.json** and replace `android/app/google-services.json`.
6. Rebuild the app.

---

## 2. SafetyNet / Play Integrity (Device Check)

Phone Auth can use device attestation. Ensure it’s enabled:

1. Firebase Console → **Authentication** → **Settings** (or **Sign-in method** → **Phone**).
2. Under **Authorized domains** / **Phone** settings, confirm **App verification** (SafetyNet / Play Integrity) is enabled if your project uses it.
3. For local testing, you can rely on **Test phone numbers** (see below) to avoid attestation issues.

---

## 3. Android configuration

- **Manifest:** `android/app/src/main/AndroidManifest.xml` already includes:
  - `android.permission.INTERNET`
  - `android.permission.ACCESS_NETWORK_STATE`
- **Google Services plugin:** Applied in `android/settings.gradle.kts` and `android/app/build.gradle.kts`.  
  Ensure **google-services.json** is in **android/app/**.

---

## 4. Debugging: exact error codes

When OTP fails, the app logs the exact Firebase error to the console (only in debug builds):

- **Send code (verifyPhoneNumber):**  
  `[Firebase Phone Auth] verificationFailed: code=..., message=...`  
  or  
  `[Firebase Phone Auth] FirebaseAuthException: code=..., message=...`
- **Verify OTP (signInWithCredential):**  
  `[Firebase Phone Auth] signInWithCredential failed: code=..., message=...`

Common codes:

| Code | Meaning | What to do |
|------|--------|------------|
| `invalid-app-credential` | Wrong/missing SHA or wrong package | Add correct SHA-1/SHA-256 and package in Firebase; update google-services.json |
| `too-many-requests` | Rate limit (SMS) | Use test phone numbers or wait; enable test numbers in Firebase |
| `missing-client-identifier` | App not recognized (e.g. no google-services.json or wrong package) | Add google-services.json; ensure package name matches Firebase Android app |
| `invalid-verification-code` | Wrong or expired OTP | Re-send code; use test OTP if using test numbers |

Run the app from IDE or `flutter run` and watch the console/Logcat for these lines.

---

## 5. Test phone numbers (no real SMS)

For quick local testing without the SMS gateway or device check:

1. Firebase Console → **Authentication** → **Sign-in method** → **Phone** → enable.
2. Open **Phone numbers for testing** (or **Settings** → **Phone**).
3. Add a test number, e.g. **+94 712 345 678**, and set a fixed code, e.g. **123456**.
4. In the app, enter that phone number and use **123456** as the OTP.

No real SMS is sent; Firebase accepts the fixed code. This helps with timeout and verification issues during development.

---

## Checklist

- [ ] SHA-1 and SHA-256 from debug keystore added in Firebase Android app.
- [ ] **google-services.json** in **android/app/** and package name matches.
- [ ] Device Check (SafetyNet/Play Integrity) enabled in Firebase if required.
- [ ] For testing: test phone number and fixed OTP configured in Firebase.
- [ ] Console logs checked for `[Firebase Phone Auth]` when OTP fails.
