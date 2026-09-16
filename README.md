# 💊 Home Pharmacy – Smart Medication & Adherence Dashboard

## 📌 About the Project

Home Pharmacy is a mobile application designed to help users organize household medications, schedule daily doses, and monitor adherence routines through a centralized, intuitive interface.

The system manages virtual medicine cabinets, tracks daily compliance, and archives completed regimens, making it simple for individuals and families to stay consistent with their healthcare treatments.

This project was developed for the Tuwaiq Academy Showcase using Flutter and Dart.

---

## 🎯 Project Goal

The main goal of the project is to provide a clean and reliable interface for home medication management.

Instead of dealing with scattered pillboxes and easily forgotten schedules, the application organizes medication routines into an accessible platform where users can:

* 🗄️ Organize medications across custom virtual cabinets
* 📅 View daily scheduled doses at a glance
* ✅ Check off completed doses in real time
* 📈 Track daily medication adherence rates automatically
* 🚑 Access first-aid supplies and emergency medicines quickly
* 🛡️ Prevent duplicate purchases and medicine waste

---

## ✨ Features

### 🗄️ Virtual Cabinets
Users can categorize and store medicines by family member, room, or specific health conditions.

### 📅 Daily Dose Checklist
A clear daily schedule displays active doses with one-tap status toggling.

### 📈 Adherence Tracking
Daily compliance percentages are calculated dynamically to show real-time progress.

### 🚑 First Aid Quick Access
A dedicated section providing essential instructions and quick access for emergency and first-aid supplies.

### ➕ Medication Registration
Easily add new medications, assign cabinet locations, and define course durations.

### 🔔 Local & Smart Notifications
Timely reminders to keep users consistent with scheduled dose intervals.

---

## 🖥️ Application Pages

The application consists of the following key screens:

1. **Home Screen (`home_screen.dart`)**  
   Provides an overview of the pharmacy, quick actions, and current medication status.

2. **Cabinets Screen (`cabinet_screen.dart`)**  
   Manages virtual medicine cabinets and categorizes household treatments.

3. **History & Schedule Screen (`history_screen.dart`)**  
   Displays daily dose schedules, tracks adherence progress, and logs completed doses.

4. **First Aid Screen (`first_aid_screen.dart`)**  
   Provides quick access and instructions for essential first-aid supplies and emergency medicines.

5. **Add Medicine Screen (`add_screen.dart`)**  
   Allows users to register new medications, set dosage quantities, and specify course dates.

6. **Authentication Screen (`auth_screen.dart`)**  
   Handles user sign-in and secure profile access connected to Supabase.

---

## 🎨 Color Palette

| Color Preview | Color Name | Role / Usage | Hex Code |
| :---: | :--- | :--- | :---: |
| <img src="https://singlecolorimage.com/get/F9F1ED/40x40" width="32" height="32" /> | **Warm Cream** | Background / Canvas | `#F9F1ED` |
| <img src="https://singlecolorimage.com/get/E57373/40x40" width="32" height="32" /> | **Coral Rose** | Primary / Accent | `#E57373` |
| <img src="https://singlecolorimage.com/get/2D3142/40x40" width="32" height="32" /> | **Deep Slate** | Text / Dark Contrast | `#2D3142` |
| <img src="https://singlecolorimage.com/get/81C784/40x40" width="32" height="32" /> | **Soft Mint** | Completed / Success | `#81C784` |

---

## 🛠️ Technologies Used

* 📱 **Flutter** – Mobile application development and cross-platform UI
* 🎯 **Dart** – Core programming language
* ⚡ **Supabase** – Cloud PostgreSQL database, data relations, and authentication
* 🎨 **Figma** – UI/UX design system and interactive mockups
* 🐙 **GitHub** – Version control and collaborative repository
* 💻 **VS Code / Android Studio** – Integrated development environment

---

## 📡 Data Source & Architecture

The application communicates directly with a cloud-hosted Supabase PostgreSQL database. 

It manages structured relational schemas including medicine entities, dose schedules, and adherence logs (`medicines`, `dose_schedules`, and `dose_logs`) with real-time status updates.

---

## 📸 Screenshots

### 🏠 Home Screen

<img width="1178" height="1602" alt="Screenshot 2026-09-16 215516" src="https://github.com/user-attachments/assets/e36d53a6-e246-44ed-ac6d-cd828055a1d0" />



The main central overview providing quick access to active medications and daily highlights.

### 🗄️ Cabinets Screen


<img width="1176" height="1580" alt="Screenshot 2026-09-16 215538" src="https://github.com/user-attachments/assets/042f12d3-058f-4459-a096-e98036246470" />


The organization view sorting virtual cabinets, storage spots, and household medicine boxes.

### 📅 Daily Schedule & History
<img width="1112" height="1592" alt="Screenshot 2026-09-17 004344" src="https://github.com/user-attachments/assets/148249ca-4df2-4c1c-a577-a26c03d90346" />




The daily timeline displaying scheduled doses, one-tap checkoffs, and compliance percentages.

### 🚑 First Aid Screen

<img width="1204" height="1592" alt="Screenshot 2026-09-16 224031" src="https://github.com/user-attachments/assets/f46c8a63-3a2a-454a-9c0e-6cfac31583b4" />



Quick access view for essential emergency medicines and supplies.

---

## 📂 Project Structure

lib/

├── screens/

│   ├── add_screen.dart

│   ├── auth_screen.dart

│   ├── cabinet_screen.dart

│   ├── first_aid_screen.dart

│   ├── history_screen.dart

│   └── home_screen.dart
│
├── services/

│   └── notification_service.dart

│
├── main_nav_screen.dart

└── main.dart

---

## 🚀 Getting Started

### Prerequisites

Make sure you have the following installed:

* ⚙️ Flutter SDK (3.x or higher)
* 🎯 Dart SDK
* 💻 Android Studio or VS Code
* 🐙 Git

### Installation

Clone the repository:  
git clone https://github.com/home-phrmacy/medcine-app

Navigate to the project folder:  
cd medcine-app

Install the required dependencies:  
flutter pub get

Run the application:  
flutter run

---

## 👥 Project

This application was developed as part of the **Tuwaiq Academy Bootcamp**.

### 👩‍💻 Team Members

* **Taif Fawaz**
* **Malak Almasabi**

---

## 📄 License

Developed as part of Tuwaiq Academy training under the supervision of Eng. Mohammed Al-Awashiz.
