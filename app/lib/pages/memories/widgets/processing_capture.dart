import 'package:flutter/material.dart';
import 'package:foxxy_package/backend/preferences.dart';
import 'package:foxxy_package/backend/schema/bt_device.dart';
import 'package:foxxy_package/backend/schema/memory.dart';
import 'package:foxxy_package/pages/memories/widgets/capture.dart';
import 'package:foxxy_package/pages/memory_capturing/page.dart';
import 'package:foxxy_package/providers/capture_provider.dart';
import 'package:foxxy_package/providers/connectivity_provider.dart';
import 'package:foxxy_package/providers/device_provider.dart';
import 'package:foxxy_package/utils/analytics/mixpanel.dart';
import 'package:foxxy_package/utils/enums.dart';
import 'package:foxxy_package/utils/other/temp.dart';
import 'package:foxxy_package/widgets/dialog.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:foxxy_package/generated/l10n.dart';
import 'package:foxxy_package/pages/memories/widgets/language_setting.dart';

class MemoryCaptureWidget extends StatefulWidget {
  final ServerProcessingMemory? memory;

  const MemoryCaptureWidget({
    super.key,
    required this.memory,
  });

  @override
  State<MemoryCaptureWidget> createState() => _MemoryCaptureWidgetState();
}

class _MemoryCaptureWidgetState extends State<MemoryCaptureWidget> {
  @override
  Widget build(BuildContext context) {
    return Consumer3<CaptureProvider, DeviceProvider, ConnectivityProvider>(
        builder:
            (context, provider, deviceProvider, connectivityProvider, child) {
      var topMemoryId = (provider.memoryProvider?.memories ?? []).isNotEmpty
          ? provider.memoryProvider!.memories.first.id
          : null;

      bool showPhoneMic = deviceProvider.connectedDevice == null &&
          !deviceProvider.isConnecting;
      bool isConnected = deviceProvider.connectedDevice != null ||
          provider.recordingState == RecordingState.record ||
          (provider.memoryCreating && deviceProvider.connectedDevice != null);

      return (showPhoneMic || isConnected || deviceProvider.isConnecting)
          ? GestureDetector(
              onTap: () async {
                if (provider.segments.isEmpty && provider.photos.isEmpty)
                  return;
                routeToPage(
                    context, MemoryCapturingPage(topMemoryId: topMemoryId));
              },
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                width: double.maxFinite,
                decoration: BoxDecoration(
                  color: Colors.grey.shade900,
                  borderRadius: BorderRadius.circular(16.0),
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _getMemoryHeader(context),
                      provider.segments.isNotEmpty
                          ? const Column(
                              children: [
                                SizedBox(height: 8),
                                LiteCaptureWidget(),
                                SizedBox(height: 8),
                              ],
                            )
                          : const SizedBox.shrink(),
                    ],
                  ),
                ),
              ),
            )
          : const SizedBox.shrink();
    });
  }

  _toggleRecording(BuildContext context, CaptureProvider provider) async {
    var recordingState = provider.recordingState;
    if (recordingState == RecordingState.record) {
      await provider.stopStreamRecording();
      context.read<CaptureProvider>().cancelMemoryCreationTimer();
      await context.read<CaptureProvider>().createMemory();
      MixpanelManager().phoneMicRecordingStopped();
    } else if (recordingState == RecordingState.initialising) {
      debugPrint('initialising, have to wait');
    } else {
      showDialog(
        context: context,
        builder: (c) => getDialog(
          context,
          () => Navigator.pop(context),
          () async {
            Navigator.pop(context);
            provider.updateRecordingState(RecordingState.initialising);
            await provider.changeAudioRecordProfile(BleAudioCodec.pcm16, 16000);
            await provider.streamRecording();
            MixpanelManager().phoneMicRecordingStarted();
          },
          S.current.LimitedCapabilities,
          S.current.DescriptionOfRecordingWithPhoneMicrophone,
          okButtonText: S.current.OkIUnderstand,
        ),
      );
    }
  }

  _getMemoryHeader(BuildContext context) {
    // Connected device
    var deviceProvider = context.read<DeviceProvider>();

    // State
    var stateText = "";
    var captureProvider = context.read<CaptureProvider>();
    var connectivityProvider = context.read<ConnectivityProvider>();
    bool isConnected = false;
    if (deviceProvider.connectedDevice == null) {
      stateText = "No device paired";
      isConnected = false;
    } else if (!connectivityProvider.isConnected) {
      stateText = "No connection";
    } else if (deviceProvider.isConnecting) {
      stateText = "Connecting...";
      isConnected = false;
    } else if (captureProvider.memoryCreating) {
      stateText = "Processing";
      isConnected = deviceProvider.connectedDevice != null;
    } else if (captureProvider.recordingDeviceServiceReady &&
        captureProvider.transcriptServiceReady) {
      stateText = "Listening";
      isConnected = true;
    } else if (captureProvider.recordingDeviceServiceReady ||
        captureProvider.transcriptServiceReady) {
      stateText = "Preparing";
      isConnected = true;
    }

    var isUsingPhoneMic =
        captureProvider.recordingState == RecordingState.record ||
            captureProvider.recordingState == RecordingState.initialising ||
            captureProvider.recordingState == RecordingState.pause;

    return Padding(
      padding: const EdgeInsets.only(left: 0, right: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (deviceProvider.connectedDevice == null &&
              !deviceProvider.isConnecting)
            getPhoneMicRecordingButton(
              context,
              () => _toggleRecording(context, captureProvider),
              captureProvider.recordingState,
            )
          else if (isConnected && !isUsingPhoneMic)
            Row(
              children: [
                const Text(
                  '🎙️',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 12),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade800,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Text(
                    captureProvider.segments.isNotEmpty ||
                            captureProvider.photos.isNotEmpty
                        ? 'In progress...'
                        : 'Say something...',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium!
                        .copyWith(color: Colors.white),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          // if (isConnected && !isUsingPhoneMic)
          // if(deviceProvider.isConnecting || connectivityProvider.isConnected)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 16,
                height: 16,
                child: RecordingStatusIndicator(),
              ),
              const SizedBox(width: 8),
              Text(
                stateText,
                style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                maxLines: 1,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class RecordingStatusIndicator extends StatefulWidget {
  const RecordingStatusIndicator({super.key});

  @override
  _RecordingStatusIndicatorState createState() =>
      _RecordingStatusIndicatorState();
}

class _RecordingStatusIndicatorState extends State<RecordingStatusIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000), // Blink every half second
      vsync: this,
    )..repeat(reverse: true);
    _opacityAnim = Tween<double>(begin: 1.0, end: 0.2).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacityAnim,
      child:
          const Icon(Icons.fiber_manual_record, color: Colors.red, size: 16.0),
    );
  }
}

getPhoneMicRecordingButton(
    BuildContext context, toggleRecording, RecordingState state) {
  if (SharedPreferencesUtil().btDeviceStruct.id.isNotEmpty)
    return const SizedBox.shrink();
  return MaterialButton(
    onPressed: state == RecordingState.initialising ? null : toggleRecording,
    child: Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        state == RecordingState.initialising
            ? const SizedBox(
                height: 8,
                width: 8,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : (state == RecordingState.record
                ? const Icon(Icons.stop, color: Colors.red, size: 12)
                : const Icon(Icons.mic, size: 18)),
        const SizedBox(width: 4),
        Text(
          state == RecordingState.initialising
              ? 'Initialising Recorder'
              : (state == RecordingState.record
                  ? S.current.StopRecording
                  : S.current.TryWithPhoneMic),
          style: Theme.of(context)
              .textTheme
              .bodyMedium!
              .copyWith(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        const SizedBox(width: 4),
      ],
    ),
  );
}

Widget getMemoryCaptureWidget({ServerProcessingMemory? memory}) {
  return Consumer<CaptureProvider>(
    builder: (context, provider, child) {
      return Column(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            width: double.maxFinite,
            decoration: BoxDecoration(
              color: Colors.grey.shade900,
              borderRadius: BorderRadius.circular(16.0),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LanguageSettingWidget(),
                  MemoryCaptureWidget(memory: memory),
                ],
              ),
            ),
          ),
        ],
      );
    },
  );
}
