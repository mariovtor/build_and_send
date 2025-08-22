# Build and Send - Context

This document provides a technical overview of the `build_and_send` Dart package.

## Project Description

`build_and_send` is a command-line tool designed to automate the process of building and deploying mobile applications (Android and iOS). It handles building artifacts (APK, App Bundle, IPA), uploading them to distribution platforms (Google Cloud Storage, TestFlight), and sending notifications to Discord.

The tool is highly configurable through a `build_config.yaml` file and uses a `.env` file for sensitive data.

## Core Features

-   **Android Build:** Builds APKs and App Bundles for different flavors.
-   **iOS Build:** Builds IPAs for different flavors.
-   **Google Cloud Storage Upload:** Uploads Android artifacts to a specified GCS bucket.
-   **TestFlight Upload:** Uploads iOS IPAs to TestFlight.
-   **Discord Notifications:** Sends customizable notifications to a Discord channel with build status and download links.
-   **Flavor Support:** Manages different build configurations for different environments (e.g., dev, staging, prod).
-   **Extensible:** Can be configured to use different build methods like `fvm` or `shorebird`.

## Project Structure

The project is structured as follows:

-   `bin/build_and_send.dart`: The main executable entry point. It parses command-line arguments and initiates the process.
-   `lib/build_and_send.dart`: The main library file, which exports the necessary components.
-   `lib/src/`: Contains the core logic of the application.
    -   `starter.dart`: The main orchestrator that reads configurations and triggers the build and send process.
    -   `build_config.dart`: Manages the `build_config.yaml` file.
    -   `build_runner.dart`: Executes the actual build commands.
    -   `discord_notifier.dart`: Handles sending notifications to Discord.
    -   `env_loader.dart`: Loads environment variables from the `build.env` file.
    -   `constants.dart`: Contains constant values used throughout the application.
    -   `exceptions/`: Custom exception classes.
    -   `utils/`: Utility functions.
-   `example/`: Contains example configuration files.
-   `test/`: Contains unit and utility tests.

## Dependencies

The project relies on the following key dependencies:

-   `args`: For parsing command-line arguments.
-   `yaml`: For reading and parsing the `build_config.yaml` file.
-   `http`: For making requests to the Discord webhook.
-   `ansi`: For colored console output.

## How to Use

1.  Add `build_and_send` to your `pubspec.yaml` as a dev dependency.
2.  Create a `build_config.yaml` file in your project root to define the build process.
3.  Create a `build.env` file in your project root for sensitive data like API keys and passwords.
4.  Run the tool from your terminal:

    ```shell
    dart run build_and_send [options]
    ```

For more details on the available options and configuration, please refer to the `README.md` file.
