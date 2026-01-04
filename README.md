# DDNS Updater

A robust Flutter application for managing Dynamic DNS (DDNS) updates, specifically designed to run reliably on Android devices (including Android TV). It allows you to keep your home IP address synced with your DDNS provider (currently supporting **DuckDNS**).

## Features

*   **Multi-Account Support**: Manage multiple DDNS configurations in one place.
*   **DuckDNS Integration**: Seamlessly sets up subdomains with DuckDNS.
*   **Background Updates**: Uses `workmanager` to perform reliable periodic updates updates in the background, even when the app is closed.
*   **Configurable Intervals**: Choose how often each account updates (15m, 30m, 1h, 12h, 24h) to avoid rate limits.
*   **Log History**: View a detailed activity log for each account (last 50 entries) to track successful syncs and errors.
*   **Dark Theme UI**: A sleek, modern "Cyber/Dark" aesthetic built with Google Fonts (Outfit).
*   **Android TV Compatible**: Designed to work well on both phones and TV boxes.

## Architecture

This project follows a **Clean Architecture** inspired structure with a **Provider** based state management approach:

*   **`lib/core/`**: Core utilities and theming (e.g., `AppTheme`).
*   **`lib/models/`**: Data models (`DDNSConfig`, `LogEntry`).
*   **`lib/providers/`**: State management logic (`ConfigProvider`, `HomeProvider`).
*   **`lib/services/`**: logic for API calls (`DDNSService`) and background tasks (`BackgroundService`).
*   **`lib/ui/screens/`**: Application screens (`HomeScreen`, `ManageConfigsScreen`, `ConfigDetailsScreen`).
*   **`lib/ui/widgets/`**: Reusable UI components.

## Getting Started

1.  **Clone the repository**:
    ```bash
    git clone <repository-url>
    ```
2.  **Install dependencies**:
    ```bash
    flutter pub get
    ```
3.  **Run the app**:
    ```bash
    flutter run
    ```

## Usage

1.  **Add Account**: On the home screen, select "DuckDNS", enter your Subdomain and Token, and choose an Update Frequency.
2.  **Manage Accounts**: Click the list icon in the top right to view all configured accounts.
3.  **View Logs**: Tap on any account in the list to see its details and a history of the last 50 update attempts.
4.  **Manual Update**: Inside the details screen, click the cyan refresh button to trigger an immediate update and log the result.

## Dependencies

*   `provider`: State management.
*   `shared_preferences`: Local storage for configs and logs.
*   `workmanager`: Android background task scheduling.
*   `dio`: HTTP client for API requests.
*   `uuid`: Unique ID generation.
*   `google_fonts`: Typography.
*   `intl`: Date formatting.
