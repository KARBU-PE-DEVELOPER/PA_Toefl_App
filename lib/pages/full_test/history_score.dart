import 'package:flutter/material.dart';
import 'package:toefl/models/test/history.dart';
import 'package:toefl/remote/api/history_api.dart';
import 'package:toefl/remote/api/profile_api.dart';
import 'package:toefl/routes/route_key.dart';
import 'package:toefl/utils/colors.dart';
import 'package:toefl/utils/hex_color.dart';
import 'package:toefl/utils/custom_text_style.dart';
import 'package:easy_localization/easy_localization.dart';

class HistoryScore extends StatefulWidget {
  const HistoryScore({super.key});

  @override
  _HistoryScoreState createState() => _HistoryScoreState();
}

class _HistoryScoreState extends State<HistoryScore>
    with TickerProviderStateMixin {
  String selectedType = "Test";
  ScrollController? _scrollController;
  bool canScrollLeft = false;
  bool canScrollRight = false;

  // Animation controllers for scroll indicators
  late AnimationController _leftArrowController;
  late AnimationController _rightArrowController;
  late Animation<double> _leftArrowAnimation;
  late Animation<double> _rightArrowAnimation;

  final HistoryApi _historyApi = HistoryApi();
  final ProfileApi _profileApi = ProfileApi();
  List<HistoryItem> historyData = [];
  bool isLoading = true;
  bool isInitialized = false;
  String? userName;
  final GlobalKey _certificateKey = GlobalKey();

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

    // Initialize ScrollController safely
    _initializeScrollController();
    // Load initial data
    _loadInitialData();

    // Start right arrow animation initially
    _rightArrowController.repeat(reverse: true);
  }

  Future<void> _loadInitialData() async {
    await Future.wait([
      _loadHistoryData(),
      _loadUserProfile(),
    ]);
  }

  Future<void> _loadUserProfile() async {
    try {
      final profile = await _profileApi.getProfile();
      setState(() {
        userName = profile.nameUser;
      });
      debugPrint("User profile loaded: $userName");
    } catch (e) {
      debugPrint("Error loading user profile: $e");
      setState(() {
        userName = "Dony Ahmad Hisyam"; // Fallback to current user
      });
    }
  }

  void _initializeScrollController() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _scrollController = ScrollController();
          _scrollController!.addListener(_updateScrollIndicators);
          isInitialized = true;
        });
        _updateScrollIndicators();
      }
    });
  }

  Future<void> _loadHistoryData() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
    });

    try {
      debugPrint("Loading history data for type: $selectedType");
      final data =
          await _historyApi.getHistoryByType(selectedType.toLowerCase());

      if (mounted) {
        setState(() {
          historyData = data;
          isLoading = false;
        });
        debugPrint("History data loaded: ${data.length} items");

        // Update scroll indicators after data loads
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _updateScrollIndicators();
        });
      }
    } catch (e) {
      debugPrint('Error loading history data: $e');
      if (mounted) {
        setState(() {
          historyData = [];
          isLoading = false;
        });
      }
    }
  }

  void _updateScrollIndicators() {
    if (_scrollController == null ||
        !_scrollController!.hasClients ||
        !mounted) {
      return;
    }

    try {
      final maxScroll = _scrollController!.position.maxScrollExtent;
      final currentScroll = _scrollController!.offset;

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
  void dispose() {
    _scrollController?.removeListener(_updateScrollIndicators);
    _scrollController?.dispose();
    _leftArrowController.dispose();
    _rightArrowController.dispose();
    super.dispose();
  }

  // Parse time_start dari API ke DateTime
  DateTime _parseTimeStart(String timeStart) {
    try {
      // Format dari API: "2025-06-13 12:06:22"
      // Tambahkan 'T' untuk format ISO 8601
      String isoString = timeStart.replaceAll(' ', 'T');
      // Jika tidak ada timezone, tambahkan Z untuk UTC
      if (!isoString.contains('Z') &&
          !isoString.contains('+') &&
          !isoString.contains('-', 10)) {
        isoString += 'Z';
      }
      return DateTime.parse(isoString);
    } catch (e) {
      debugPrint('Error parsing time_start: $timeStart, error: $e');
      // Fallback: parsing manual
      try {
        final parts = timeStart.split(' ');
        if (parts.length == 2) {
          final dateParts = parts[0].split('-');
          final timeParts = parts[1].split(':');

          if (dateParts.length == 3 && timeParts.length >= 2) {
            return DateTime(
              int.parse(dateParts[0]), // year
              int.parse(dateParts[1]), // month
              int.parse(dateParts[2]), // day
              int.parse(timeParts[0]), // hour
              int.parse(timeParts[1]), // minute
              timeParts.length > 2
                  ? int.parse(timeParts[2].split('.')[0])
                  : 0, // second
            );
          }
        }
      } catch (e2) {
        debugPrint('Manual parsing also failed: $e2');
      }
      return DateTime.now(); // Ultimate fallback
    }
  }

  // Format DateTime untuk display di table
  String _formatDateTime(DateTime dateTime) {
    String year = dateTime.year.toString();
    String month = dateTime.month.toString().padLeft(2, '0');
    String day = dateTime.day.toString().padLeft(2, '0');
    String hour = dateTime.hour.toString().padLeft(2, '0');
    String minute = dateTime.minute.toString().padLeft(2, '0');

    return "$year-$month-$day\n$hour:$minute";
  }

  // PERBAIKAN: Show certificate langsung tanpa navigasi
  void _showCertificate(HistoryItem data) {
    debugPrint('Showing certificate for packet ID: ${data.packetId}');

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(16),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.9,
              maxWidth: MediaQuery.of(context).size.width * 0.95,
            ),
            child: Stack(
              children: [
                RepaintBoundary(
                  key: _certificateKey,
                  child: _buildCertificateContent(data),
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCertificateContent(HistoryItem historyData) {
    final DateTime now = DateTime.now();
    final String formattedDate = DateFormat('MMMM dd, yyyy').format(now);
    final scoreData = historyData.score;

    return Container(
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            HexColor(mariner50),
          ],
        ),
        border: Border.all(
          color: HexColor(mariner500),
          width: 8,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: HexColor(mariner500),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.school,
                size: 48,
                color: HexColor(primaryWhite),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'CERTIFICATE OF ACHIEVEMENT',
              style: CustomTextStyle.extrabold24.copyWith(
                color: HexColor(mariner800),
                fontSize: 28,
                letterSpacing: 2,
              ),
              textAlign: TextAlign.center,
              softWrap: true,
              maxLines: 2,
            ),
            const SizedBox(height: 8),
            Container(
              height: 3,
              width: 200,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    HexColor(mariner300),
                    HexColor(mariner700),
                    HexColor(mariner300),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
            Text(
              'This is to certify that',
              style: CustomTextStyle.medium14.copyWith(
                color: HexColor(neutral70),
                fontSize: 18,
              ),
              softWrap: true,
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: HexColor(mariner500),
                    width: 2,
                  ),
                ),
              ),
              child: Text(
                userName ?? "Dony Ahmad Hisyam",
                style: CustomTextStyle.extrabold24.copyWith(
                  color: HexColor(mariner800),
                  fontSize: 32,
                ),
                textAlign: TextAlign.center,
                softWrap: true,
                maxLines: 3,
                overflow: TextOverflow.visible,
              ),
            ),
            const SizedBox(height: 30),
            Text(
              'has successfully completed the',
              style: CustomTextStyle.medium14.copyWith(
                color: HexColor(neutral70),
                fontSize: 18,
              ),
              softWrap: true,
            ),
            const SizedBox(height: 12),
            Text(
              historyData.type.toUpperCase() == 'TEST'
                  ? 'TOEFL TEST'
                  : 'TOEFL SIMULATION',
              style: CustomTextStyle.extrabold24.copyWith(
                color: HexColor(mariner700),
                fontSize: 24,
              ),
              softWrap: true,
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: HexColor(mariner50),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: HexColor(mariner200),
                  width: 1,
                ),
              ),
              child: Text(
                '"${historyData.displayPacketName}"',
                style: CustomTextStyle.bold16.copyWith(
                  color: HexColor(mariner600),
                  fontSize: 18,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
                softWrap: true,
                maxLines: 4,
                overflow: TextOverflow.visible,
              ),
            ),
            const SizedBox(height: 30),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: HexColor(mariner100),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: HexColor(mariner300),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    'ACHIEVEMENT SCORE',
                    style: CustomTextStyle.bold16.copyWith(
                      color: HexColor(mariner800),
                      letterSpacing: 1,
                    ),
                    softWrap: true,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    alignment: WrapAlignment.spaceAround,
                    children: [
                      _buildScoreItem(
                          'TOTAL SCORE', '${scoreData.totalScore.toInt()}'),
                      const SizedBox(width: 20),
                      _buildScoreItem('PERCENTAGE',
                          '${((scoreData.totalScore / 677) * 100).toInt()}%'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    alignment: WrapAlignment.spaceAround,
                    children: [
                      _buildScoreItem('LISTENING',
                          '${scoreData.listeningScore.toInt()}/50'),
                      const SizedBox(width: 10),
                      _buildScoreItem('STRUCTURE',
                          '${scoreData.structureScore.toInt()}/40'),
                      const SizedBox(width: 10),
                      _buildScoreItem(
                          'READING', '${scoreData.readingScore.toInt()}/50'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    children: [
                      Text(
                        'Date of Completion',
                        style: CustomTextStyle.medium14.copyWith(
                          color: HexColor(neutral60),
                        ),
                        softWrap: true,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        formattedDate,
                        style: CustomTextStyle.bold16.copyWith(
                          color: HexColor(mariner700),
                        ),
                        softWrap: true,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    children: [
                      Container(
                        height: 2,
                        width: 120,
                        color: HexColor(mariner500),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Administrator',
                        style: CustomTextStyle.medium14.copyWith(
                          color: HexColor(neutral60),
                        ),
                        softWrap: true,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              'VOCADIA TOEFL PREPARATION',
              style: CustomTextStyle.bold16.copyWith(
                color: HexColor(mariner600),
                letterSpacing: 1,
              ),
              softWrap: true,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreItem(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Column(
        children: [
          Text(
            label,
            style: CustomTextStyle.medium14.copyWith(
              color: HexColor(neutral60),
              fontSize: 10,
            ),
            softWrap: true,
            textAlign: TextAlign.center,
            maxLines: 2,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: CustomTextStyle.extrabold24.copyWith(
              color: HexColor(mariner800),
              fontSize: 18,
            ),
            softWrap: true,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // FIXED: Filter dan sort data dari terlama ke terbaru (ascending)
    final filteredData = historyData
        .where((item) => item.type.toLowerCase() == selectedType.toLowerCase())
        .toList()
      ..sort((a, b) =>
          a.timeStart.compareTo(b.timeStart)); // Sort ascending (terlama dulu)

    return SizedBox(
      width: double.infinity,
      child: Padding(
        padding: const EdgeInsets.only(left: 25, right: 25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Toggle Button
            Row(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8),
                    bottomLeft: Radius.circular(8),
                  ),
                  child: ElevatedButton(
                    onPressed: isLoading
                        ? null
                        : () {
                            setState(() {
                              selectedType = "Test";
                            });
                            _loadHistoryData();
                          },
                    style: ButtonStyle(
                      backgroundColor: WidgetStateProperty.all(
                        selectedType == "Test"
                            ? HexColor(mariner500)
                            : HexColor(mariner300),
                      ),
                      shape: WidgetStateProperty.all(
                        const RoundedRectangleBorder(
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(8),
                            bottomLeft: Radius.circular(8),
                          ),
                        ),
                      ),
                      elevation: WidgetStateProperty.all(0),
                      shadowColor: WidgetStateProperty.all(Colors.transparent),
                    ),
                    child: Text(
                      "Test",
                      style: TextStyle(
                        color: selectedType == "Test"
                            ? HexColor(primaryWhite)
                            : HexColor(mariner900),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(8),
                    bottomRight: Radius.circular(8),
                  ),
                  child: ElevatedButton(
                    onPressed: isLoading
                        ? null
                        : () {
                            setState(() {
                              selectedType = "Simulation";
                            });
                            _loadHistoryData();
                          },
                    style: ButtonStyle(
                      backgroundColor: WidgetStateProperty.all(
                        selectedType == "Simulation"
                            ? HexColor(mariner500)
                            : HexColor(mariner300),
                      ),
                      shape: WidgetStateProperty.all(
                        const RoundedRectangleBorder(
                          borderRadius: BorderRadius.only(
                            topRight: Radius.circular(8),
                            bottomRight: Radius.circular(8),
                          ),
                        ),
                      ),
                      elevation: WidgetStateProperty.all(0),
                      shadowColor: WidgetStateProperty.all(Colors.transparent),
                    ),
                    child: Text(
                      "Simulation",
                      style: TextStyle(
                        color: selectedType == "Simulation"
                            ? HexColor(primaryWhite)
                            : HexColor(mariner900),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Table with synchronized horizontal scroll
            isLoading
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20.0),
                      child: CircularProgressIndicator(),
                    ),
                  )
                : filteredData.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            children: [
                              Icon(
                                Icons.history,
                                size: 48,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'There is no $selectedType history yet',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : selectedType == "Test"
                        ? _buildTestTable(filteredData)
                        : _buildSynchronizedTable(filteredData),

            // Scroll indicator animation
            if (isInitialized && filteredData.isNotEmpty)
              _buildScrollIndicators(),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // FIXED: Special table for Test type with chronological numbering (terlama = 1)
  Widget _buildTestTable(List<HistoryItem> filteredData) {
    if (!isInitialized || _scrollController == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 350),
        child: Scrollbar(
          controller: _scrollController!,
          thumbVisibility: true,
          child: SingleChildScrollView(
            child: SingleChildScrollView(
              controller: _scrollController!,
              scrollDirection: Axis.horizontal,
              child: Column(
                children: [
                  // Header for Test table
                  Container(
                    decoration: BoxDecoration(
                      color: HexColor(mariner300),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(8),
                        topRight: Radius.circular(8),
                      ),
                    ),
                    child: Row(
                      children: [
                        _buildHeaderCell("No", width: 60),
                        _buildHeaderCell("Total", width: 80),
                        _buildHeaderCell("Date & Time", width: 140),
                        _buildHeaderCell("Listening", width: 90),
                        _buildHeaderCell("Structure", width: 90),
                        _buildHeaderCell("Reading", width: 90),
                        _buildHeaderCell("Action", width: 120),
                      ],
                    ),
                  ),
                  // FIXED: Data Rows for Test table with chronological numbering
                  ...List.generate(filteredData.length, (index) {
                    final data = filteredData[index];
                    final dateTime = _parseTimeStart(data.timeStart);
                    // FIXED: Chronological numbering (terlama = 1, terbaru = last number)
                    final rowNumber = index + 1;

                    return Container(
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: Colors.grey.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          _buildDataCell("$rowNumber", width: 60),
                          _buildDataCell(data.displayTotal, width: 80),
                          _buildDataCell(_formatDateTime(dateTime),
                              width: 140, isDateTime: true),
                          _buildDataCell(data.displayListening, width: 90),
                          _buildDataCell(data.displayStructure, width: 90),
                          _buildDataCell(data.displayReading, width: 90),
                          _buildActionCell(data, width: 120),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // PERBAIKAN: Action cell dengan "View Certificate" button
  Widget _buildActionCell(HistoryItem data, {double width = 120}) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: ElevatedButton(
        onPressed: () => _showCertificate(data), // Langsung show certificate
        style: ElevatedButton.styleFrom(
          backgroundColor: HexColor(mariner500),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
          elevation: 0,
          minimumSize: const Size(80, 36),
        ),
        child: const Text(
          'Certificate', // Ubah text jadi Certificate
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  // FIXED: Original table for Simulation type with chronological numbering
  Widget _buildSynchronizedTable(List<HistoryItem> filteredData) {
    if (!isInitialized || _scrollController == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 350),
        child: Scrollbar(
          controller: _scrollController!,
          thumbVisibility: true,
          child: SingleChildScrollView(
            child: SingleChildScrollView(
              controller: _scrollController!,
              scrollDirection: Axis.horizontal,
              child: Column(
                children: [
                  // Header
                  Container(
                    decoration: BoxDecoration(
                      color: HexColor(mariner300),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(8),
                        topRight: Radius.circular(8),
                      ),
                    ),
                    child: Row(
                      children: [
                        _buildHeaderCell("No", width: 60),
                        _buildHeaderCell("Total", width: 80),
                        _buildHeaderCell("Date & Time", width: 140),
                        _buildHeaderCell("Listening", width: 90),
                        _buildHeaderCell("Structure", width: 90),
                        _buildHeaderCell("Reading", width: 90),
                      ],
                    ),
                  ),
                  // FIXED: Data Rows with chronological numbering
                  ...List.generate(filteredData.length, (index) {
                    final data = filteredData[index];
                    final dateTime = _parseTimeStart(data.timeStart);
                    // FIXED: Chronological numbering (terlama = 1, terbaru = last number)
                    final rowNumber = index + 1;

                    return Container(
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: Colors.grey.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          _buildDataCell("$rowNumber", width: 60),
                          _buildDataCell(data.displayTotal, width: 80),
                          _buildDataCell(_formatDateTime(dateTime),
                              width: 140, isDateTime: true),
                          _buildDataCell(data.displayListening, width: 90),
                          _buildDataCell(data.displayStructure, width: 90),
                          _buildDataCell(data.displayReading, width: 90),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
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

  Widget _buildHeaderCell(String text, {double width = 100}) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
          color: Color(0xFF374151),
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildDataCell(String text,
      {double width = 100, bool isDateTime = false}) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Text(
        text,
        style: TextStyle(
          fontSize: isDateTime ? 12 : 14, // Smaller font for date/time
          color: const Color(0xFF6B7280),
          height: isDateTime ? 1.3 : 1.0, // Better line height for multi-line
        ),
        textAlign: TextAlign.center,
        maxLines: isDateTime ? 2 : 1, // Allow 2 lines for date/time
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
