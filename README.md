# Build and Send

A Dart package for building artifacts, upload and sending them.

## Features

- Build APK and app bundles
- Upload to Google Cloud Storage
- Build iOS IPA
- Upload IPA to TestFlight
- Send notifications to Discord

## Installation

Add `build_and_send` to your `pubspec.yaml` in the `dev_dependencies` section.:

```yaml
dependencies:
  ansi: ^0.4.2
  args: ^2.5.0
  http: '>=0.13.5 <2.0.0'
  yaml: ^3.1.2
  ```

## Usage
in your project folder, same where configuration files are, run the following command in terminal:

```shell
dart run build_and_send
```

### Options
- `-p, --platform` : Platform to build. Can be either android, ios or all. Default is all.
- `-f, --flavor` : Flavor to build.
- `-s, --silent` : Silent mode. Won't send any notification to discord even if configured.
- `-m, --mention`: Mention specific users in discord when sending notification. Provide comma separated names. If not provided, all users configured will be mentioned. see build_config.yaml, example for mentionUsers [command -m user1,user2], in .yaml file mentionUsers: user1:1234567890,user2:0987654321.
- `-n, --no-mention`: Don't mention any user in discord when sending notification. If not provided, all users configured will be mentioned.
- `--no-pod-sync'`: If you are having some issues with ios build, you can try manually sync pod files. This flag will skip pod install step.
- `-v, --verbose` : Verbose mode. Will print more information.
- `-h, --help` : Display help information.


## Configuration
Create a build_config.yaml. This file contains the configuration for the build and send process.

### Example
```yaml
build:
  #fvm, shorebird, default
  method: default
  android:
    #optional, if you need to pass any arguments to build command, like using a specific -t target, or shorebird configuration
    # like --flutter-version or any other stuff
    build_args: null
    #optional
    apk_path: null
    #optional
    bundle_path: null
    #if cloud not given will only build
    gcloud:
      bucket: flavor1-bucket
      app_id: flavor1-app-id
  ios:
    #optional, if you need to pass any arguments to build command, like using a specific -t target, or shorebird configuration like --flutter-version or any other stuff
    build_args: 
    #if not given will only build the ipa file, will search in build/ios/ipa
    ipa_name: null
  #optional
  flavors:
    #by using a default if you call the package build function, will use the according flavor, the value must be a valid flavor name
    default_build: null
    dev:
      #fvm, shorebird, default
      method: default
      android:
        #to pass flavor flags and all stuffs, dont need to pass --flavor dev because its implicit
        build_args: -t lib/main_dev.dart
        #required  generaly flavors change build file name
        apk_name: 
        #optional
        apk_path: null
        #generaly flavors change build file name
        bundle_name:
        #optional
        bundle_path: null
        #if you want to use custom email put in build.env archive DEV_ANDROID_EMAIL, this email must to have access to this gcloud
        #if cloud not given will only build
        gcloud:
          bucket: flavor1-bucket
          app_id: flavor1-app-id

      ios:
        #to pass flavor flags and all stuffs, dont need to pass --flavor dev because its implicit
        build_args: -t lib/main_dev.dart
        #if not given will only build the ipa file, will search in build/ios/ipa
        ipa_name: null
    #optional, if given will send a message with android uploaded link
    discord:
      #required
      webhook_url: YOUR_DISCORD_WEBHOOK_URL
      #optional, will tag the channel in the message
      channel_id: YOUR_DISCORD_CHANNEL_ID
      #optional
      mention_users: user1:123456789012345678,user2:987654321098765432
      #default true
      show_version: true
      #default true
      show_flavor: true
```

##
### Create a  build.env file in the root of your project

**Remember to add the `build.env` file to your `.gitignore` to prevent sensitive information from being committed to your repository.**

```env
ACCOUNT_EMAIL=upload.to.gc@example.com
FLAVOR1_UPLOAD_EMAIL=flavor1.permissions@example.com
APPLE_EMAIL=your_apple@mail.com
APPLE_APP_SPECIFIC_PASSWORD=your_app_specific_password
#remove if you dont want to use discord
DISCORD_SENDER_ID=000000000000000
```

## Contributing

Any suggestions, issues, pull requests are welcomed.

## License

[MIT](https://github.com/ScerIO/icon_font_generator/blob/master/LICENSE)

## Credits

* [mariovtor](https://github.com/westracer/fontify)