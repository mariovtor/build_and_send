library build_and_send;

import 'package:build_and_send/src/console_printer.dart';
import 'package:http/http.dart' as http;
import 'build_config.dart';

class DiscordNotifier {
  final DiscordConfig config;

  DiscordNotifier(this.config);

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

  static String generateMessage({
    required String? flavorName,
    required String version,
    required String? apkUrl,
    required String? bundleUrl,
    required String sender,
    required String? discordChannel,
    required bool uploadedIpa,
    String? customText,
  }) {
    var message = '';
    if (discordChannel?.isNotEmpty == true) {
      message += '<#$discordChannel> \n';
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
