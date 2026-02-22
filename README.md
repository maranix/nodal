# Nodal 🏥

[![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white)](https://flutter.dev/)
[![Dart](https://img.shields.io/badge/dart-%230175C2.svg?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev/)

**Connect the dots of your family's medical history.**

Nodal is a local-first, profile-centric Flutter application designed to replace the physical "medical file folder." It allows you to manage prescriptions, track active treatments, and organize doctor visits for yourself and your family members in one secure place.

## 🏗️ Architecture: Profile-First, Doctor-Centric

Nodal is built around a specific data hierarchy to ensure medical records are never mixed up. Every piece of medical data belongs to a **Profile** (a family member) and is categorized under a specific **Doctor Visit**.

1. **The Profile (Who):** The top-level container (e.g., "Dad", "Mom", "Self"). 
2. **The Doctor (Source):** Each profile has its own directory of healthcare providers.
3. **The Visit (Event):** The timeline of interactions with a doctor.
4. **The Data (Records):** Diagnoses, Prescriptions, Test Reports, and Medicines are all attached to a specific *Visit*.

## ✨ Key Features

* **Multi-Profile Management:** Switch contexts easily between different family members. Each profile maintains its own isolated dashboard, doctor directory, and active medication list.
* **Visit Timelines:** Log appointments, attach PDF test reports, and digitize physical prescriptions.
* **Active Status Dashboard:** The app automatically filters historical data to show a "Right Now" view of active diagnoses and current medication schedules.
* **Local-First Privacy:** All sensitive health data is stored locally on the device ensuring complete privacy. 

## 🛠️ Tech Stack

* **Framework:** Flutter
* **Language:** Dart 
* **Routing:** `go_router` (with `go_router_builder` for type-safe routes)
* **Architecture:** Feature-First (Domain Driven)

## 🚀 Getting Started

### Prerequisites

* Flutter SDK (Latest stable) or 3.41.x
* Dart SDK `3.11` or higher

### Installation

1. Clone the repository:
   git clone https://github.com/maranix/nodal.git

2. Navigate to the project directory:
   cd nodal

3. Install dependencies:
   flutter pub get

4. Run the code generator (Required for GoRouter and Local DB models):
   dart run build_runner build --delete-conflicting-outputs

5. Run the app:
   flutter run

## 📂 Project Structure

Nodal uses a feature-first folder structure to maintain clean separation of concerns:

lib/
├── core/                   # App-wide services, theme, and router configuration
│   └── router/             # Central GoRouter instance 
├── features/
│   ├── profile/            # Profile creation, switching, and dashboard UI
│   ├── doctor/             # Per-profile doctor directory
│   └── visit/              # Visit timeline, prescriptions, and test reports
└── main.dart               # Entry point

## 🤝 Contributing

Contributions are welcome! If you have a suggestion that would make this better, please fork the repo and create a pull request. 

1. Fork the Project
2. Create your Feature Branch (git checkout -b feature/AmazingFeature)
3. Commit your Changes (git commit -m 'Add some AmazingFeature')
4. Push to the Branch (git push origin feature/AmazingFeature)
5. Open a Pull Request