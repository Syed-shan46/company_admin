# Company Admin Portal

This is the Super Admin portal for the Multi-Vendor platform. Use this app to:
- Approve or Reject new Vendor registrations.
- View platform analytics.
- Manage users (Ban/Unban).

## Login Credentials

**Important**: These credentials are for the Super Admin account created by the backend.

| Role | Email | Password |
|------|-------|----------|
| **Super Admin** | `admin@zepcart.com` | `password123` |

> These credentials are configured in the backend `.env` file (`ADMIN_EMAIL`, `ADMIN_PASSWORD`).

## Setup

1. **Backend**: Ensure the backend server is running (`npm run dev`).
   - Default URL: `http://localhost:5000` (or `192.168.x.x`)
2. **Flutter App**:
   - `flutter pub get`
   - `flutter run`

## Architecture
- **State Management**: Riverpod
- **Routing**: GoRouter
- **Networking**: http (ApiClient wrapper)

## Project Structure
- `lib/src/features/vendors`: Vendor approval workflow.
- `lib/src/features/dashboard`: Main stats view.
- `lib/src/features/auth`: Login screen and logic.
