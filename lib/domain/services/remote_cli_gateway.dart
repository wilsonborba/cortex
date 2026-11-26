import '../models/api.dart';
import '../models/remote_cli.dart';

/// Transport boundary for the Android remote-control screens.
abstract interface class RemoteCliGateway {
  Future<List<RemoteCliSession>> sessions();

  Stream<RemoteCliEvent> events(String sessionId, {required int after});

  Future<int?> sendPrompt(
    String sessionId,
    String prompt, {
    List<String> fileIds = const [],
  });

  Future<void> answerApproval(
    String sessionId,
    String approvalId, {
    required bool approved,
  });

  Future<void> cancel(String sessionId, {String? turnId});

  /// Uploads only a file explicitly selected by the user through `/files`.
  Future<String> uploadImage({
    required String name,
    required List<int> bytes,
    required String contentType,
  });

  Future<DownloadedFileContent> artifactImage(String fileId);
}
