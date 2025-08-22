library build_and_send;

abstract class Notifier {
  Future<void> notify(NotificationContext context);
}

class NotificationContext {
  final String? flavorName;
  final String version;
  final String? apkUrl;
  final String? bundleUrl;
  final String sender;
  final bool uploadedIpa;
  final String? customText;
  final bool mention;
  final List<String>? mentionNames;

  NotificationContext({
    required this.flavorName,
    required this.version,
    required this.apkUrl,
    required this.bundleUrl,
    required this.sender,
    required this.uploadedIpa,
    this.customText,
    this.mention = true,
    this.mentionNames,
  });
}
