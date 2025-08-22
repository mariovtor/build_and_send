library build_and_send;

abstract class Builder {
  Future<BuildResult> build(BuildContext context);
}

class BuildContext {
  final String? flavorName;
  final String platform;
  final String buildArgs;
  final bool onlyUpload;
  final bool noPodSync;

  BuildContext({
    required this.flavorName,
    required this.platform,
    required this.buildArgs,
    this.onlyUpload = false,
    this.noPodSync = true,
  });
}

class BuildResult {
  final bool success;
  final String? error;
  final Map<String, dynamic>? metadata;

  BuildResult({
    required this.success,
    this.error,
    this.metadata,
  });

  factory BuildResult.success({Map<String, dynamic>? metadata}) {
    return BuildResult(success: true, metadata: metadata);
  }

  factory BuildResult.failure(String error) {
    return BuildResult(success: false, error: error);
  }
}
