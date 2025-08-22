# Build and Send - AI Coding Agent Instructions

## Project Overview
`build_and_send` is a Dart CLI tool for automating mobile app builds (Android/iOS) with cloud uploads and Discord notifications. **Currently undergoing architectural refactoring** from monolithic to service-oriented design.

## Architecture Status (Mid-Refactoring)

### ✅ Completed Abstractions
- **Notifiers**: `Notifier` interface → `DiscordNotifier` implementation via `NotificationService`
- **Uploaders**: `Uploader` interface → `GCloudUploader` implementation via `UploadService`  
- **New Context Objects**: `NotificationContext`, `UploadContext` for clean data passing

### 🚧 In Progress (Legacy Code Still Present)
- `BuildRunner` still contains monolithic logic alongside new service usage
- Old `DiscordNotifier` in `/src/discord_notifier.dart` coexists with new one in `/src/notifiers/`
- Builder abstraction planned but not implemented

### 🎯 Key Architectural Pattern
Services follow factory pattern: `ServiceName.create()` returns appropriate implementation based on config.

```dart
// Example: UploadService creates GCloudUploader when gcloud config present
final uploader = UploadService.create(config: config, ...);
if (uploader != null) {
  final url = await uploader.upload(UploadContext(...));
}
```

## Essential Development Context

### Configuration-Driven Execution
- `build_config.yaml`: Main configuration defining platforms, flavors, upload targets
- `build.env`: Sensitive credentials (gitignored) - email accounts, API keys, passwords
- **Flavor System**: Custom build configurations override base settings via `config.flavors[flavorName]`

### Build Method Abstraction
Three supported build methods via `method` field:
- `default`: Standard Flutter CLI (but always use `fvm flutter` in development)
- `fvm`: Flutter Version Management (explicitly uses FVM - redundant since we always use FVM)  
- `shorebird`: Code-push capable builds

Commands are dynamically prefixed: `fvm flutter build apk` → `fvm fvm flutter build apk` (when method=fvm)

### Platform-Specific Workflows
- **Android**: APK + Bundle → GCloud Storage (public URLs)
- **iOS**: IPA → TestFlight via `xcrun altool` (macOS only)
- **Cross-platform**: Discord notifications with build artifacts and @mentions

### Critical File Locations
- Tests: `test/unit/` (only `gcloud_uploader_test.dart` exists currently)
- New architecture: `lib/src/notifiers/`, `lib/src/uploaders/`
- Legacy code: `lib/src/discord_notifier.dart`, monolithic `BuildRunner`
- Entry point: `bin/build_and_send.dart` → `Starter.start()`

## Development Patterns

### Error Handling via ConsolePrinter
```dart
ConsolePrinter.writeError('Message', shouldExit: false); // Continue execution  
ConsolePrinter.writeGreen('Success message');
ConsolePrinter.slashes().writeProgress('Building...', run: () async { /* work */ });
```

### Comprehensive Verbose Logging System
The project includes a centralized `Logger` class providing hierarchical, color-coded output when `--verbose` flag is used:

```dart
import '../logger.dart';

// Section management for organized output
Logger.startSection('Android Build');         // ━━━ Starting: Android Build ━━━
Logger.endSection();                         // ━━━ Completed: Android Build ━━━

// Step-by-step progression
Logger.step('Building APK file');           // → Building APK file

// Different log levels with color coding  
Logger.info('Build started');               // [INFO] Build started
Logger.debug('Internal state info');        // [DEBUG] Internal state info (verbose only)
Logger.success('Build completed');          // [SUCCESS] Build completed  
Logger.warning('Non-critical issue');       // [WARNING] Non-critical issue
Logger.error('Build failed');               // [ERROR] Build failed

// Configuration and command visibility
Logger.config('Platform', 'android');       // [CONFIG] Platform: android
Logger.command('flutter build apk');        // [COMMAND] flutter build apk
```

**Logger Integration Pattern**: Every major service (`AndroidBuilder`, `IOSBuilder`, `GCloudUploader`, `DiscordNotifier`) uses sections and step logging:
1. `Logger.startSection('Service Name')` at method entry
2. `Logger.step('Action description')` for major operations  
3. `Logger.debug()` for internal state (verbose-only)
4. `Logger.command()` for shell command execution
5. `Logger.success()/error()` for outcomes
6. `Logger.endSection()` in finally blocks

**Initialization**: Logger must be initialized in `Starter.start()` with verbose flag before any other logging calls.

### Command Execution Pattern
`_runCommand()` method handles shell execution with progress indicators:
```dart
await _runCommand(
  'fvm flutter build apk',
  progressMessage: 'Building APK',
  onRun: (ProcessResult result) => handleResult(result),
);
```

### Environment Variable Hierarchy
`EnvLoader.get('KEY')` with fallback chains:
- Flavor-specific: `DEV_UPLOAD_EMAIL`
- Generic: `ACCOUNT_EMAIL`
- Default: empty string

## Testing Strategy
- **Current**: Only `GCloudUploader` has comprehensive tests with mocked shell commands
- **Pattern**: Use `mocktail` for mocking, especially `RunCommandFunction` typedef for command execution
- **Missing**: Tests for `NotificationService`, `DiscordNotifier`, `BuildService` (planned)

## Development Workflow
- **Always use FVM**: Every `dart`/`flutter` command must be prefixed with `fvm` (project locked to Flutter 3.35.1)
- **Lint Analysis**: **ALWAYS run `fvm dart analyze` after any code changes and fix all issues before proceeding**
- **Test After Changes**: Run `fvm dart test` to verify functionality after implementing features
- **Incremental Development**: Make small changes, analyze, test, then proceed to next step

## Mandatory Development Steps (ALWAYS Follow This Order)
1. **Create/Edit Code**: Implement the requested changes
2. **Lint Check**: Run `fvm dart analyze` and fix ALL issues before proceeding
3. **Test Execution**: Run `fvm dart test` to ensure functionality works
4. **Verification**: Confirm all tests pass before moving to next task

**⚠️ CRITICAL**: Never proceed to testing without first running lint analysis and fixing all reported issues.

## Key Commands & Workflows
- **Development**: `fvm dart run build_and_send -p android -f dev -v` (verbose Android dev build)
- **Lint Check**: `fvm dart analyze` (run after every change - MANDATORY)
- **Testing**: `fvm dart test test/unit/specific_test.dart` (specific tests)
- **Full Testing**: `fvm dart test` (all tests)
- **Build Check**: `fvm dart compile exe bin/build_and_send.dart` (verify executable builds)

## Refactoring Guidelines
1. **Preserve dual architecture temporarily**: New services alongside legacy `BuildRunner`
2. **Follow established patterns**: Factory methods, context objects, interface implementations
3. **Add tests when creating services**: Mock shell commands via `RunCommandFunction` parameter injection
4. **Use semantic imports**: `library build_and_send;` at top of each file
5. **Mandatory lint checking**: Run `fvm dart analyze` after every file creation/modification
6. **Test-driven development**: Write tests for new functionality and ensure they pass

## Common Gotchas
- **File existence checks**: Always verify build artifacts exist before upload attempts
- **macOS-only features**: iOS builds/uploads wrapped in `Platform.isMacOS` checks  
- **Shell command escaping**: Use single quotes for file paths with spaces in `_runCommand()`
- **Config validation**: GCloud requires both bucket + app_id; Discord needs webhook_url minimum
- **Lint errors**: Always run `fvm dart analyze` after changes - many issues are caught here before testing

## Future Architecture (Per docs/PLAN.md)
Next phases will abstract `Builder` interface and introduce Firebase App Distribution, Fastlane integration, and flexible distribution strategies via enhanced YAML configuration.
