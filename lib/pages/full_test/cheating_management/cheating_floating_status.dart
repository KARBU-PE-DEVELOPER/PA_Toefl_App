import 'package:flutter/material.dart';
import 'dart:math' as math;

class FloatingCheatingStatus extends StatefulWidget {
  final int lookAwayCount;
  final int maxLookAway;
  final int faceNotDetectedSeconds;
  final int faceNotDetectedCountdown; // TAMBAH PARAMETER INI
  final int blinkCountdown;
  final String currentStatus;
  final String blinkStatus;
  final VoidCallback? onUpdate;

  const FloatingCheatingStatus({
    Key? key,
    required this.lookAwayCount,
    required this.maxLookAway,
    required this.faceNotDetectedSeconds,
    required this.faceNotDetectedCountdown, // TAMBAH PARAMETER INI
    required this.blinkCountdown,
    required this.currentStatus,
    required this.blinkStatus,
    this.onUpdate,
  }) : super(key: key);

  @override
  State<FloatingCheatingStatus> createState() => _FloatingCheatingStatusState();
}

class _FloatingCheatingStatusState extends State<FloatingCheatingStatus>
    with TickerProviderStateMixin {
  double _xPosition = 20;
  double _yPosition = 100;
  bool _isExpanded = false;
  late AnimationController _pulseController;
  late AnimationController _expandController;
  late Animation<double> _pulseAnimation;

  static bool _hasInitialized = false;

  @override
  void initState() {
    super.initState();

    if (!_hasInitialized) {
      _hasInitialized = true;
    }

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _expandController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _expandController.forward();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _expandController.dispose();
    super.dispose();
  }

  Color _getLookAwayColor() {
    final remaining = widget.maxLookAway - widget.lookAwayCount;
    if (remaining >= 3) return Colors.green;
    if (remaining >= 1) return Colors.orange;
    return Colors.red;
  }

  Color _getTimeColor() {
    final countdownMinutes = widget.faceNotDetectedCountdown / 60;
    if (countdownMinutes >= 3) return Colors.green;
    if (countdownMinutes >= 1) return Colors.orange;
    return Colors.red;
  }

  IconData _getStatusIcon() {
    if (widget.currentStatus.contains("not detected"))
      return Icons.face_retouching_off;
    if (widget.currentStatus.contains("Look away")) return Icons.visibility_off;
    return Icons.face;
  }

  // FUNGSI UNTUK FORMAT WAKTU COUNTDOWN
  String _formatCountdown(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return "${minutes}:${remainingSeconds.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        IgnorePointer(
          child: Container(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            color: Colors.transparent,
          ),
        ),
        Positioned(
          left: _xPosition,
          top: _yPosition,
          child: _buildDraggableWidget(),
        ),
      ],
    );
  }

  Widget _buildDraggableWidget() {
    return Draggable(
      feedback: Material(
        color: Colors.transparent,
        elevation: 15,
        borderRadius: BorderRadius.circular(15),
        child: _buildStatusContainer(),
      ),
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: _buildStatusContainer(),
      ),
      onDragEnd: (details) {
        final screenSize = MediaQuery.of(context).size;
        final widgetWidth = _isExpanded ? 200 : 60; // PERBESAR WIDTH
        final widgetHeight = _isExpanded ? 180 : 60; // PERBESAR HEIGHT

        setState(() {
          _xPosition = math.max(
              0, math.min(details.offset.dx, screenSize.width - widgetWidth));
          _yPosition = math.max(
              0, math.min(details.offset.dy, screenSize.height - widgetHeight));
        });
      },
      child: _buildStatusContainer(),
    );
  }

  Widget _buildStatusContainer() {
    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(15),
      shadowColor: _getLookAwayColor().withOpacity(0.3),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: _isExpanded ? 200 : 60, // PERBESAR WIDTH
        height: _isExpanded ? 180 : 60, // PERBESAR HEIGHT
        padding: EdgeInsets.all(_isExpanded ? 12 : 6), // PERBESAR PADDING
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.black87,
              Colors.black54,
            ],
          ),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: _getLookAwayColor(),
            width: 2,
          ),
        ),
        child: GestureDetector(
          onTap: () {
            setState(() {
              _isExpanded = !_isExpanded;
            });
          },
          child:
              _isExpanded ? _buildExpandedContent() : _buildCollapsedContent(),
        ),
      ),
    );
  }

  Widget _buildCollapsedContent() {
    final remaining = widget.maxLookAway - widget.lookAwayCount;
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: remaining <= 1 ? _pulseAnimation.value : 1.0,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _getStatusIcon(),
                  color: _getLookAwayColor(),
                  size: 18,
                ),
                const SizedBox(height: 2),
                Text(
                  '$remaining',
                  style: TextStyle(
                    color: _getLookAwayColor(),
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildExpandedContent() {
    final lookAwayRemaining = widget.maxLookAway - widget.lookAwayCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween, // DISTRIBUSI RATA
      children: [
        // Header with status icon
        Row(
          children: [
            Icon(
              _getStatusIcon(),
              color: _getLookAwayColor(),
              size: 18, // PERBESAR ICON
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                widget.currentStatus,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12, // PERBESAR FONT
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ),

        // Look away counter
        _buildInfoRow(
          Icons.visibility_off,
          "Look away",
          "$lookAwayRemaining/${widget.maxLookAway}",
          _getLookAwayColor(),
        ),

        // Face detection countdown timer - MENGGUNAKAN COUNTDOWN
        if (widget.faceNotDetectedSeconds > 0)
          _buildInfoRow(
            Icons.timer,
            "Face Timer",
            _formatCountdown(
                widget.faceNotDetectedCountdown), // COUNTDOWN FORMAT
            _getTimeColor(),
          ),

        // Blink status
        _buildInfoRow(
          Icons.remove_red_eye,
          "Blink",
          widget.blinkCountdown > 0 ? "${widget.blinkCountdown}s" : "✓",
          widget.blinkCountdown <= 3 ? Colors.orange : Colors.green,
        ),

        // Minimize button
        Center(
          child: Container(
            width: 24, // PERBESAR BUTTON
            height: 3,
            decoration: BoxDecoration(
              color: Colors.white54,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2), // PERBESAR SPACING
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14), // PERBESAR ICON
          const SizedBox(width: 6), // PERBESAR SPACING
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 11, // PERBESAR FONT
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 11, // PERBESAR FONT
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
