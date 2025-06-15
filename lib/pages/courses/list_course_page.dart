import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:toefl/models/courses/course.dart';
import 'package:toefl/state_management/courses/course_list_provider.dart';
import 'package:toefl/utils/pattern_painter.dart';
import 'package:toefl/widgets/course/build_course_list_widget.dart';
import 'package:toefl/widgets/course/course_card_widget.dart';
import 'package:toefl/utils/hex_color.dart';
import 'package:toefl/utils/colors.dart';
import 'package:toefl/widgets/course/course_grid_widget.dart';

class ListCoursePage extends ConsumerStatefulWidget {
  const ListCoursePage({super.key});

  @override
  ConsumerState<ListCoursePage> createState() => _ListCoursePageState();
}

class _ListCoursePageState extends ConsumerState<ListCoursePage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<Course> _filterCourses(List<Course> courses) {
    if (_searchQuery.isEmpty) return courses;
    return courses
        .where((course) => course.courseName
            .toLowerCase()
            .contains(_searchQuery.toLowerCase()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(courseListProviderProvider);

    return Scaffold(
      backgroundColor: HexColor(neutral20),
      body: CustomScrollView(
        slivers: [
          // Modern App Bar with Search
          SliverAppBar(
            automaticallyImplyLeading: false,
            expandedHeight: 280,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: HexColor(mariner700),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      HexColor(mariner700),
                      HexColor(mariner500),
                      HexColor(deepSkyBlue),
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    // Background Pattern
                    Positioned.fill(
                      child: CustomPaint(
                        painter: PatternPainter(),
                      ),
                    ),
                    // Content
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'TOEFL Courses',
                            style: GoogleFonts.nunito(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Master your English skills',
                            style: GoogleFonts.nunito(
                              fontSize: 16,
                              color: Colors.white70,
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Search Bar
                          Container(
                            height: 50,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(25),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                              ),
                            ),
                            child: TextField(
                              controller: _searchController,
                              onChanged: (value) {
                                setState(() {
                                  _searchQuery = value;
                                });
                              },
                              style: GoogleFonts.nunito(color: Colors.white),
                              decoration: InputDecoration(
                                hintText: 'Search courses...',
                                hintStyle: GoogleFonts.nunito(
                                  color: Colors.white70,
                                ),
                                prefixIcon: const Icon(
                                  Icons.search,
                                  color: Colors.white70,
                                ),
                                suffixIcon: _searchQuery.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(
                                          Icons.clear,
                                          color: Colors.white70,
                                        ),
                                        onPressed: () {
                                          _searchController.clear();
                                          setState(() {
                                            _searchQuery = '';
                                          });
                                        },
                                      )
                                    : null,
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 15,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(50),
              child: Container(
                color: HexColor(mariner700),
                child: TabBar(
                  controller: _tabController,
                  indicatorColor: Colors.white,
                  indicatorWeight: 3,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white60,
                  labelStyle: GoogleFonts.nunito(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  tabs: const [
                    Tab(
                      icon: Icon(Icons.menu_book, size: 20),
                      text: 'Reading',
                    ),
                    Tab(
                      icon: Icon(Icons.headphones, size: 20),
                      text: 'Listening',
                    ),
                    Tab(
                      icon: Icon(Icons.architecture, size: 20),
                      text: 'Structure',
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Course Content
          SliverFillRemaining(
            child: state.when(
              data: (data) => TabBarView(
                controller: _tabController,
                children: [
                  CourseGridWidget(
                    courses: _filterCourses(data.reading),
                    courseType: 'reading',
                  ),
                  CourseGridWidget(
                    courses: _filterCourses(data.listening),
                    courseType: 'listening',
                  ),
                  CourseGridWidget(
                    courses: _filterCourses(data.structure),
                    courseType: 'structure',
                  ),
                ],
              ),
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
              error: (e, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: HexColor(colorError),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Oops! Something went wrong',
                      style: GoogleFonts.nunito(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      e.toString(),
                      style: GoogleFonts.nunito(
                        fontSize: 14,
                        color: HexColor(neutral60),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        ref.refresh(courseListProviderProvider);
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
