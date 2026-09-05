# Flutter App Architecture Rules

Follow these rules for all Flutter development in this workspace:

## Architecture & Structure
- Implement Clean Architecture principles while strictly maintaining the **GetX Folder Structure**.
- Each feature in `lib/app/modules/` should have:
  - `bindings/`
  - `controllers/`
  - `views/` (All views must extend `GetView<ControllerType>`)
- Data sources and models should be organized under `lib/app/data/` (e.g., `providers/`, `models/`).

## UI & Theming
- Maintain central definitions for:
  - App Theme (`theme`)
  - App Colors (`app colors`)
  - Custom Buttons
  - Custom TextFields
  - App Text/Typography
- Always check for existing custom widgets before creating new ones.
- **Strictly use the Custom Snackbar and Custom Loader components** across the entire app. Do not use random or default snackbars/loaders anywhere.
- Strictly ignore and avoid writing duplicate code. Re-use existing UI components.

## File Size Constraints
- **Maximum 150 lines per file.**
- If a file exceeds this limit, you must refactor it by extracting the UI components into smaller widget files (under a `widgets` folder for that feature) and referencing them, ensuring you use clean architecture properly.

## Networking & API
- Use a dedicated **Network Caller** file to handle all API communications.
- All API calls must go through this custom request handler.
- Use **Dio** for handling HTTP requests.
- Always use **Models** for JSON parsing (serialization/deserialization).

## State Management & Storage
- Use **GetX** for state management, dependency injection, and routing.
- Use **Hive** properly for all local storage needs.
