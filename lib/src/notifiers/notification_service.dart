library build_and_send;

import '../build_config.dart';
import 'discord_notifier.dart';
import 'notifier.dart';

class NotificationService {
  static Notifier? create(BuildConfig config) {
    if (config.discord != null) {
      return DiscordNotifier(config.discord!);
    }
    // In the future, we can add more notifiers here.
    // For example:
    // if (config.slack != null) {
    //   return SlackNotifier(config.slack!);
    // }
    return null;
  }
}
