# Codemagic → TestFlight (Jestora Pattern Studio)

## Project

| Field | Value |
|-------|--------|
| Bundle ID | `com.jestorapattern.studio` |
| Team ID | `78C629N23T` |
| Scheme | `newFirstApp` |
| Project | `newFirstApp.xcodeproj` |
| Workflow | `ios-testflight` in `codemagic.yaml` |

## Firebase / cue config (already in repo)

| Field | Value |
|-------|--------|
| Firebase function | `JestoraPatternStudio` |
| Firebase region | `europe-central2` |
| App ID (gate) | `id6797531429` |
| GoogleService-Info | `newFirstApp/GoogleService-Info.plist` |
| Push entitlements | Debug → `development`, Release → `production` |
| SPM | FirebaseCore · FirebaseFunctions · FirebaseMessaging |

In **Apple Developer → Identifiers → com.jestorapattern.studio** enable **Push Notifications**.  
In **Firebase Console** upload the APNs Auth Key (`.p8`) for this app.

## One-time setup in Codemagic UI

### 1. App Store Connect API key (integration name must match yaml)

1. Codemagic → **Teams** → **Integrations** (or Team settings → Apple Developer Portal)
2. Add **App Store Connect API** key
3. **Name:** exactly `JestoraASC` (same as in `codemagic.yaml`)
4. Issuer ID: `f3e40d15-1cdc-4ddc-a9ca-b61da62dc4e7`
5. Key ID: `94BF5678PP`
6. Upload `AuthKey_94BF5678PP.p8` (from Downloads — never commit this file)

### 2. Code signing

Codemagic will fetch/create App Store distribution cert + profile for  
`com.jestorapattern.studio` via the API key (`ios_signing` in yaml).

### 3. Detect workflow

After this repo has `codemagic.yaml` on `main`:

1. Open the app in Codemagic
2. Click **Check for configuration file**
3. Select workflow **iOS TestFlight** → Start build

## After first green build

1. [App Store Connect](https://appstoreconnect.apple.com) → JestoraPatternStudio → **TestFlight**
2. Wait for processing
3. Answer Export Compliance
4. Add Internal Tester → install from TestFlight

## App Store Submit (manual when ready)

Listing in ASC (screenshots, description, Privacy URL, category Graphics & Design).  
`submit_to_app_store` stays `false` in yaml — submit from ASC when listing is complete.
