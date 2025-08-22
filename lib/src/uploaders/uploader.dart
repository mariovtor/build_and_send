library build_and_send;

abstract class Uploader {
  Future<String> upload(UploadContext context);
}

class UploadContext {
  final String filePath;
  final String fileName;

  UploadContext({
    required this.filePath,
    required this.fileName,
  });
}
