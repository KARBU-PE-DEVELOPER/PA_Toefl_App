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
    this.enabled = false,
  });

  final String url;
  final bool enabled;

  @override
  State<ToeflAudioPlayer> createState() => _ToeflAudioPlayerState();
}

class _ToeflAudioPlayerState extends State<ToeflAudioPlayer> {
  final player = AudioPlayer();

  Duration position = Duration.zero;
  Duration duration = Duration.zero;
  bool _hasPlayed = false;
  bool _isCompleted = false;

  void handlePlay() async {
    if (_hasPlayed || _isCompleted) return;

    try {
      await player.setUrl(widget.url);
      await player.play();

      setState(() {
        _hasPlayed = true;
      });

      player.positionStream.listen((event) {
        setState(() {
          position = event;
        });
      });

      player.durationStream.listen((event) {
        if (event != null) {
          setState(() {
            duration = event;
          });
        }
      });

      player.playerStateStream.listen((event) {
        if (event.processingState == ProcessingState.completed) {
          setState(() {
            _isCompleted = true;
          });
        }
      });
    } catch (e) {
      debugPrint("Error playing audio: $e");
    }
  }

  @override
  void dispose() {
    player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
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
                onTap: handlePlay,
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
                child: IgnorePointer(
                  child: Slider(
                    value: position.inSeconds.toDouble(),
                    min: 0.0,
                    max: duration.inSeconds.toDouble() > 0
                        ? duration.inSeconds.toDouble()
                        : 1.0,
                    onChanged: (_) {},
                    activeColor: HexColor(mariner900),
                    inactiveColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
