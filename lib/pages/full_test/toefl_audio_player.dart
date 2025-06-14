import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:toefl/utils/utils.dart';

import '../../utils/colors.dart';
import '../../utils/custom_text_style.dart';
import '../../utils/hex_color.dart';
import '../../widgets/blue_container.dart';

class ToeflAudioPlayer extends StatefulWidget {
  const ToeflAudioPlayer({
    super.key,
    required this.url,
  });

  final String url;

  @override
  State<ToeflAudioPlayer> createState() => _ToeflAudioPlayerState();
}

class _ToeflAudioPlayerState extends State<ToeflAudioPlayer> {
  final AudioPlayer _player = AudioPlayer();

  // Persistence across rebuilds: URLs that have completed
  static final Set<String> _completedUrls = {};

  bool _hasPlayed = false;
  bool _isCompleted = false;

  Duration position = Duration.zero;
  Duration duration = Duration.zero;

  @override
  void initState() {
    super.initState();

    // If this URL has completed before, mark flags
    if (_completedUrls.contains(widget.url)) {
      _hasPlayed = true;
      _isCompleted = true;
    }

    // Listen to position updates
    _player.positionStream.listen((pos) {
      setState(() => position = pos);
    });

    // Listen to duration updates
    _player.durationStream.listen((dur) {
      if (dur != null) setState(() => duration = dur);
    });

    // Listen to completion
    _player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        setState(() {
          _isCompleted = true;
          _completedUrls.add(widget.url);
        });
      }
    });
  }

  Future<void> handlePlay() async {
    // Ignore if already played or completed
    if (_hasPlayed || _isCompleted) return;

    // Immediately mark as played so icon updates
    setState(() {
      _hasPlayed = true;
    });

    try {
      await _player.setUrl(widget.url);
      await _player.play();
    } catch (e) {
      debugPrint("Error playing audio: \$e");
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final iconSize = screenWidth * 0.08;
    final fontSize = screenWidth * 0.04;

    IconData icon;
    if (_isCompleted) {
      icon = Icons.check_rounded;
    } else if (_hasPlayed) {
      icon = Icons.pause_rounded;
    } else {
      icon = Icons.play_arrow_rounded;
    }

    return BlueContainer(
      innerShadow: true,
      color: mariner200,
      padding: 8.0,
      width: screenWidth,
      child: Row(
        children: [
          GestureDetector(
            // Disable tap after first play or completion
            onTap: (_hasPlayed || _isCompleted) ? null : handlePlay,
            child: Icon(
              icon,
              color: HexColor(mariner900),
              size: iconSize,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            Utils.formatDuration(position),
            style: CustomTextStyle.normal12.copyWith(fontSize: fontSize),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Slider(
              value: position.inSeconds
                  .toDouble()
                  .clamp(0.0, duration.inSeconds > 0
                      ? duration.inSeconds.toDouble()
                      : 1.0),
              min: 0.0,
              max: duration.inSeconds > 0
                  ? duration.inSeconds.toDouble()
                  : 1.0,
              onChanged: (_) {},
              activeColor: HexColor(mariner900),
              inactiveColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}