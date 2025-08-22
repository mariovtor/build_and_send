library build_and_send;

import 'package:build_and_send/src/build_config.dart';
import 'package:build_and_send/src/uploaders/gcloud_uploader.dart';
import 'package:build_and_send/src/uploaders/uploader.dart';

class UploadService {
  static Uploader? create({
    required BuildConfig config,
    required String uploadAccount,
    required bool verbose,
  }) {
    if (config.android.gcloud != null) {
      return GCloudUploader(
        gcloudConfig: config.android.gcloud!,
        uploadAccount: uploadAccount,
        verbose: verbose,
      );
    }
    // In the future, we can add more uploaders here (e.g., TestFlightUploader, FirebaseUploader).
    return null;
  }
}
