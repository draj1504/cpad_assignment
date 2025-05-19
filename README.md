# cpad_assignment

Cross-Platform Application Development - Assignment
BITS ID: 2023TM93653

# Purpose

This Flutter application allows users to sign up, log in, manage a list of people (CRUD), and update their account details securely. The app is integrated with Back4App (Parse Platform) for backend services.

# TECHNOLOGIES USED:

Flutter
Back4App (Parse Server)
Dart
Parse Server SDK for Flutter

# Backend Features:
**Authentication:** Using ParseUser for Login / Signup.
**Data Storage:** Persons class stores user-created records.
**User-Level Access:** Users can only access their own data.
**Security:** Each record uses ACL or queries filtered by current user.

# Collections in Back4App:
**User:** Stores registered users.
**Persons:** Stores firstName, lastName, age, username (Current User)

# Demo Link

https://drive.google.com/file/d/1bX9qMFcYNKfbXd6Sy4o5-1VFCN7K-265/view?usp=sharing
