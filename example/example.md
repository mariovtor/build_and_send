# Build and Send Examples

## Configuration Files

### build_config.yaml
Check `build_config.yaml` file to see the configuration.

### build.env  
Check `build.env` file to see the configuration.

## Usage Examples

### Basic Commands
```bash
# Build all platforms with default flavor
dart run build_and_send

# Build Android only with verbose logging
dart run build_and_send -p android -v

# Build specific flavor with Discord notifications
dart run build_and_send -f dev -p android

# Upload only mode (skip build)
dart run build_and_send --only-upload -p android -v
```

### Verbose Mode Examples

For debugging or understanding the build process, use the `-v` flag for comprehensive logging:

```bash
# Debug Android build process
dart run build_and_send -p android -f dev -v

# See all configuration and upload steps  
dart run build_and_send -p all -v

# Debug upload issues with detailed logging
dart run build_and_send --only-upload -v
```

The verbose output provides:
- **Section boundaries** showing each phase of execution
- **Configuration details** displaying all build parameters  
- **Step tracking** with visual progress indicators
- **Command visibility** showing exact shell commands executed
- **Debug information** for troubleshooting issues