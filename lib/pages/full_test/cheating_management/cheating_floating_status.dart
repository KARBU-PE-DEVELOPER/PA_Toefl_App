import 'package:flutter/material.dart';
import 'dart:math' as math;

class FloatingCheatingStatus extends StatefulWidget {
  final int lookAwayCount;
  final int maxLookAway;
  final int faceNotDetectedSeconds;
  final int faceNotDetectedCountdown;
  final int blinkCountdown;
  final String currentStatus;
  final String blinkStatus;
  final VoidCallback? onUpdate;

  const FloatingCheatingStatus({
    Key? key,
    required this.lookAwayCount,
    required this.maxLookAway,
    required this.faceNotDetectedSeconds,
    required this.faceNotDetectedCountdown,
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

  // FUNGSI BARU: Mendapatkan warna border berdasarkan status yang paling kritis
  Color _getBorderColor() {
    // Cek status face not detected terlebih dahulu (prioritas tertinggi)
    if (widget.currentStatus.contains("not detected")) {
      return _getTimeColor();
    }

    // Cek status look away
    if (widget.currentStatus.contains("Look away")) {
      return _getLookAwayColor();
    }

    // Jika tidak ada masalah khusus, gunakan warna look away sebagai default
    return _getLookAwayColor();
  }

  IconData _getStatusIcon() {
    if (widget.currentStatus.contains("not detected"))
      return Icons.face_retouching_off;
    if (widget.currentStatus.contains("Look away")) return Icons.visibility_off;
    return Icons.face;
  }

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
        borderRadius: BorderRadius.circular(12),
        child: _buildStatusContainer(),
      ),
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: _buildStatusContainer(),
      ),
      onDragEnd: (details) {
        final screenSize = MediaQuery.of(context).size;
        final widgetWidth = _isExpanded ? 170.0 : 60.0;
        final widgetHeight = _isExpanded ? 120.0 : 60.0;

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
      borderRadius: BorderRadius.circular(12),
      shadowColor:
          _getBorderColor().withOpacity(0.3), // GUNAKAN _getBorderColor()
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: _isExpanded ? 170.0 : 60.0,
        height: _isExpanded ? 120.0 : 60.0,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.black87,
              Colors.black54,
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
                _getBorderColor(), // GUNAKAN _getBorderColor() BUKAN _getLookAwayColor()
            width: 2,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: GestureDetector(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: _isExpanded
                  ? _buildExpandedContent()
                  : _buildCollapsedContent(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCollapsedContent() {
    final remaining = widget.maxLookAway - widget.lookAwayCount;
    // UBAH LOGIKA PULSE: Aktif saat face not detected ATAU look away kritis
    final shouldPulse =
        widget.currentStatus.contains("not detected") || remaining <= 1;

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale:
              shouldPulse ? _pulseAnimation.value : 1.0, // GUNAKAN shouldPulse
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _getStatusIcon(),
                  color:
                      _getBorderColor(), // GUNAKAN _getBorderColor() UNTUK KONSISTENSI
                  size: 20,
                ),
                const SizedBox(height: 3),
                Text(
                  // TAMPILKAN COUNTDOWN JIKA FACE NOT DETECTED, ATAU REMAINING LOOK AWAY
                  widget.currentStatus.contains("not detected")
                      ? _formatCountdown(widget.faceNotDetectedCountdown)
                      : '$remaining',
                  style: TextStyle(
                    color:
                        _getBorderColor(), // GUNAKAN _getBorderColor() UNTUK KONSISTENSI
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
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

    return LayoutBuilder(
      builder: (context, constraints) {
        return FittedBox(
          fit: BoxFit.scaleDown,
          child: SizedBox(
            width: 158,
            height: 108,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Status header
                _buildStatusHeader(),

                // Stats
                _buildStatsSection(lookAwayRemaining),

                // Minimize button
                _buildMinimizeButton(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusHeader() {
    return SizedBox(
      height: 20,
      child: Row(
        children: [
          Icon(
            _getStatusIcon(),
            color:
                _getBorderColor(), // GUNAKAN _getBorderColor() UNTUK KONSISTENSI
            size: 14,
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              widget.currentStatus.length > 12
                  ? "${widget.currentStatus.substring(0, 9)}..."
                  : widget.currentStatus,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                height: 1.1,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection(int lookAwayRemaining) {
    return SizedBox(
      height: 72,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Look away
          _buildStatRow(
            Icons.visibility_off,
            "Look Away",
            "$lookAwayRemaining/${widget.maxLookAway}",
            _getLookAwayColor(),
          ),

          // Face timer (kondisional)
          if (widget.faceNotDetectedSeconds > 0)
            _buildStatRow(
              Icons.timer,
              "Timer",
              _formatCountdown(widget.faceNotDetectedCountdown),
              _getTimeColor(),
            ),

          // Blink
          _buildStatRow(
            Icons.remove_red_eye,
            "Blink",
            widget.blinkCountdown > 0 ? "${widget.blinkCountdown}s" : "✓",
            widget.blinkCountdown <= 3 ? Colors.orange : Colors.green,
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(IconData icon, String label, String value, Color color) {
    return SizedBox(
      height: 18,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left side
          Expanded(
            flex: 3,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: color, size: 12),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 9,
                      height: 1.1,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          // Right side
          Expanded(
            flex: 2,
            child: Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 9,
                fontWeight: FontWeight.bold,
                height: 1.1,
              ),
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMinimizeButton() {
    return SizedBox(
      height: 12,
      child: Center(
        child: Container(
          width: 16,
          height: 3,
          decoration: BoxDecoration(
            color: Colors.white54,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }
}
