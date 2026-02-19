# Roadmap 

**Vision:** A profile-centric family health wallet.

---

## 🏗️ Phase 1: "Profile" Module (Foundation)

**Goal:** Establish the multi-user architecture. The app should launch, allow creating/switching profiles. 

### 1.1 Project Setup
- [x] Initialize Flutter Project (`flutter create nodal`).
- [x] Setup Folder Structure (Features: `profile`, core`, ...).
- [x] Add Sqlite
- [x] Define `Profile` Model:
    - `id` (UUID)
    - `name` (String)
    - `dob` (DateTime - for dynamic Age)

### 1.2 Profile Management
- [ ] **Profile Switcher Screen:**
    - [ ] UI: Grid/List of avatars.
    - [ ] Logic: "Select Profile" updates the global active profile state.
- [ ] **Create/Edit Profile:**
    - [ ] Form: Name, DOB and etc.
    - [ ] Database: CRUD operations for Profiles.

---

## 🩺 Phase 2: The "Doctor & Visit" Log
**Goal:** The core data entry flow. Users add medical data *inside* a specific Doctor's timeline.

### 2.1 The Doctor Directory (Per Profile)
- [ ] Define `Doctor` Model:
    - `id`, `profileId` (FK), `name`, `specialty`, `phone`, `isCurrent` (bool).
- [ ] **Doctor List UI:**
    - [ ] Display list of Doctors associated with the *current* profile.
    - [ ] Filter by "Current" vs "Past".
- [ ] **Add/Edit Doctor:**
    - [ ] Form to add a new Doctor to a Profile.

TBD

---

## ⚡ Phase 3: The "Active" Dashboard (The View Layer)
**Goal:** Aggregate data from the "Visits" to show a "Right Now" snapshot on the Profile Home screen.

TBD

---

## 🔍 Phase 4: Search, Filter & Polish
**Goal:** Make the data retrievable and the app usable.

TBD

---

## ☁️ Phase 5: Backup & Export (Future)

TBD
