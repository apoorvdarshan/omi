part of 'page.dart';

/// The live capture page as a native reader. Capture, WAL upload, speaker labels, the name-speaker
/// sheet and the photo viewer keep their existing owners; only text, times and counts cross the
/// bridge, never audio or photo bytes. A refused snapshot keeps the complete classic page.
extension _NativeConversationCapturing on _ConversationCapturingPageState {
  Widget _buildNativeCapture(
    CaptureProvider provider,
    DeviceProvider deviceProvider, {
    required Widget fallback,
    required String title,
    required String emptyText,
  }) {
    final wedge = CaptureWedgeMonitor.instance;
    return ListenableBuilder(
      listenable: wedge,
      builder: (context, _) {
        final l10n = context.l10n;
        final timeline = _nativeTimeline(provider);
        final latestId = timeline.isEmpty ? null : timeline.last.id;
        final effectivelyMuted = provider.isPaused || provider.isCallActive;
        final showControls =
            provider.liveCaptureSource != null || provider.segments.isNotEmpty || provider.photos.isNotEmpty;
        return IosNativeSurface(
          title: title,
          fallback: fallback,
          // A reader shows no empty copy of its own; the timeline carries it as a row below.
          empty: emptyText,
          toolbar: [
            NativeRow('capture_back', l10n.back,
                symbol: 'chevron.left', action: (_) => Navigator.of(context).maybePop()),
          ],
          sections: [
            NativeSection('capture_status', _nativeStatusRows(provider, wedge)),
            NativeSection('capture_timeline', [
              ...timeline,
              if (timeline.isEmpty && emptyText.isNotEmpty) NativeRow('capture_empty', emptyText, kind: 'label'),
            ]),
          ],
          reader: NativeReader(
            targetId: latestId,
            request: provider.segmentsPhotosVersion + _readerJumps,
            following: _readerFollowing,
            footer: [
              if (latestId != null && !_readerFollowing)
                NativeRow('capture_latest', l10n.jumpToLatestMessage,
                    symbol: 'arrow.down',
                    action: (_) => _nativeRebuild(() {
                          _readerFollowing = true;
                          _readerJumps++;
                        })),
              // Pause/Resume and Finish, the one stop, as on the classic page.
              if (showControls) ...[
                if (provider.liveCaptureSource != null &&
                    LiveCaptureCard.canPause(provider.recordingDevice, source: provider.liveCaptureSource))
                  NativeRow('capture_pause', effectivelyMuted ? l10n.resume : l10n.pause,
                      symbol: effectivelyMuted ? 'play.fill' : 'pause.fill',
                      enabled: !_mutePending && !provider.isCallActive,
                      action: (_) => _toggleMute(provider)),
                NativeRow('capture_finish', l10n.finish,
                    symbol: 'checkmark', enabled: !_nativeFinishing, action: (_) => _finishNatively(provider)),
              ],
            ],
            scroll: latestId == null
                ? null
                : NativeRow('capture_reader_scroll', l10n.transcript,
                    kind: 'menu',
                    options: {'suspend': l10n.transcript, latestId: l10n.jumpToLatestMessage}, action: (value) {
                    // A drag stops following; reaching the newest line again resumes it.
                    final following = value != 'suspend';
                    if (following != _readerFollowing) _nativeRebuild(() => _readerFollowing = following);
                  }),
          ),
        );
      },
    );
  }

  /// Finish runs once per tap, even when the native command repeats while the owner finishes.
  Future<void> _finishNatively(CaptureProvider provider) async {
    if (_nativeFinishing) return;
    _nativeRebuild(() => _nativeFinishing = true);
    try {
      await _stopConversation(provider);
    } finally {
      if (mounted) _nativeRebuild(() => _nativeFinishing = false);
    }
  }

  /// The recovery prompt, the unsynced-audio indicator and the carried-speaker note, as the classic
  /// page shows them above the transcript.
  List<NativeRow> _nativeStatusRows(CaptureProvider provider, CaptureWedgeMonitor wedge) {
    final l10n = context.l10n;
    final episode = wedge.visiblePrompt;
    final wal = _unsyncedWalStatus(provider);
    final carried = _carriedSpeaker(provider);
    return [
      if (episode != null)
        NativeRow('capture_recovery', captureRecoveryText(l10n, episode),
            symbol: 'exclamationmark.triangle',
            onVisible: (_) => wedge.markPromptShown(),
            action: (_) {
              wedge.markPromptShown();
              return actOnCaptureRecovery(wedge, episode);
            }),
      if (wal != null) ...[
        NativeRow('capture_wal', wal.text,
            kind: 'label',
            subtitle: wal.backlog ?? '',
            symbol: wal.failed
                ? 'exclamationmark.icloud'
                : wal.retrying
                    ? 'arrow.clockwise.icloud'
                    : wal.uploading
                        ? 'icloud.and.arrow.up'
                        : 'internaldrive'),
        if (wal.retryable)
          NativeRow('capture_wal_retry', l10n.retry,
              symbol: 'arrow.clockwise', action: (_) => provider.retryFailedSessionWalUploads()),
      ],
      if (carried != null) ...[
        NativeRow('capture_carried', l10n.speakerLabelText('carried', carried.person.name),
            kind: 'label', symbol: 'arrow.uturn.forward'),
        NativeRow('capture_carried_change', l10n.speakerLabelText('change', ''),
            action: (_) => _editSegmentSpeaker(carried.segment, provider)),
        NativeRow('capture_carried_close', l10n.close,
            symbol: 'xmark', action: (_) => _nativeRebuild(() => _closedCarriedSpeakers.add(carried.key))),
      ],
    ];
  }

  /// Photo groups, then the transcript, in the classic timeline's order. Photo rows carry only their
  /// time and count; the existing viewer loads the images.
  List<NativeRow> _nativeTimeline(CaptureProvider provider) {
    final l10n = context.l10n;
    final dates = OmiDateFormat.of(context);
    final people = context.watch<PeopleProvider?>()?.people ?? SharedPreferencesUtil().cachedPeople;
    final segments = provider.segments;
    final names = SpeakerNames.forSegments(segments, people: people, l10n: l10n);
    final photos = List<ConversationPhoto>.from(provider.photos)..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    final photoTimeline = photos.isNotEmpty;
    final conversationId = widget.topConversationId ?? provider.topConversationId;
    final groups = groupCapturePhotos(photos);
    return [
      for (var index = 0; index < groups.length; index++)
        NativeRow(
          'capture_photos:$index',
          groups[index].length > 1
              ? '${dates.time(groups[index].first.createdAt)} · ${l10n.conversationPhotosCount(groups[index].length)}'
              : dates.time(groups[index].first.createdAt),
          kind: 'navigation',
          symbol: 'camera',
          action: (_) => _openPhotoViewer(photos, photos.indexOf(groups[index].first), conversationId),
        ),
      for (var index = 0; index < segments.length; index++)
        _nativeSegmentRow(provider, segments[index], index, people, names, photoTimeline: photoTimeline),
    ];
  }

  NativeRow _nativeSegmentRow(
    CaptureProvider provider,
    TranscriptSegment segment,
    int index,
    List<Person> people,
    SpeakerNames names, {
    required bool photoTimeline,
  }) {
    final l10n = context.l10n;
    final person = personById(people, segment.personId);
    final suggested = _pinnedSuggestion(segment, provider, people);
    // The transcript list names every speaker but Omi; the photo timeline names every line.
    final canIdentify = photoTimeline || segment.isUser || segment.speakerId != omiSpeakerId;
    final likely = person != null && segment.speakerLabelSource == SpeakerLabelSource.auto;
    final segmentId = segment.id;
    return NativeRow(
      'capture_segment:$index',
      [
        tryDecodingText(segment.text),
        for (final translation in segment.translations) tryDecodingText(translation.text),
      ].join('\n'),
      kind: 'transcript',
      subtitle: [
        names.forSegment(segment, person: person),
        if (likely) l10n.speakerLabelText('likely', ''),
        OmiDuration.offset(segment.start),
        if (suggested != null) l10n.speakerSuggestionChip(suggested.name),
      ].join(' · '),
      options: {
        if (canIdentify) 'identify': l10n.identifySpeaker,
        if (suggested != null) ...{
          'suggestion_accept': l10n.yes,
          'suggestion_reject': l10n.speakerTagPromptSomeoneElse,
        },
      },
      // A line whose speaker is being saved waits for that answer.
      enabled: !provider.taggingSegmentIds.contains(segmentId),
      action: !canIdentify && suggested == null
          ? null
          : (value) {
              final current = provider.segments.where((item) => item.id == segmentId).firstOrNull;
              if (current == null) return null;
              if (value == 'suggestion_accept' || value == 'suggestion_reject') {
                final people = Provider.of<PeopleProvider?>(context, listen: false)?.people ??
                    SharedPreferencesUtil().cachedPeople;
                final person = _pinnedSuggestion(current, provider, people);
                if (person == null) return null;
                return value == 'suggestion_accept'
                    ? _acceptSuggestion(current, person, provider)
                    : _rejectSuggestion(current, person, provider);
              }
              if (!canIdentify) return null;
              _nameSpeaker(current.id, current.speakerId, provider);
              if (!photoTimeline) PlatformManager.instance.analytics.tagSheetOpened();
              return null;
            },
    );
  }
}
