import 'package:flutter/material.dart';
import 'package:toefl/utils/colors.dart';
import 'package:toefl/utils/hex_color.dart';

class HistoryScore extends StatefulWidget {
  const HistoryScore({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _HistoryScoreState createState() => _HistoryScoreState();
}

class _HistoryScoreState extends State<HistoryScore> {
  String selectedType = "Test";
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
                            : HexColor(primaryWhite),
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
                            : HexColor(primaryWhite),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text("No")),
                  DataColumn(label: Text("Date")),
                  DataColumn(label: Text("Time")),
                  DataColumn(label: Text("Listening")),
                  DataColumn(label: Text("Structure")),
                  DataColumn(label: Text("Reading")),
                  DataColumn(label: Text("Total")),
                ],
                rows: List.generate(filteredData.length, (index) {
                  final data = filteredData[index];
                  return DataRow(cells: [
                    DataCell(Text("${index + 1}")),
                    DataCell(Text("${data["date"]}")),
                    DataCell(Text("${data["time"]}")),
                    DataCell(Text("${data["listening"]}")),
                    DataCell(Text("${data["structure"]}")),
                    DataCell(Text("${data["reading"]}")),
                    DataCell(Text("${data["total"]}")),
                  ]);
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
