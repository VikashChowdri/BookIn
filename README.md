# BookIn

BookIn is a peer-to-peer book exchange and rental app built with Flutter and Firebase. It was designed primarily for university campuses and student communities where readers need course textbooks for a semester without paying full retail price, or want to pass on books they have already finished.

Users can list books for either **direct purchase** or **short-term rental**, coordinate handovers via in-app real-time chat, and verify physical exchanges using a digital **QR Book Pass**.

---

## What it does

- **Dual Exchange Models**: List books for outright purchase, term rental (with custom start/end dates and rental pricing), or both.
- **QR Handover Verification ("Book Pass")**: When a rental or purchase request is approved, BookIn issues a digital pass (`TicketWidget` + `qr_flutter`). The other party scans the code with the in-app scanner (`mobile_scanner`) to verify pickup or return, automatically updating the booking and book availability in Firestore.
- **In-App Direct Chat**: Real-time buyer-seller messaging backed by Firestore snapshot streams, keeping transaction discussions inside the app without needing to share personal phone numbers right away.
- **Zero-Storage Image Pipeline**: To keep setup lightweight and eliminate the need for paid cloud storage buckets, book covers and profile pictures are cropped (`image_cropper`) and compressed client-side into compact Base64 strings stored directly inside Firestore documents.
- **Campus & Subject Tagging**: Filter books by academic department, subject, and general categories, or search across titles and authors with live suggestions and search history.
- **Ratings & Reviews**: Built-in star ratings and feedback system to build credibility for campus sellers and borrowers.
- **Multiple Themes**: Supports Light mode, Dark mode, and a custom olive & lavender **Student Theme** (`ThemeController`) designed for low-strain reading.

---

## Exchange Lifecycle

```text
[Buyer finds book]
       │
       ▼
[Submits Purchase or Rental Request]
       │
       ▼
[Seller receives in-app Notification]
       │
  ┌────┴────────────┐
  ▼                 ▼
[Accept]         [Decline] ──> Booking rejected
  │
  ▼
[Book Pass (QR Ticket) Generated]
  │
  ▼
[Parties meet up & scan QR code]
  │
  ├─ Purchase ──> Status: completed | Book marked sold
  │
  └─ Rental   ──> Status: active    | Book marked rented
                     │
                     ▼ (on return)
                  [Re-scan Book Pass] ──> Status: completed | Book marked available
```

---

## Tech Stack

- **Framework**: [Flutter](https://flutter.dev) (Dart SDK `^3.12.2`)
- **Backend & Auth**: Firebase Auth, Cloud Firestore
- **Key Dependencies**:
  - `mobile_scanner`: Camera-based QR code scanner for handover verification
  - `qr_flutter`: Dynamic QR ticket generation
  - `ticket_widget`: Digital pass UI styling
  - `image_picker` & `image_cropper`: Cover photo selection and cropping
  - `shared_preferences`: Local persistence for theme settings and search cache

---

## Project Structure

```text
lib/
├── core/
│   ├── animations/       # Reusable transitions (FadeSlideEntry, BounceTap, ShimmerEffect)
│   ├── constants/        # App colors, Firestore collection names, UI dimension tokens
│   ├── theme/            # Light, dark, and student themes + ThemeController
│   └── utils/            # App-wide globals and navigator keys
├── data/
│   ├── services/
│   │   ├── auth_service.dart       # Firebase Authentication operations & session state
│   │   ├── chat_service.dart       # Real-time message streams and active chat threads
│   │   ├── database_service.dart   # Firestore CRUD for books, bookings, reviews, and profiles
│   │   └── storage_service.dart    # Image picking, cropping, and Base64 compression
│   └── dummy_books.dart            # Sample seed data
├── models/
│   ├── book.dart                   # Book model (department, subject, category, prices, status)
│   ├── booking.dart                # Booking model (type: rental/purchase, status, dates)
│   ├── chat.dart & message.dart    # Conversation thread and message payloads
│   ├── notification_item.dart      # Real-time in-app notification model
│   ├── review.dart                 # Community feedback and star ratings
│   └── user_model.dart             # Profiles, public name, bio, blocked user list
├── routes/
│   └── app_routes.dart             # Named routes and custom page transitions
├── screens/
│   ├── auth/                       # Splash, onboarding, login, register, password reset
│   ├── booking/                    # My rentals, purchases, incoming requests, QR scanner & ticket
│   ├── cart/                       # Multi-item cart and checkout
│   ├── chat/                       # Conversations list and active chat view
│   ├── common/                     # Error and placeholder screens
│   ├── favorites/                  # Favorites and wishlist screens
│   ├── home/                       # Feed, featured carousel, category chips, add/edit book
│   ├── notifications/              # Incoming booking notifications and action triggers
│   ├── profile/                    # User profile, public seller profile, edit profile
│   ├── review/                     # Rating dialog and reviews list
│   └── search/                     # Live search with recent search history
└── widgets/                        # Shared UI components (AppImage, BookCard, etc.)
```

---

## Firestore Schema Overview

| Collection | Purpose | Key Fields |
|---|---|---|
| `users` | Profiles and account details | `username`, `email`, `publicName`, `profilePictureUrl`, `bio`, `blockedUsers` |
| `books` | Catalog listings | `title`, `author`, `department`, `subject`, `category`, `price`, `rentPrice`, `status`, `available` |
| `bookings` | Rental and purchase orders | `bookId`, `buyerId`, `sellerId`, `type` (`rental`/`purchase`), `status`, `startDate`, `endDate` |
| `chats` | Direct messaging threads | `participants`, `lastMessage`, `lastMessageTime`, with nested `messages` |
| `notifications` | Order updates and alerts | `userId`, `title`, `body`, `type`, `relatedId`, `isRead` |
| `reviews` | Seller and book feedback | `targetId`, `targetType` (`user`/`book`), `reviewerId`, `rating`, `comment` |

---

## Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (`>= 3.12.2`)
- Android Studio or Xcode (with Simulator / physical device)
- A Firebase project with **Authentication** (Email/Password) and **Cloud Firestore** enabled

### 1. Clone & install dependencies

```bash
git clone https://github.com/VikashChowdri/BookIn.git
cd BookIn
flutter pub get
```

### 2. Firebase Configuration

The repository is configured via `lib/firebase_options.dart` along with `android/app/google-services.json` and `ios/Runner/GoogleService-Info.plist`.

To bind the app to your own Firebase project:
1. Install the FlutterFire CLI:
   ```bash
   dart pub global activate flutterfire_cli
   ```
2. Run the configuration tool:
   ```bash
   flutterfire configure
   ```
3. Deploy required Firestore composite indexes (defined in `firestore.indexes.json`):
   ```bash
   firebase deploy --only firestore:indexes
   ```

### 3. Hardware & Permissions

- **Camera**: Required for scanning physical QR tickets during handovers.
  - On iOS, `NSCameraUsageDescription` is configured in `ios/Runner/Info.plist`.
  - When testing on physical devices, accept the camera permission prompt when opening the QR scanner.

### 4. Run the app

```bash
# Check connected devices
flutter devices

# Run debug build
flutter run
```

### 5. Running Tests

```bash
flutter test test/animations_test.dart
```

---

## Authors

Developed collaboratively by:
- **Vikash Chowdri**
- **Sanjay Pandian**
- **Elackiyasenthilprabu**
- **Likhitha B**
