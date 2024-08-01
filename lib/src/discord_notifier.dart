library build_and_send;

import 'package:build_and_send/src/console_printer.dart';
import 'package:http/http.dart' as http;
import 'build_config.dart';

///
/// Class to send notifications to discord
/// This class will send notifications to discord
/// using the provided configuration
///   - config: Configuration for discord
///   - notify: Send notification to discord
///  - generateMessage: Generate message to send to discord
///
class DiscordNotifier {
  final DiscordConfig config;

  DiscordNotifier(this.config);

  /// Send notification to discord
  /// This method will send a notification to discord
  /// with the provided message
  ///  - message: Message to send
  /// - mention: Whether to mention users or not
  /// - mentionNames: Names of the users to mention
  /// Returns a future
  /// Throws an error if the notification fails
  Future<void> notify(String message,
      {bool mention = true, List<String>? mentionNames}) async {
    var payload = {'content': message.toString()};

    if (mention && config.mentionUsers != null) {
      var mentions = [];
      if (mentionNames != null) {
        for (var name in mentionNames) {
          if (config.mentionUsers!.containsKey(name)) {
            mentions.add('<@${config.mentionUsers![name]}>');
          }
        }
      } else {
        mentions = config.mentionUsers!.values.map((id) => '<@$id>').toList();
      }
      payload['content'] = '${payload['content'] ?? ''} ${mentions.join(' ')}';
    }
    var response = await http.post(
      Uri.parse(config.webhookUrl),
      // headers: {'Content-Type': 'application/json'},
      body: payload,
    );

    if (response.statusCode != 204) {
      ConsolePrinter.writeError(
          'Failed to send notification: ${response.body}');
    } else {
      ConsolePrinter.writeGreen('Notification sent successfully');
    }
  }

  /// Generate message to send to discord
  /// This method will generate a message to send to discord
  /// based on the configuration and the build details
  ///   - flavorName: Name of the flavor
  ///  - version: Version of the build
  /// - apkUrl: URL of the APK
  /// - bundleUrl: URL of the bundle
  /// - sender: User who built the app
  /// - uploadedIpa: Whether the IPA was uploaded
  /// - customText: Custom text to send in the message
  /// Returns the generated message
  String generateMessage({
    required String? flavorName,
    required String version,
    required String? apkUrl,
    required String? bundleUrl,
    required String sender,
    required bool uploadedIpa,
    String? customText,
  }) {
    var message = '';
    if (config.channelId?.isNotEmpty == true) {
      message += '<#${config.channelId}> \n';
    }
    message += '**Version: $version**\n';

    if (flavorName != null) {
      message += '**Build: $flavorName**\n';
    }

    if (apkUrl?.isNotEmpty == true) {
      message += '\nAPK Link: $apkUrl\n';
    }

    if (bundleUrl?.isNotEmpty == true) {
      message += 'Bundle Link: $bundleUrl\n';
    }

    if (uploadedIpa) {
      message += 'IPA uploaded\n';
    }

    if (sender.contains('@')) {
      message += 'Built by: $sender\n\n';
    } else if (sender.isNotEmpty) {
      message += 'Built by: <@$sender>\n\n';
    }
    if (customText?.isNotEmpty == true) {
      message += '${customText!}\n\n';
    }
    return message;
  }
}
