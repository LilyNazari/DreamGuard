# DreamGuard Flutter Modules

This repository contains Flutter modules for the **DreamGuard** app, including **Educational Resources** and **User Profile** management. These components are designed to fetch, display, and manage content and user data seamlessly with a responsive and localized UI.

---

## 1. Educational Resources Module

**File:** `educational_resources.dart`  

### Overview
The `EducationalResources` widget provides a curated list of educational articles fetched from a Medium RSS feed. Each article is displayed as a card with an image, title, description, and read time.

### Features
- Fetches articles dynamically from Medium using RSS-to-JSON API.
- Parses article title, description (stripping HTML tags), publication date, and image.
- Displays articles in scrollable cards.
- Tapping a card opens the article in the device’s browser.
- Fallback and error handling if a URL cannot be opened.
- Supports multiple languages via `AppLocalizations`.

### Dependencies
- `http` — for network requests.
- `url_launcher` — for opening article URLs.
- `flutter_gen` — for localization.
- `flutter/material.dart` — standard UI components.

---

## 2. User Profile Module

**File:** `profile_page.dart`  

### Overview
The `ProfilePage` widget allows users to view and edit their personal information and profile picture. It also supports tab-based navigation for managing passwords, viewing dream history, and checking dream statistics.

### Features
- Display user profile details: name, surname, email, username, phone, gender, region, date of birth, and education.
- Edit and save profile details with form validation.
- Upload and update profile picture.
- Tabs for:
  - **My Details** — edit personal information.
  - **Password** — placeholder for password management.
  - **Dream History** — placeholder for historical dream logs.
  - **Dream Statistics** — placeholder for dream analytics.
- Handles loading states and error messages gracefully.
- Localized text using `AppLocalizations`.

### Dependencies
- `provider` — for state management.
- `flutter_gen` — for localization.
- `flutter/material.dart` — UI components.

