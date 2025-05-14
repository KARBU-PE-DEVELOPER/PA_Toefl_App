import 'package:flutter/material.dart';
import 'package:toefl/utils/colors.dart';
import 'package:toefl/utils/hex_color.dart';

class HistoryScore extends StatefulWidget {
  const HistoryScore({super.key});

  @override
  _HistoryScoreState createState() => _HistoryScoreState();
}

class _HistoryScoreState extends State<HistoryScore> {
  String selectedType = "Test";
  final ScrollController _scrollController = ScrollController();
  bool canScrollLeft = false;
  bool canScrollRight = false;

  final List<Map<String, dynamic>> historyData = [
    {
      "id": 1,
      "type": "Test",
      "listening": 25,
      "structure": 23,
      "reading": 27,
      "total": 75,
      "date": "2025-04-02",
      "time": "08:30 AM"
    },
    {
      "id": 2,
      "type": "Simulation",
      "listening": 22,
      "structure": 20,
      "reading": 24,
      "total": 66,
      "date": "2025-04-01",
      "time": "10:00 AM"
    },
    {
      "id": 3,
      "type": "Test",
      "listening": 28,
      "structure": 25,
      "reading": 30,
      "total": 83,
      "date": "2025-03-30",
      "time": "02:15 PM"
    },
  ];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_updateScrollIndicators);
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _updateScrollIndicators());
  }

  void _updateScrollIndicators() {
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;

    setState(() {
      canScrollLeft = currentScroll > 0;
      canScrollRight = currentScroll < maxScroll;
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_updateScrollIndicators);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredData =
        historyData.where((item) => item["type"] == selectedType).toList();

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
                    onPressed: () {
                      setState(() {
                        selectedType = "Test";
                      });
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
                    onPressed: () {
                      setState(() {
                        selectedType = "Simulation";
                      });
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

            // Scrollable Table
            Scrollbar(
              controller: _scrollController,
              thumbVisibility: true,
              child: SingleChildScrollView(
                controller: _scrollController,
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
                      final dateTime = "${data["date"]} ${data["time"]}";
                      return DataRow(cells: [
                        DataCell(Text("${index + 1}")),
                        DataCell(Text("${data["total"]}")),
                        DataCell(Text(dateTime)),
                        DataCell(Text("${data["listening"]}")),
                        DataCell(Text("${data["structure"]}")),
                        DataCell(Text("${data["reading"]}")),
                      ]);
                    }),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Scroll indicator line

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
