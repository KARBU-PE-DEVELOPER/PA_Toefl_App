import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:toefl/models/games/searchword_game.dart';
import 'package:toefl/remote/api/games/searchword_api.dart';

class WordSearchGame extends StatefulWidget {
  const WordSearchGame({super.key});

  @override
  State<WordSearchGame> createState() => _WordSearchGameState();
}

class _WordSearchGameState extends State<WordSearchGame> {
  final int gridSize = 10;
  late List<String> words;
  late List<List<String>> grid;
  Set<Offset> selected = {};
  Set<Offset> foundPositions = {};
  String selectedWord = '';
  List<String> foundWords = [];

  final GlobalKey _gridKey = GlobalKey();
  bool isLoading = true;

  int score = 0;
  int timeRemaining = 60;
  Timer? _timer;
  bool gameOver = false;

  @override
  void initState() {
    super.initState();
    _loadWordsFromApi();
  }

  Future<void> _loadWordsFromApi() async {
    try {
      final api = SearchWordApi();
      final data = await api.getWord();
      words = data.words.map((e) => e.toUpperCase()).toList();
      grid = generateGridWithWords(words, gridSize);
    } catch (e) {
      words = [];
      grid = List.generate(gridSize, (i) => List.generate(gridSize, (j) => ''));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal memuat kata: $e")),
      );
    }

    setState(() {
      isLoading = false;
      _startTimer();
    });
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (timeRemaining > 0) {
        setState(() {
          timeRemaining--;
        });
      } else {
        _endGame();
      }
    });
  }

 void _endGame() async {
  _timer?.cancel();

  setState(() {
    gameOver = true;
  });

  try {
    await SearchWordApi().store(score.toDouble()); // Submit the score
  } catch (e) {
    debugPrint("Score submission failed: $e");
  }

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => AlertDialog(
      title: const Text("Time's Up!"),
      content: Text("Your score: $score\nWords found: ${foundWords.length}/${words.length}"),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            Navigator.pop(context);
          },
          child: const Text("OK"),
        ),
      ],
    ),
  );
}


  List<List<String>> generateGridWithWords(List<String> words, int size) {
    List<List<String>> board = List.generate(size, (y) => List.generate(size, (x) => ''));
    final rand = Random();

    for (var word in words) {
      bool placed = false;
      int attempts = 0;

      while (!placed && attempts < 100) {
        int dir = rand.nextInt(4); // 0: right, 1: down, 2: left, 3: up
        int dx = [1, 0, -1, 0][dir];
        int dy = [0, 1, 0, -1][dir];

        int x = rand.nextInt(size);
        int y = rand.nextInt(size);

        if (x + dx * (word.length - 1) >= size ||
            x + dx * (word.length - 1) < 0 ||
            y + dy * (word.length - 1) >= size ||
            y + dy * (word.length - 1) < 0) {
          attempts++;
          continue;
        }

        bool canPlace = true;
        for (int i = 0; i < word.length; i++) {
          String current = board[y + dy * i][x + dx * i];
          if (current.isNotEmpty && current != word[i]) {
            canPlace = false;
            break;
          }
        }

        if (canPlace) {
          for (int i = 0; i < word.length; i++) {
            board[y + dy * i][x + dx * i] = word[i];
          }
          placed = true;
        }

        attempts++;
      }
    }

    for (int y = 0; y < size; y++) {
      for (int x = 0; x < size; x++) {
        if (board[y][x].isEmpty) {
          board[y][x] = String.fromCharCode(rand.nextInt(26) + 65);
        }
      }
    }

    return board;
  }

  void handleCellTap(int x, int y) {
    if (gameOver) return;

    Offset pos = Offset(x.toDouble(), y.toDouble());
    if (selected.contains(pos)) return;

    setState(() {
      selected.add(pos);
      selectedWord += grid[y][x];

      for (var word in words) {
        if (selectedWord == word && !foundWords.contains(word)) {
          foundWords.add(word);
          foundPositions.addAll(selected);
          score += 20; // increment score
          selectedWord = '';
          selected.clear();

          if (foundWords.length == words.length) {
            _endGame();
          }
          break;
        }
      }
    });
  }

  void resetSelection() {
    setState(() {
      selected.clear();
      selectedWord = '';
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double cellSize = MediaQuery.of(context).size.width * 0.095;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Word Search Game'),
        backgroundColor: Colors.indigo,
        elevation: 0,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                const SizedBox(height: 10),
                Text(
                  "Time Left: $timeRemaining sec | Score: $score",
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                const Text("Find the hidden words!"),
                const SizedBox(height: 10),
                LayoutBuilder(
                  builder: (context, constraints) {
                    return GestureDetector(
                      onPanEnd: (_) => resetSelection(),
                      onPanUpdate: (details) {
                        RenderBox box = _gridKey.currentContext?.findRenderObject() as RenderBox;
                        Offset gridTopLeft = box.localToGlobal(Offset.zero);
                        Offset local = details.globalPosition - gridTopLeft;

                        int x = (local.dx ~/ cellSize).clamp(0, gridSize - 1);
                        int y = (local.dy ~/ cellSize).clamp(0, gridSize - 1);

                        handleCellTap(x, y);
                      },
                      child: Container(
                        key: _gridKey,
                        width: cellSize * gridSize,
                        height: cellSize * gridSize,
                        margin: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.black12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Stack(
                          children: [
                            for (int y = 0; y < gridSize; y++)
                              for (int x = 0; x < gridSize; x++)
                                Positioned(
                                  left: x * cellSize,
                                  top: y * cellSize,
                                  child: Container(
                                    width: cellSize,
                                    height: cellSize,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: foundPositions.contains(Offset(x.toDouble(), y.toDouble()))
                                          ? Colors.blue.shade200
                                          : selected.contains(Offset(x.toDouble(), y.toDouble()))
                                              ? Colors.greenAccent
                                              : Colors.white,
                                      border: Border.all(color: Colors.grey.shade300),
                                    ),
                                    child: Text(
                                      grid[y][x],
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: words.map((word) {
                    bool found = foundWords.contains(word);
                    return Chip(
                      label: Text(
                        word,
                        style: TextStyle(
                          decoration: found ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      backgroundColor: found ? Colors.green : Colors.grey.shade300,
                    );
                  }).toList(),
                ),
              ],
            ),
    );
  }
}