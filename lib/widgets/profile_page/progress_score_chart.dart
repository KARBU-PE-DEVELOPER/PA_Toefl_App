import 'dart:math' as math;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:toefl/models/test/history.dart';
import 'package:toefl/remote/api/history_api.dart';
import 'package:toefl/utils/colors.dart';
import 'package:toefl/utils/custom_text_style.dart';
import 'package:toefl/utils/hex_color.dart';

// Model untuk data score history (menggunakan data dari API)
class ScoreData {
  final double score;
  final DateTime date;
  final String level;

  ScoreData({
    required this.score,
    required this.date,
    required this.level,
  });

  // Factory untuk konversi dari HistoryItem dengan parsing date yang benar
  factory ScoreData.fromHistoryItem(HistoryItem historyItem) {
    DateTime parsedDate;
    try {
      // Parse time_start format: "2025-06-13 12:06:22"
      // Tambahkan 'T' untuk format ISO 8601
      String isoString = historyItem.timeStart.replaceAll(' ', 'T');
      // Jika tidak ada timezone, tambahkan Z untuk UTC
      if (!isoString.contains('Z') &&
          !isoString.contains('+') &&
          !isoString.contains('-', 10)) {
        isoString += 'Z';
      }
      parsedDate = DateTime.parse(isoString);
    } catch (e) {
      debugPrint('Error parsing date: ${historyItem.timeStart}, error: $e');
      // Fallback: coba parsing manual
      try {
        final parts = historyItem.timeStart.split(' ');
        if (parts.length == 2) {
          final dateParts = parts[0].split('-');
          final timeParts = parts[1].split(':');

          if (dateParts.length == 3 && timeParts.length >= 2) {
            parsedDate = DateTime(
              int.parse(dateParts[0]), // year
              int.parse(dateParts[1]), // month
              int.parse(dateParts[2]), // day
              int.parse(timeParts[0]), // hour
              int.parse(timeParts[1]), // minute
              timeParts.length > 2
                  ? int.parse(timeParts[2].split('.')[0])
                  : 0, // second
            );
          } else {
            parsedDate = DateTime.now();
          }
        } else {
          parsedDate = DateTime.now();
        }
      } catch (e2) {
        debugPrint('Manual parsing also failed: $e2');
        parsedDate = DateTime.now();
      }
    }

    return ScoreData(
      score: historyItem.score.totalScore,
      date: parsedDate,
      level: historyItem.score.levelProficiency,
    );
  }
}

class ProgressScoreChart extends StatefulWidget {
  final double currentScore;
  final num targetScore;
  final String currentLevel;

  const ProgressScoreChart({
    super.key,
    required this.currentScore,
    required this.targetScore,
    required this.currentLevel,
  });

  @override
  State<ProgressScoreChart> createState() => _ProgressScoreChartState();
}

class _ProgressScoreChartState extends State<ProgressScoreChart>
    with TickerProviderStateMixin {
  // FIXED: Initialize scoreData sebagai empty list
  List<ScoreData> scoreData = [];
  ScrollController _scrollController = ScrollController();
  OverlayEntry? _overlayEntry;
  GlobalKey _chartKey = GlobalKey();

  // Animation controllers for scroll indicators
  late AnimationController _leftArrowController;
  late AnimationController _rightArrowController;
  late Animation<double> _leftArrowAnimation;
  late Animation<double> _rightArrowAnimation;

  bool canScrollLeft = false;
  bool canScrollRight = false;
  bool isLoading = true;
  String errorMessage = '';

  // API instance
  final HistoryApi _historyApi = HistoryApi();

  // FIXED: Store dot positions for accurate click detection
  List<Offset> _dotPositions = [];

  @override
  void initState() {
    super.initState();

    // Initialize animation controllers
    _leftArrowController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _rightArrowController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _leftArrowAnimation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _leftArrowController,
      curve: Curves.easeInOut,
    ));

    _rightArrowAnimation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _rightArrowController,
      curve: Curves.easeInOut,
    ));

    // Add scroll listener
    _scrollController.addListener(_updateScrollIndicators);

    // Load data from API
    _loadHistoryData();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_updateScrollIndicators);
    _scrollController.dispose();
    _leftArrowController.dispose();
    _rightArrowController.dispose();
    _removeTooltip();
    super.dispose();
  }

  /// Load history data from API
  Future<void> _loadHistoryData() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = '';
      });

      // Get test history only
      final List<HistoryItem> historyItems = await _historyApi.getTestHistory();

      debugPrint("Loaded ${historyItems.length} test history items");

      if (historyItems.isEmpty) {
        setState(() {
          scoreData = [];
          isLoading = false;
          errorMessage = 'No test history found';
        });
        return;
      }

      // Convert to ScoreData and sort by date (oldest to newest)
      final List<ScoreData> convertedData =
          historyItems.map((item) => ScoreData.fromHistoryItem(item)).toList();

      // Sort by date ascending (oldest first for proper chart progression)
      convertedData.sort((a, b) => a.date.compareTo(b.date));

      setState(() {
        scoreData = convertedData;
        isLoading = false;
      });

      debugPrint("Chart data ready: ${scoreData.length} points");
      for (int i = 0; i < scoreData.length; i++) {
        debugPrint(
            "Point $i: score=${scoreData[i].score}, date=${scoreData[i].date}, level=${scoreData[i].level}");
      }

      // Start animation check after data loaded
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _updateScrollIndicators();
        if (canScrollRight) {
          _rightArrowController.repeat(reverse: true);
        }
      });
    } catch (e, stackTrace) {
      debugPrint("Error loading history data: $e");

      setState(() {
        scoreData = [];
        isLoading = false;
        errorMessage = 'Failed to load history data';
      });
    }
  }

  void _updateScrollIndicators() {
    if (!_scrollController.hasClients || !mounted) {
      return;
    }

    try {
      final maxScroll = _scrollController.position.maxScrollExtent;
      final currentScroll = _scrollController.offset;

      final newCanScrollLeft = currentScroll > 0;
      final newCanScrollRight = currentScroll < maxScroll;

      if (newCanScrollLeft != canScrollLeft ||
          newCanScrollRight != canScrollRight) {
        setState(() {
          canScrollLeft = newCanScrollLeft;
          canScrollRight = newCanScrollRight;
        });

        // Control animations based on scroll position
        if (canScrollLeft && !_leftArrowController.isAnimating) {
          _leftArrowController.repeat(reverse: true);
        } else if (!canScrollLeft) {
          _leftArrowController.stop();
          _leftArrowController.reset();
        }

        if (canScrollRight && !_rightArrowController.isAnimating) {
          _rightArrowController.repeat(reverse: true);
        } else if (!canScrollRight) {
          _rightArrowController.stop();
          _rightArrowController.reset();
        }
      }
    } catch (e) {
      debugPrint('Error updating scroll indicators: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Check if scroll is needed
    bool needsScroll = scoreData.length > 6;

    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: HexColor(mariner300),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Progress Score History Test',
            style: CustomTextStyle.bold16.copyWith(
              fontSize: 18,
              color: HexColor(neutral90),
            ),
          ),
          const SizedBox(height: 12),

          // Chart container with fixed height
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
            ),
            child: _buildChartContent(),
          ),

          // Scroll indicators hanya muncul jika perlu scroll
          if (!isLoading && scoreData.isNotEmpty && needsScroll) ...[
            const SizedBox(height: 8),
            _buildScrollIndicators(),
          ],

          const SizedBox(height: 16),
          // Enhanced info section with 3 columns using API data
          _buildInfoSection(),
        ],
      ),
    );
  }

  Widget _buildChartContent() {
    if (isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(HexColor(mariner500)),
            ),
            const SizedBox(height: 12),
            Text(
              'Loading test history...',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    if (errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.grey[400],
              size: 48,
            ),
            const SizedBox(height: 12),
            Text(
              errorMessage,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _loadHistoryData,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (scoreData.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.assessment_outlined,
              color: Colors.grey[400],
              size: 48,
            ),
            const SizedBox(height: 12),
            Text(
              'No test history available',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Complete some tests to see your progress',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }

    // Check if scroll is needed
    bool needsScroll = scoreData.length > 6;

    return Row(
      children: [
        // Fixed Y-axis labels
        Container(
          width: 40,
          padding: const EdgeInsets.only(left: 12, top: 20, bottom: 16),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('600',
                  style: TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 11,
                      fontWeight: FontWeight.w500)),
              Text('450',
                  style: TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 11,
                      fontWeight: FontWeight.w500)),
              Text('300',
                  style: TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 11,
                      fontWeight: FontWeight.w500)),
              Text('150',
                  style: TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 11,
                      fontWeight: FontWeight.w500)),
              Text('0',
                  style: TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 11,
                      fontWeight: FontWeight.w500)),
            ],
          ),
        ),
        // Chart area dengan conditional scroll
        Expanded(
          child: Container(
            margin: const EdgeInsets.all(16),
            child: Stack(
              children: [
                // Fixed Grid lines
                Positioned.fill(
                  child: CustomPaint(
                    painter: GridPainter(color: const Color(0xFFE2E8F0)),
                  ),
                ),
                // Chart dengan conditional scroll
                needsScroll ? _buildScrollableChart() : _buildStaticChart(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoSection() {
    if (isLoading || scoreData.isEmpty) {
      return Row(
        children: [
          // Last Score
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Last Score',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '${widget.currentScore.toStringAsFixed(0)}/${widget.targetScore}',
                  style: CustomTextStyle.bold16.copyWith(
                    fontSize: 14,
                    color: HexColor(neutral90),
                  ),
                ),
              ],
            ),
          ),
          // Current Level from API
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Level',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _getLevelColor(widget.currentLevel),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    widget.currentLevel.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 9,
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Trend
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Trend',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Icon(
                      Icons.remove,
                      size: 14,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 2),
                    Text(
                      'No Data',
                      style: CustomTextStyle.bold16.copyWith(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        // Last Score
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Last Score',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '${scoreData.last.score.toStringAsFixed(0)}/${widget.targetScore}',
                style: CustomTextStyle.bold16.copyWith(
                  fontSize: 14,
                  color: HexColor(neutral90),
                ),
              ),
            ],
          ),
        ),
        // Current Level from latest test API
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Level',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _getLevelColor(scoreData.last.level),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  scoreData.last.level.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 9,
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
        // Trend
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(
              'Trend',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(
                  _getTrendIcon(),
                  size: 14,
                  color: _getTrendColor(),
                ),
                const SizedBox(width: 2),
                Text(
                  _getTrendText(),
                  style: CustomTextStyle.bold16.copyWith(
                    fontSize: 14,
                    color: _getTrendColor(),
                  ),
                ),
              ],
            ),
          ]),
        ),
      ],
    );
  }

  Color _getLevelColor(String level) {
    switch (level.toUpperCase()) {
      case 'ADVANCED':
        return Colors.purple[600]!;
      case 'UPPER-INTERMEDIATE':
        return Colors.indigo[600]!;
      case 'INTERMEDIATE':
        return Colors.blue[600]!;
      case 'PRE-INTERMEDIATE':
        return Colors.green[600]!;
      case 'ELEMENTARY':
        return Colors.orange[600]!;
      case 'BASIC':
        return Colors.red[600]!;
      default:
        return Colors.grey[600]!;
    }
  }

  IconData _getTrendIcon() {
    if (scoreData.length < 2) return Icons.remove;
    final lastScore = scoreData.last.score;
    final previousScore = scoreData[scoreData.length - 2].score;
    final diff = lastScore - previousScore;

    if (diff > 0) {
      return Icons.trending_up;
    } else if (diff < 0) {
      return Icons.trending_down;
    } else {
      return Icons.trending_flat;
    }
  }

  Widget _buildScrollableChart() {
    return SingleChildScrollView(
      key: _chartKey,
      controller: _scrollController,
      scrollDirection: Axis.horizontal,
      physics: const AlwaysScrollableScrollPhysics(),
      child: GestureDetector(
        onTapDown: (details) {
          _handleScrollableChartTap(details);
        },
        child: Container(
          width: scoreData.length * 60.0, // Dynamic width
          height: double.infinity,
          child: CustomPaint(
            painter: ScoreChartPainter(
              data: scoreData,
              lineColor: const Color(0xFF3B82F6),
              fillColor: const Color(0xFF3B82F6).withOpacity(0.08),
              onDotPositionsCalculated: (positions) {
                // Store dot positions for accurate click detection
                _dotPositions = positions;
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStaticChart() {
    return GestureDetector(
      key: _chartKey,
      onTapDown: (details) {
        _handleStaticChartTap(details);
      },
      child: Container(
        width: double.infinity,
        height: double.infinity,
        child: CustomPaint(
          painter: ScoreChartPainter(
            data: scoreData,
            lineColor: const Color(0xFF3B82F6),
            fillColor: const Color(0xFF3B82F6).withOpacity(0.08),
            onDotPositionsCalculated: (positions) {
              // Store dot positions for accurate click detection
              _dotPositions = positions;
            },
          ),
        ),
      ),
    );
  }

  Widget _buildScrollIndicators() {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Left arrow indicator
          AnimatedBuilder(
            animation: _leftArrowAnimation,
            builder: (context, child) {
              return Opacity(
                opacity: canScrollLeft ? _leftArrowAnimation.value : 0.2,
                child: Icon(
                  Icons.keyboard_arrow_left,
                  color: HexColor(mariner500),
                  size: 24,
                ),
              );
            },
          ),
          const SizedBox(width: 8),
          // Scroll text indicator
          const SizedBox(
            height: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.swipe, size: 14, color: Color(0xFF64748B)),
                SizedBox(width: 6),
                Text(
                  'Scroll horizontally to view more data',
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Right arrow indicator
          AnimatedBuilder(
            animation: _rightArrowAnimation,
            builder: (context, child) {
              return Opacity(
                opacity: canScrollRight ? _rightArrowAnimation.value : 0.2,
                child: Icon(
                  Icons.keyboard_arrow_right,
                  color: HexColor(mariner500),
                  size: 24,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  String _getTrendText() {
    if (scoreData.length < 2) return 'No Data';
    final lastScore = scoreData.last.score;
    final previousScore = scoreData[scoreData.length - 2].score;
    final diff = lastScore - previousScore;

    if (diff > 0) {
      return '+${diff.toStringAsFixed(0)}';
    } else if (diff < 0) {
      return '${diff.toStringAsFixed(0)}';
    } else {
      return '0';
    }
  }

  Color _getTrendColor() {
    if (scoreData.length < 2) return Colors.grey;
    final lastScore = scoreData.last.score;
    final previousScore = scoreData[scoreData.length - 2].score;
    final diff = lastScore - previousScore;

    if (diff > 0) {
      return Colors.green[600]!;
    } else if (diff < 0) {
      return Colors.red[600]!;
    } else {
      return Colors.grey[600]!;
    }
  }

  // FIXED: Handle scrollable chart tap dengan radius deteksi yang lebih besar
  void _handleScrollableChartTap(TapDownDetails details) {
    if (scoreData.isEmpty || _dotPositions.isEmpty) return;

    final double tapX = details.localPosition.dx;
    final double tapY = details.localPosition.dy;

    debugPrint('=== SCROLLABLE CHART TAP DEBUG ===');
    debugPrint('Tap position: ($tapX, $tapY)');
    debugPrint('Available dot positions: ${_dotPositions.length}');

    // Find the closest dot with improved logic
    int closestDotIndex = -1;
    double minDistance = double.infinity;

    for (int i = 0; i < _dotPositions.length && i < scoreData.length; i++) {
      final dotPosition = _dotPositions[i];
      final distanceSquared =
          ((dotPosition.dx - tapX) * (dotPosition.dx - tapX) +
              (dotPosition.dy - tapY) * (dotPosition.dy - tapY));
      final distance = math.sqrt(distanceSquared);

      debugPrint(
          'Point $i: position=(${dotPosition.dx.toStringAsFixed(1)}, ${dotPosition.dy.toStringAsFixed(1)}), distance=${distance.toStringAsFixed(1)}, score=${scoreData[i].score}');

      if (distanceSquared < minDistance) {
        minDistance = distanceSquared;
        closestDotIndex = i;
      }
    }

    final double closestDistance = math.sqrt(minDistance);
    debugPrint(
        'Closest dot: index=$closestDotIndex, distance=${closestDistance.toStringAsFixed(1)}');

    // INCREASED: Click detection radius from 50 to 100 pixels for better UX
    if (closestDotIndex >= 0 && closestDistance <= 100) {
      final RenderBox? renderBox =
          _chartKey.currentContext?.findRenderObject() as RenderBox?;
      if (renderBox != null) {
        final dotLocalPosition = _dotPositions[closestDotIndex];
        final dotGlobalPosition = renderBox.localToGlobal(dotLocalPosition);

        debugPrint(
            '✅ SHOWING TOOLTIP for point $closestDotIndex with score ${scoreData[closestDotIndex].score}');
        _showTooltip(
            scoreData[closestDotIndex], dotGlobalPosition, closestDotIndex);
      }
    } else {
      debugPrint(
          '❌ No dot within range. Closest distance: ${closestDistance.toStringAsFixed(1)} (threshold: 100)');
    }
    debugPrint('=== END SCROLLABLE CHART TAP DEBUG ===\n');
  }

  // FIXED: Handle static chart tap dengan radius deteksi yang lebih besar
  void _handleStaticChartTap(TapDownDetails details) {
    if (scoreData.isEmpty || _dotPositions.isEmpty) return;

    // IMPROVED: Better coordinate calculation
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final chartArea = renderBox.size;

    // Get raw tap position
    final double rawTapX = details.localPosition.dx;
    final double rawTapY = details.localPosition.dy;

    // Calculate offset based on chart structure
    const double yAxisWidth = 40.0; // Y-axis label width
    const double padding = 16.0; // Container margin

    final double tapX = rawTapX - yAxisWidth - padding;
    final double tapY = rawTapY - padding;

    debugPrint('=== STATIC CHART TAP DEBUG ===');
    debugPrint('Raw tap: ($rawTapX, $rawTapY)');
    debugPrint('Adjusted tap: ($tapX, $tapY)');
    debugPrint('Chart area: ${chartArea.width} x ${chartArea.height}');
    debugPrint('Available dot positions: ${_dotPositions.length}');

    // Find the closest dot
    int closestDotIndex = -1;
    double minDistance = double.infinity;

    for (int i = 0; i < _dotPositions.length && i < scoreData.length; i++) {
      final dotPosition = _dotPositions[i];
      final distanceSquared =
          ((dotPosition.dx - tapX) * (dotPosition.dx - tapX) +
              (dotPosition.dy - tapY) * (dotPosition.dy - tapY));
      final distance = math.sqrt(distanceSquared);

      debugPrint(
          'Point $i: position=(${dotPosition.dx.toStringAsFixed(1)}, ${dotPosition.dy.toStringAsFixed(1)}), distance=${distance.toStringAsFixed(1)}, score=${scoreData[i].score}');

      if (distanceSquared < minDistance) {
        minDistance = distanceSquared;
        closestDotIndex = i;
      }
    }

    final double closestDistance = math.sqrt(minDistance);
    debugPrint(
        'Closest dot: index=$closestDotIndex, distance=${closestDistance.toStringAsFixed(1)}');

    // INCREASED: Click detection radius from 50 to 100 pixels for better UX
    if (closestDotIndex >= 0 && closestDistance <= 100) {
      // Calculate global position for tooltip
      final dotLocalPosition = Offset(
          _dotPositions[closestDotIndex].dx + yAxisWidth + padding,
          _dotPositions[closestDotIndex].dy + padding);
      final dotGlobalPosition = renderBox.localToGlobal(dotLocalPosition);

      debugPrint(
          '✅ SHOWING TOOLTIP for point $closestDotIndex with score ${scoreData[closestDotIndex].score}');
      _showTooltip(
          scoreData[closestDotIndex], dotGlobalPosition, closestDotIndex);
    } else {
      debugPrint(
          '❌ No dot within range. Closest distance: ${closestDistance.toStringAsFixed(1)} (threshold: 100)');
    }
    debugPrint('=== END STATIC CHART TAP DEBUG ===\n');
  }

  void _showTooltip(ScoreData data, Offset dotGlobalPosition, int dataIndex) {
    _removeTooltip();

    _overlayEntry = OverlayEntry(
      builder: (context) => GestureDetector(
        onTap: _removeTooltip, // Tap outside to close
        behavior: HitTestBehavior.translucent,
        child: Stack(
          children: [
            // Semi-transparent background
            Container(
              width: double.infinity,
              height: double.infinity,
              color: Colors.black.withOpacity(0.1),
            ),
            // Clean tooltip positioned above the dot (no arrow, simplified)
            Positioned(
              left: (dotGlobalPosition.dx - 70)
                  .clamp(10.0, MediaQuery.of(context).size.width - 150),
              top: (dotGlobalPosition.dy - 120) // Position above the dot
                  .clamp(50.0, MediaQuery.of(context).size.height - 140),
              child: GestureDetector(
                onTap: () {}, // Prevent closing when tapping on tooltip itself
                child: Material(
                  elevation: 16,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    width: 140,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border:
                          Border.all(color: const Color(0xFF3B82F6), width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Header with close button
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Score',
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF3B82F6),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            GestureDetector(
                              onTap: _removeTooltip,
                              child: Container(
                                padding: const EdgeInsets.all(3),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Icon(Icons.close,
                                    size: 14, color: Colors.grey[600]),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 8),

                        // Large score display
                        Text(
                          '${data.score.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 28,
                            color: Color(0xFF3B82F6),
                          ),
                        ),

                        const SizedBox(height: 8),

                        // Level badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: _getLevelColor(data.level),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            data.level.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 9,
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),

                        const SizedBox(height: 8),

                        // Date
                        Text(
                          DateFormat('MMM dd, yyyy').format(data.date),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),

                        const SizedBox(height: 2),

                        // Time
                        Text(
                          DateFormat('HH:mm').format(data.date),
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeTooltip() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }
}

class GridPainter extends CustomPainter {
  final Color color;

  GridPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    // Draw horizontal grid lines
    for (int i = 0; i <= 3; i++) {
      final y = (size.height / 3) * i;
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class ScoreChartPainter extends CustomPainter {
  final List<ScoreData> data;
  final Color lineColor;
  final Color fillColor;
  final Function(List<Offset>)? onDotPositionsCalculated;

  ScoreChartPainter({
    required this.data,
    required this.lineColor,
    required this.fillColor,
    this.onDotPositionsCalculated,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;

    final dotPaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.fill;

    final dotBorderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final path = Path();
    final fillPath = Path();

    const double maxValue = 600;
    // IMPROVED: Better spacing calculation
    final double stepX =
        data.length > 1 ? size.width / (data.length - 1) : size.width / 2;

    // Store dot positions for click detection
    List<Offset> dotPositions = [];

    // Create paths using score data
    for (int i = 0; i < data.length; i++) {
      final double x = data.length == 1 ? size.width / 2 : i * stepX;
      final double y = size.height - (data[i].score / maxValue * size.height);

      // Store dot position
      dotPositions.add(Offset(x, y));

      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }

    // Complete fill path
    if (data.length == 1) {
      // For single point, create a small area around it
      final double x = size.width / 2;
      final double y = size.height - (data[0].score / maxValue * size.height);
      fillPath.lineTo(x, size.height);
    } else {
      fillPath.lineTo((data.length - 1) * stepX, size.height);
    }
    fillPath.close();

    // Draw fill area
    canvas.drawPath(fillPath, fillPaint);

    // Draw line (only if more than one point)
    if (data.length > 1) {
      canvas.drawPath(path, linePaint);
    }

    // ENHANCED: Draw larger clickable dots for better interaction
    for (int i = 0; i < data.length; i++) {
      final double x = data.length == 1 ? size.width / 2 : i * stepX;
      final double y = size.height - (data[i].score / maxValue * size.height);

      // Larger white border for better visibility and clicking
      canvas.drawCircle(Offset(x, y), 15, dotBorderPaint);

      // Blue dot
      canvas.drawCircle(Offset(x, y), 10, dotPaint);
    }

    // CRITICAL: Pass dot positions back to widget for click detection
    if (onDotPositionsCalculated != null) {
      onDotPositionsCalculated!(dotPositions);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
