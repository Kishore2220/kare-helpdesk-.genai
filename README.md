# KARE Help Desk (Flutter + Firebase)

Student support app for Kalasalingam Academy of Research and Education (KARE).
Built with Flutter. Database: **Firebase** (Authentication + Cloud Firestore).

## Features

- Register and log in with a register number and password
- Student home with 12 campus information categories (academic, hostel, blocks, transport, library, food and canteen, exams, fees, medical, events, IT)
- Report an Issue (category, description, photo) with a KARE number such as KARE-1024
- My Complaints with live status (Pending, In Progress, Resolved)
- Admin dashboard: counts, view all complaints, change status, edit information pages
- Courses, subjects and fees for every course
- KARE Help Bot: an FAQ bot that answers from the information stored in the app (no AI service)
- Android app (APK) and Chrome web version

Planned: AI chatbot, campus map, notifications.

## Folders

| Path | What it holds |
|---|---|
| `lib/main.dart`, `lib/firebase_config.dart` | App start and Firebase settings |
| `lib/screens/` | All screens (login, home, complaints, admin, info pages, bot) |
| `lib/seed_data.dart` | Starter data: courses, fees, subjects and information pages |
| `firestore.rules` | Security rules for the database |
| `assets/images/` | KARE logo and campus photo |
| `build_android.ps1`, `run_chrome.ps1`, `change_icon.bat` | Helper scripts for Windows |

## Part A - Set up Firebase (once, about 10 minutes)

1. Go to https://console.firebase.google.com and click **Create a project**. Name it `kare-helpdesk`. Google Analytics can be turned off.
2. **Authentication**: Build > Authentication > Get started > Sign-in method > **Email/Password** > Enable > Save.
3. **Firestore**: Build > Firestore Database > Create database > choose location **asia-south1 (Mumbai)** > start in **production mode** > Create.
4. **Rules**: in Firestore open the **Rules** tab, delete everything, paste the full contents of `firestore.rules` from this project, and click **Publish**.
5. **Web app values** (for Chrome and the web link):
   Project settings (gear icon) > General > Your apps > click the **</>** (Web) icon > nickname `kare-web` > Register app.
   Copy these values from the code shown into `lib/firebase_config.dart` (the `_web` block):
   apiKey, appId, messagingSenderId, projectId (authDomain and storageBucket follow the project id).
6. **Android app values** (only needed for the Android app):
   Project settings > Your apps > Add app > Android icon > package name **com.kare.kare_helpdesk** > Register app > download `google-services.json` and open it in VS Code. Copy into the `_android` block:
   - apiKey = `api_key` > `current_key`
   - appId = `client` > `client_info` > `mobilesdk_app_id`
   - messagingSenderId = `project_info` > `project_number`
   - projectId = `project_info` > `project_id`
   You can skip the "next" steps Firebase shows about Gradle.

## Part B - Run in Chrome

    flutter create --org com.kare --project-name kare_helpdesk .
    flutter pub get
    flutter run -d chrome

(or:  powershell -ExecutionPolicy Bypass -File .\run_chrome.ps1 )

Register in the app and log in.

## Part C - Make yourself admin and load the data

1. Firebase console > Firestore Database > Data > collection **users** > click your document > change the field **role** from `student` to `admin` > Update.
2. In the app log out and log in again. An **Admin** button appears.
3. Open Admin > tap the **cloud-upload icon** (top right) > **Load**. This fills in courses, fees, subjects, hostels, canteens and the other pages.
4. Admins can edit information inside the app: open any page > pencil icon to edit, **Add** to add, Delete inside the edit box. On Fees the pencil edits tuition and other fees.

## Change the phone icon

Put a square logo at `assets/images/kare_logo.png`, then double-click `change_icon.bat` in the project folder. It sets the icon and the app name and builds the APK.

## Build the Android app

    powershell -ExecutionPolicy Bypass -File .\build_android.ps1

File: build\app\outputs\flutter-apk\app-release.apk (upload to Google Drive > Anyone with the link).

## Web link for your boss

    flutter build web

Drag the `build\web` folder to https://app.netlify.com/drop. Then in Firebase console > Authentication > Settings > **Authorized domains** > Add domain > your `xxxx.netlify.app`.

## Where things are stored

| Data | Firestore location |
|---|---|
| Profiles and roles | users |
| Complaints (KARE-1024...) and photos | complaints (photo is a small compressed picture inside the complaint) |
| Complaint number counter | counters/complaints |
| Courses, fees, subjects | programs |
| Hostels, canteens, blocks, exams etc. | info_items |
