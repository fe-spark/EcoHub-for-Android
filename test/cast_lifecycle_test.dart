import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ecohub_android/components/cast/player_cast_controller.dart';
import 'package:ecohub_android/components/cast/player_cast_sheet.dart';
import 'package:ecohub_android/components/player/player_playback_controller.dart';
import 'package:ecohub_android/components/player/video_player_widget.dart';
import 'package:ecohub_android/services/cast_session.dart';
import 'package:ecohub_android/services/dlna_client.dart';
import 'package:ecohub_android/types/dlna_types.dart';

class FakeDlnaClient extends DlnaClient {
  int discoverCalls = 0;
  int cancelCalls = 0;
  Completer<List<DlnaDevice>>? pendingCompleter;

  @override
  Future<List<DlnaDevice>> discover({void Function(List<DlnaDevice>)? onUpdate}) {
    discoverCalls++;
    final completer = Completer<List<DlnaDevice>>();
    pendingCompleter = completer;
    return completer.future;
  }

  @override
  void cancelDiscover() {
    cancelCalls++;
  }
}

class MockPlayerCastHost implements PlayerCastHost {
  double currentPos = 25.0;
  double totalDur = 120.0;
  bool playing = true;
  bool opening = false;
  bool buffering = false;
  String url = 'https://example.com/video1.mp4';
  String mediaTitle = '测试影片 第1集';
  bool hasNextEpisode = true;
  double vol = 0.75;
  bool fullscreen = false;

  bool parkLocalCalled = false;
  bool pauseLocalCalled = false;
  double? resumeTargetSec;
  bool? resumeWasPlaying;
  double? completedPosSec;
  double? completedDurSec;
  bool exitFullCalled = false;
  bool onCastEndedCalled = false;
  bool syncUiCalled = false;
  double? lastSyncCur;
  double? lastSyncDur;
  String? lastToast;
  bool? autoPipEnabled;
  bool stopPipCalled = false;

  @override
  double get currentPosition => currentPos;
  @override
  double get totalDuration => totalDur;
  @override
  bool get isPlaying => playing;
  @override
  bool get isOpening => opening;
  @override
  bool get isBuffering => buffering;
  @override
  String get videoUrl => url;
  @override
  String get title => mediaTitle;
  @override
  bool get hasNext => hasNextEpisode;
  @override
  double get volume => vol;
  @override
  bool get isFull => fullscreen;

  @override
  void parkLocal() {
    parkLocalCalled = true;
  }

  @override
  void pauseLocal() {
    pauseLocalCalled = true;
  }

  @override
  void resumeLocal(double targetSec, bool wasPlaying) {
    resumeTargetSec = targetSec;
    resumeWasPlaying = wasPlaying;
  }

  @override
  void remountCompleted(double positionSec, double durationSec) {
    completedPosSec = positionSec;
    completedDurSec = durationSec;
  }

  @override
  void exitFullForCast() {
    exitFullCalled = true;
  }

  @override
  void onCastEnded() {
    onCastEndedCalled = true;
  }

  @override
  void syncUi() {
    syncUiCalled = true;
  }

  @override
  void syncProgress(double currentSec, double durationSec) {
    lastSyncCur = currentSec;
    lastSyncDur = durationSec;
  }

  @override
  void showToast(String message) {
    lastToast = message;
  }

  @override
  void setPipAutoStart(bool enable) {
    autoPipEnabled = enable;
  }

  @override
  void stopPip() {
    stopPipCalled = true;
  }
}
