library build_and_send;

import 'package:http/http.dart' as http;

import '../build_config.dart';
import '../console_printer.dart';
import '../logger.dart';
import 'notifier.dart';

class DiscordNotifier implements Notifier {
  final DiscordConfig config;

  DiscordNotifier(this.config);

  @override
  Future<void> notify(NotificationContext context) async {
    Logger.startSection('Discord Notification');
    Logger.debug('Webhook URL configured: ${config.webhookUrl.isNotEmpty}');
    Logger.debug('Channel ID: ${config.channelId}');
    Logger.debug('Version: ${context.version}');
    Logger.debug('Mention enabled: ${context.mention}');

    Logger.step('Generating notification message');
    final message = _generateMessage(context);
    Logger.debug('Generated message: $message');

    var payload = {'content': message.toString()};

    if (context.mention && config.mentionUsers != null) {
      Logger.step('Processing user mentions');
      var mentions = <String>[];
      if (context.mentionNames != null) {
        Logger.debug('Mentioning specific users: ${context.mentionNames}');
        for (var name in context.mentionNames!) {
          if (config.mentionUsers!.containsKey(name)) {
            mentions.add('<@${config.mentionUsers![name]}>');
          }
        }
      } else {
        Logger.debug('Mentioning all configured users');
        mentions = config.mentionUsers!.values.map((id) => '<@$id>').toList();
      }
      payload['content'] = '${payload['content'] ?? ''} ${mentions.join(' ')}';
      Logger.debug('Final payload with mentions: ${payload['content']}');
    }

    Logger.step('Sending notification to Discord');
    Logger.debug('Webhook URL: ${config.webhookUrl}');
    var response = await http.post(
      Uri.parse(config.webhookUrl),
      body: payload,
    );

    if (response.statusCode != 204) {
      Logger.error('Failed to send Discord notification: ${response.body}');
      ConsolePrinter.writeError(
          'Failed to send notification to Discord: ${response.body}');
    } else {
      Logger.success('Discord notification sent successfully');
      ConsolePrinter.writeGreen('Notification sent successfully to Discord');
    }

    Logger.endSection();
  }

  String _generateMessage(NotificationContext context) {
    var message = '';
    if (config.channelId?.isNotEmpty == true) {
      message += '<#${config.channelId}> \n';
    }
    message += '**Version: ${context.version}**\n';

    if (context.flavorName != null) {
      message += '**Build: ${context.flavorName}**\n';
    }

    if (context.apkUrl?.isNotEmpty == true) {
      message += '\nAPK Link: ${context.apkUrl}\n';
    }

    if (context.bundleUrl?.isNotEmpty == true) {
      message += 'Bundle Link: ${context.bundleUrl}\n';
    }

    if (context.uploadedIpa) {
      message += 'IPA uploaded\n';
    }

    if (context.sender.contains('@')) {
      message += 'Built by: ${context.sender}\n\n';
    } else if (context.sender.isNotEmpty) {
      message += 'Built by: <@${context.sender}>\n\n';
    }
    if (context.customText?.isNotEmpty == true) {
      message += '${context.customText!}\n\n';
    }
    return message;
  }
}
