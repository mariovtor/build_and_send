# Product Requirements Document (PRD) - Build and Send

## 1. Introduction

This document outlines the product requirements for the refactoring and enhancement of the `build_and_send` Dart package. The goal is to improve the existing functionality, add new features, and enhance the overall architecture, security, and developer experience.

## 2. Goals

-   **Refactor and Improve:** Modernize the codebase by improving architecture, security, and error handling.
-   **Add New Features:** Extend the package's capabilities with new distribution channels and more flexible configurations.
-   **Enhance Developer Experience:** Make the package easier to use, configure, and maintain.

## 3. Existing Features (to be maintained and improved)

-   **Build Automation:** Continue to support building Android (APK, App Bundle) and iOS (IPA) artifacts.
-   **Build Methods:** Maintain support for different build methods, including `fvm`, `shorebird`, and the default Flutter toolchain.
-   **Flavor Management:** Continue to support build flavors for different environments.
-   **Environment Variables:** Securely handle environment variables for build configurations.
-   **Distribution:**
    -   Google Cloud Storage: Upload Android artifacts.
    -   TestFlight: Upload iOS IPAs.
-   **Notifications:** Send notifications to Discord.

## 4. New Features

### 4.1. Firebase App Distribution

-   **Description:** Allow users to upload Android and iOS builds to Firebase App Distribution.
-   **Configuration:** Users will configure their Firebase settings in the `build_config.yaml` file, including the Firebase App ID and service account credentials.
-   **Pre-requisite Check:** The tool will verify that the necessary Firebase configuration and credentials are in place before attempting to upload.

### 4.2. Fastlane for Google Play Console

-   **Description:** Enable users to use Fastlane to upload Android artifacts directly to the Google Play Console.
-   **Configuration:** Users will configure their Fastlane settings in the `build_config.yaml` file.
-   **Pre-requisite Check:** The tool will verify that Fastlane is installed and properly configured in the user's environment before attempting to use it.

### 4.3. Flexible Distribution Strategy

-   **Description:** Allow users to define and manage complex distribution strategies in the `build_config.yaml` file.
-   **Example:** A user could define a strategy to:
    1.  Build a specific flavor.
    2.  Upload the Android artifact to Firebase App Distribution.
    3.  Upload the iOS artifact to TestFlight.
    4.  Send a notification to Discord upon completion.

### 4.4. Abstracted Notification System

-   **Description:** The notification system will be refactored to be platform-agnostic.
-   **Goal:** This will allow for the easy addition of new notification platforms in the future, such as Slack, without requiring significant changes to the core logic.
-   **Initial Implementation:** The initial implementation will continue to support Discord, but the architecture will be designed to accommodate other platforms.

### 4.5. FVM for the Package

-   **Description:** The `build_and_send` package will use a specific Flutter version via FVM (Flutter Version Management) internally.
-   **Goal:** This will ensure consistency and prevent conflicts with the user's project-specific FVM setup.

### 4.6. Comprehensive Tests

-   **Description:** The package will have a robust and comprehensive test suite.
-   **Goal:** To ensure the reliability and maintainability of the package, with good test coverage for all features.

## 5. Non-Functional Requirements

-   **Improved Architecture:** The codebase will be refactored to follow SOLID principles, making it more modular, maintainable, and scalable.
-   **Enhanced Security:** Sensitive data, such as API keys and passwords, will be handled with the utmost care to prevent exposure.
-   **Robust Error Handling:** The package will implement comprehensive error handling to provide clear, informative, and actionable error messages.
-   **Improved Logging:** Logging will be enhanced to be more informative and configurable, with options for verbose output.
-   **Continuous Testing:** After each significant change or new feature implementation, a corresponding set of tests (unit, integration) will be written and executed to ensure that the codebase remains stable and that new changes do not introduce regressions.
-   **Input Validation and Sanitization:** All user inputs, whether from the command line or configuration files, will be validated and sanitized to prevent security vulnerabilities such as command injection and to ensure the stability of the tool.
