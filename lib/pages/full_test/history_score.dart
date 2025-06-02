import 'package:flutter/material.dart';
import 'package:toefl/models/test/history.dart';
import 'package:toefl/remote/api/history_api.dart';
import 'package:toefl/utils/colors.dart';
import 'package:toefl/utils/hex_color.dart';

class HistoryScore extends StatefulWidget {
  const HistoryScore({super.key});

  @override
  _HistoryScoreState createState() => _HistoryScoreState();
}

class _HistoryScoreState extends State<HistoryScore> {
  String selectedType = "Test";
  ScrollController? _scrollController;
  bool canScrollLeft = false;
  bool canScrollRight = false;

  final HistoryApi _historyApi = HistoryApi();
  List<HistoryItem> historyData = [];
  bool isLoading = true;
  bool isInitialized = false;

  @override
  void initState() {
    super.initState();
    // Initialize ScrollController safely
    _initializeScrollController();
    // Load initial data
    _loadHistoryData();
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

      setState(() {
        canScrollLeft = currentScroll > 0;
        canScrollRight = currentScroll < maxScroll;
      });
    } catch (e) {
      debugPrint('Error updating scroll indicators: $e');
    }
  }

  @override
  void dispose() {
    _scrollController?.removeListener(_updateScrollIndicators);
    _scrollController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredData = historyData
        .where((item) => item.type.toLowerCase() == selectedType.toLowerCase())
        .toList();

    return SizedBox(
      width: double.infinity,
      child: Padding(
        padding: const EdgeInsets.only(left: 30, right: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Toggle Button
            Row(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(2),
                    bottomLeft: Radius.circular(2),
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
                            topLeft: Radius.circular(2),
                            bottomLeft: Radius.circular(2),
                          ),
                        ),
                      ),
                    ),
                    child: Text(
                      "Test",
                      style: TextStyle(
                        color: selectedType == "Test"
                            ? HexColor(primaryWhite)
                            : HexColor(mariner900),
                      ),
                    ),
                  ),
                ),
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(50),
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
                            topRight: Radius.circular(50),
                          ),
                        ),
                      ),
                    ),
                    child: Text(
                      "Simulation",
                      style: TextStyle(
                        color: selectedType == "Simulation"
                            ? HexColor(primaryWhite)
                            : HexColor(mariner900),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Scrollable Table with loading and empty states
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
                    : _buildDataTable(filteredData),

            const SizedBox(height: 8),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildDataTable(List<HistoryItem> filteredData) {
    // Only build the scrollable table if controller is initialized
    if (!isInitialized || _scrollController == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scrollbar(
      controller: _scrollController!,
      thumbVisibility: true,
      child: SingleChildScrollView(
        controller: _scrollController!,
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 800),
          child: DataTable(
            columns: const [
              DataColumn(label: Text("No")),
              DataColumn(label: Text("Total")),
              DataColumn(label: Text("Date & Time")),
              DataColumn(label: Text("Listening")),
              DataColumn(label: Text("Structure")),
              DataColumn(label: Text("Reading")),
            ],
            rows: List.generate(filteredData.length, (index) {
              final data = filteredData[index];
              return DataRow(cells: [
                DataCell(Text("${index + 1}")),
                DataCell(Text(data.displayTotal)),
                DataCell(Text("-")),
                DataCell(Text(data.displayListening)),
                DataCell(Text(data.displayStructure)),
                DataCell(Text(data.displayReading)),
              ]);
            }),
          ),
        ),
      ),
    );
  }
}
