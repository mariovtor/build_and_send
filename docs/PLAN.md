# Development Plan - Build and Send

This document outlines the development plan for refactoring and enhancing the `build_and_send` package. Each major task is broken down into smaller, actionable steps. We will mark items as complete as we progress.

## Phase 1: Project Setup and Refactoring ✅ **COMPLETELY FINISHED**

-   [x] **1.1. Setup FVM for the package** ✅ **COMPLETED**
    -   [x] 1.1.1. Add a `.fvm/fvm_config.json` to the project to lock the Flutter version for the package.
    -   [x] 1.1.2. Update the CI/CD pipeline to use the FVM version.
    -   [x] 1.1.3. Document the FVM usage within the package.
-   [x] **1.2. Initial Refactoring** ✅ **COMPLETED**
    -   [x] 1.2.1. **Abstract the Notifier** ✅ **COMPLETED**
        -   [x] 1.2.1.1. Create a `Notifier` interface with a `notify` method.
        -   [x] 1.2.1.2. Create a `DiscordNotifier` class that implements the `Notifier` interface.
        -   [x] 1.2.1.3. Create a `NotificationService` to manage notifiers.
        -   [x] 1.2.1.4. Add tests for the `NotificationService` and `DiscordNotifier`.
    -   [x] 1.2.2. **Abstract the Uploader** ✅ **COMPLETED**
        -   [x] 1.2.2.1. Create an `Uploader` interface with an `upload` method.
        -   [x] 1.2.2.2. Create `GCloudUploader` and `TestFlightUploader` classes that implement the `Uploader` interface.
        -   [x] 1.2.2.3. Create an `UploadService` to manage uploaders.
        -   [x] 1.2.2.4. Add tests for the `UploadService` and `GCloudUploader`/`TestFlightUploader`.
    -   [x] 1.2.3. **Abstract the Builder** ✅ **COMPLETED**
        -   [x] 1.2.3.1. Create a `Builder` interface with a `build` method.
        -   [x] 1.2.3.2. Create `AndroidBuilder` and `IOSBuilder` classes that implement the `Builder` interface.
        -   [x] 1.2.3.3. Create a `BuildService` to manage builders.
        -   [x] 1.2.3.4. Add tests for the `BuildService` and `AndroidBuilder`/`IOSBuilder`.
    -   [x] 1.2.4. **Refactor `BuildRunner`** ✅ **COMPLETED**
        -   [x] 1.2.4.1. Refactor `BuildRunner` to be a coordinator that uses the new services.
        -   [x] 1.2.4.2. Move the build, upload, and notification logic to their respective services.
    -   [x] 1.2.5. **Improve Configuration** ✅ **COMPLETED**
        -   [x] 1.2.5.1. Update `build_config.yaml` to support the new abstracted services.
    -   [x] 1.2.6. **Improve Error Handling and Logging** ✅ **COMPLETED**
        -   [x] 1.2.6.1. Implement a more robust error handling and logging mechanism.
        -   [x] 1.2.6.2. Integrate a logging package like `logging`.
    -   [x] 1.2.7. **Implement Input Validation and Sanitization** ✅ **COMPLETED**
        -   [x] 1.2.7.1. Add validation for command-line arguments.
        -   [x] 1.2.7.2. Add validation and sanitization for all values read from `build_config.yaml`.
        -   [x] 1.2.7.3. Add environment variable validation.
        -   [x] 1.2.7.4. Add security checks for potential injection attacks.
-   [x] **1.3. Improve Testing** ✅ **COMPLETED**
    -   [x] 1.3.1. Review the existing tests and improve their coverage and effectiveness.
    -   [x] 1.3.2. Add comprehensive tests for the core components, including `starter`, `build_config`, and `build_runner`.
    -   [x] 1.3.3. Add comprehensive tests for all validation modules.

## Phase 2: New Features

-   [ ] **2.1. Firebase App Distribution**
    -   [ ] 2.1.1. Research the Firebase App Distribution API and the best way to integrate it with Dart.
    -   [ ] 2.1.2. Implement a pre-run check to ensure Firebase is configured correctly.
    -   [ ] 2.1.3. Implement the uploader for Firebase App Distribution.
    -   [ ] 2.1.4. Add the necessary Firebase configuration options to the `build_config.yaml` file.
    -   [ ] 2.1.5. Add tests for the Firebase App Distribution feature.
    -   [ ] 2.1.6. Update the documentation to reflect the new feature.
-   [ ] **2.2. Fastlane for Google Play Console**
    -   [ ] 2.2.1. Research how to integrate and use Fastlane with Dart for Android deployment.
    -   [ ] 2.2.2. Implement a pre-run check to ensure Fastlane is installed and configured.
    -   [ ] 2.2.3. Implement the uploader using Fastlane.
    -   [ ] 2.2.4. Add the necessary Fastlane configuration options to the `build_config.yaml` file.
    -   [ ] 2.2.5. Add tests for the Fastlane feature.
    -   [ ] 2.2.6. Update the documentation to reflect the new feature.
-   [ ] **2.3. Flexible Distribution Strategy**
    -   [ ] 2.3.1. Design a new, more flexible configuration structure for the `build_config.yaml` file.
    -   [ ] 2.3.2. Implement the logic to parse and execute the defined distribution strategies.
    -   [ ] 2.3.3. Refactor the existing uploaders to be compatible with the new distribution strategy.
    -   [ ] 2.3.4. Add tests for the flexible distribution strategy feature.
    -   [ ] 2.3.5. Update the documentation to reflect the new feature.

## Phase 3: Finalization

-   [ ] **3.1. Code Review and Cleanup**
    -   [ ] 3.1.1. Conduct a thorough review of the entire codebase for consistency, quality, and best practices.
    -   [ ] 3.1.2. Remove any dead code, and add comments where necessary.
-   [ ] **3.2. Documentation**
    -   [ ] 3.2.1. Update the `README.md` file to include the new features and configuration options.
    -   [ ] 3.2.2. Update the `context.md` file to reflect the new architecture.
-   [ ] **3.3. Release**
    -   [ ] 3.3.1. Update the `CHANGELOG.md` with all the new features and improvements.
    -   [ ] 3.3.2. Increment the package version in the `pubspec.yaml` file.
    -   [ ] 3.3.3. Publish the new version of the package to pub.dev.
