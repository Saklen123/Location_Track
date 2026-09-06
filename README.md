# Flutter Location Tracking App

A comprehensive Flutter application demonstrating Google Maps integration and real-time location tracking with background support.

## Features

- Google Maps integration with custom markers
- Real-time foreground location tracking
- Background location tracking
- Location permission handling (denied, permanently denied, services disabled)
- Display of latitude, longitude, speed, altitude, and last updated time
- Clean architecture with Riverpod state management
- Cross-platform support (Android & iOS)

## Setup Instructions

### Prerequisites

1. Flutter SDK (3.0 or higher)
2. Android Studio / Xcode
3. Google Maps API Key
4. Physical device for testing (location services)

### Google Maps API Setup

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select existing one
3. Enable Google Maps SDK for Android and iOS
4. Create API keys for both platforms

### Android Configuration

1. Add API key to `android/app/src/main/AndroidManifest.xml`:
```xml
<manifest>
    <application>
        <meta-data
            android:name="com.google.android.geo.API_KEY"
            android:value="YOUR_ANDROID_API_KEY" />
    </application>
</manifest>