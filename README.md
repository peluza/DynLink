# DDNS Updater

A robust Flutter application for managing Dynamic DNS (DDNS) updates, specifically designed to run reliably on Android devices (including Android TV). It allows you to keep your home IP address synced with your DDNS provider (currently supporting **DuckDNS**).

## Features

*   **Smart Update Logic**: Checks if your public IP matches the domain's current IP before updating. Skips unnecessary requests to prevent bans, but enforces a mandatory update every 15 days to keep the hostname active.
*   **Failover IP Detection**: Uses multiple IP verification services (`icanhazip.com`, `aws`) and rotates them every 15 minutes to guarantee reliability.
*   **Background Persistence**: Configured to auto-start on device boot (`RECEIVE_BOOT_COMPLETED`) and ignore battery optimizations, ensuring the app behaves like a system service.
*   **Multi-Account Support**: Manage multiple DDNS configurations in one place.
*   **DuckDNS Integration**: Seamlessly sets up subdomains with DuckDNS.
*   **Background Updates**: Uses `workmanager` to perform reliable periodic updates updates in the background, even when the app is closed.
*   **Configurable Intervals**: Choose how often each account updates (15m, 30m, 1h, 12h, 24h).
*   **Log History**: View a detailed activity log for each account, distinguishing between "Success" (IP Changed) and "Skipped" (IP Synced).
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

1.  **Grant Permissions**: On first launch, click the **Battery Icon** in the top-right corner to request exemption from battery optimizations. This is critical for background reliability.
    *   **Orange Icon**: Optimization is enabled (Bad for background tasks). Click to fix.
    *   **Green Icon**: Optimization is disabled (Good). The app can run freely.
2.  **Add Account**: On the home screen, select "DuckDNS", enter your Subdomain and Token, and choose an Update Frequency.
3.  **Manage Accounts**: Click the list icon in the top right to view all configured accounts.
4.  **View Logs**: Tap on any account in the list to see its details and a history of the last 50 update attempts.
5.  **Manual Update**: Inside the details screen, click the cyan refresh button to trigger an immediate update and log the result.

## Dependencies

*   `provider`: State management.
*   `shared_preferences`: Local storage for configs and logs.
*   `workmanager`: Android background task scheduling.
*   `dio`: HTTP client for API requests.
*   `uuid`: Unique ID generation.
*   `google_fonts`: Typography.
*   `intl`: Date formatting.
