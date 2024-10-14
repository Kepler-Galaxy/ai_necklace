import 'package:foxxy_package/backend/schema/transcript_segment.dart';
import 'package:foxxy_package/backend/http/webhooks.dart';
import 'package:foxxy_package/backend/schema/message.dart';
import 'package:foxxy_package/services/notification_service.dart';

triggerTranscriptSegmentReceivedEvents(
  List<TranscriptSegment> segments,
  String sessionId, {
  Function(ServerMessage)? sendMessageToChat,
}) async {
  webhookOnTranscriptReceivedCall(segments, sessionId).then((s) {
    if (s.isNotEmpty)
      NotificationService.instance.createNotification(
          title: 'Developer: On Transcript Received',
          body: s,
          notificationId: 10);
  });
  // TODO: restore me, how to trigger from backend
}
