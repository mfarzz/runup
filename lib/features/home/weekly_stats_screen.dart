import 'package:flutter/material.dart';

import '../../models/activity_models.dart';
import '../../services/activity_storage_service.dart';
import '../../widgets/expandable_weekly_stats_item.dart';

class WeeklyStatsScreen extends StatefulWidget {
  const WeeklyStatsScreen({super.key});

  @override
  State<WeeklyStatsScreen> createState() => _WeeklyStatsScreenState();
}

class _WeeklyStatsScreenState extends State<WeeklyStatsScreen>
    with TickerProviderStateMixin {
  final ActivityStorageService _storageService = ActivityStorageService();
  final ScrollController _scrollController = ScrollController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  List<Map<String, dynamic>> _allWeeklyStats = [];
  List<Map<String, dynamic>> _displayedStats = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  
  // Date search
  DateTime? _searchDate;
  
  // Pagination
  int _currentPage = 0;
  final int _itemsPerPage = 10;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadWeeklyStats();
    _scrollController.addListener(_onScroll);
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
    ));

    _animationController.forward();
  }

  Future<void> _loadWeeklyStats() async {
    try {
      final activities = await _storageService.getActivities();
      _allWeeklyStats = _generateWeeklyStats(activities);
      _applyDateSearch();
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading weekly stats: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  List<Map<String, dynamic>> _generateWeeklyStats(List<ActivitySession> activities) {
    final Map<String, List<ActivitySession>> weeklyGroups = {};
    
    for (var activity in activities) {
      if (activity.endTime == null) continue;
      
      // Calculate week start (Monday)
      final activityDate = activity.endTime!;
      final daysSinceMonday = (activityDate.weekday - 1) % 7;
      final weekStart = activityDate.subtract(Duration(days: daysSinceMonday));
      final weekKey = '${weekStart.year}-W${_getWeekNumber(weekStart)}';
      
      weeklyGroups[weekKey] ??= [];
      weeklyGroups[weekKey]!.add(activity);
    }
    
    // Convert to list and sort by most recent week first
    return weeklyGroups.entries.map((entry) {
      final weekActivities = entry.value;
      final weekStart = weekActivities.first.endTime!;
      final daysSinceMonday = (weekStart.weekday - 1) % 7;
      final actualWeekStart = weekStart.subtract(Duration(days: daysSinceMonday));
      final weekEnd = actualWeekStart.add(const Duration(days: 6));
      
      return {
        'weekKey': entry.key,
        'weekStart': actualWeekStart,
        'weekEnd': weekEnd,
        'activities': weekActivities,
        'stats': _calculateWeekStats(weekActivities),
        'isCurrentWeek': _isCurrentWeek(actualWeekStart),
      };
    }).toList()
      ..sort((a, b) => (b['weekStart'] as DateTime).compareTo(a['weekStart'] as DateTime));
  }

  int _getWeekNumber(DateTime date) {
    final firstDayOfYear = DateTime(date.year, 1, 1);
    final daysSinceStart = date.difference(firstDayOfYear).inDays;
    return ((daysSinceStart + firstDayOfYear.weekday - 1) / 7).ceil();
  }

  bool _isCurrentWeek(DateTime weekStart) {
    final now = DateTime.now();
    final currentWeekStart = now.subtract(Duration(days: (now.weekday - 1) % 7));
    return weekStart.difference(currentWeekStart).inDays.abs() < 7;
  }

  Map<String, dynamic> _calculateWeekStats(List<ActivitySession> activities) {
    double totalDistance = 0;
    int totalDuration = 0;
    int totalActivities = activities.length;
    
    final activityCounts = <ActivityType, int>{};
    final activityDistances = <ActivityType, double>{};
    
    for (var activity in activities) {
      totalDistance += activity.distance;
      totalDuration += activity.duration.inSeconds;
      
      activityCounts[activity.type] = (activityCounts[activity.type] ?? 0) + 1;
      activityDistances[activity.type] = (activityDistances[activity.type] ?? 0) + activity.distance;
    }
    
    return {
      'totalDistance': totalDistance,
      'totalDuration': totalDuration,
      'totalActivities': totalActivities,
      'activityCounts': activityCounts,
      'activityDistances': activityDistances,
      'averageDistance': totalActivities > 0 ? totalDistance / totalActivities : 0,
      'averageDuration': totalActivities > 0 ? totalDuration / totalActivities : 0,
    };
  }

  void _applyDateSearch() {
    List<Map<String, dynamic>> filteredStats;
    
    if (_searchDate == null) {
      filteredStats = List.from(_allWeeklyStats);
    } else {
      // Find the week that contains the search date
      final searchWeek = _findWeekContainingDate(_searchDate!);
      if (searchWeek != null) {
        filteredStats = [searchWeek];
      } else {
        filteredStats = [];
      }
    }
    
    _currentPage = 0;
    _displayedStats = _getPagedData(filteredStats);
    
    if (mounted) {
      setState(() {});
    }
  }

  Map<String, dynamic>? _findWeekContainingDate(DateTime date) {
    for (var weekStats in _allWeeklyStats) {
      final weekStart = weekStats['weekStart'] as DateTime;
      final weekEnd = weekStats['weekEnd'] as DateTime;
      
      if (date.isAfter(weekStart.subtract(const Duration(days: 1))) &&
          date.isBefore(weekEnd.add(const Duration(days: 1)))) {
        return weekStats;
      }
    }
    return null;
  }

  List<Map<String, dynamic>> _getPagedData(List<Map<String, dynamic>> data) {
    final endIndex = (_currentPage + 1) * _itemsPerPage;
    return data.take(endIndex).toList();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  void _loadMore() {
    final filteredStats = _searchDate == null 
        ? _allWeeklyStats 
        : _findWeekContainingDate(_searchDate!) != null 
            ? [_findWeekContainingDate(_searchDate!)!] 
            : <Map<String, dynamic>>[];
            
    if (!_isLoadingMore && _currentPage * _itemsPerPage < filteredStats.length) {
      setState(() {
        _isLoadingMore = true;
        _currentPage++;
      });

      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          setState(() {
            _displayedStats = _getPagedData(filteredStats);
            _isLoadingMore = false;
          });
        }
      });
    }
  }

  void _showDatePicker() {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (context) => _buildCustomDatePicker(),
    );
  }

  Widget _buildCustomDatePicker() {
    final currentDate = DateTime.now();
    final selectedDate = _searchDate ?? currentDate;
    
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 320,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withOpacity(0.25),
              Colors.white.withOpacity(0.15),
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Colors.white.withOpacity(0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.black.withOpacity(0.6),
                  Colors.black.withOpacity(0.4),
                ],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.white.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        color: const Color(0xFF00D4FF),
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Select Date',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Calendar Content
                Container(
                  padding: const EdgeInsets.all(20),
                  child: Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: ColorScheme.dark(
                        primary: const Color(0xFF00D4FF),
                        onPrimary: Colors.white,
                        surface: Colors.transparent,
                        onSurface: Colors.white,
                        onSurfaceVariant: Colors.white.withOpacity(0.7),
                      ),
                      datePickerTheme: DatePickerThemeData(
                        backgroundColor: Colors.transparent,
                        headerBackgroundColor: Colors.transparent,
                        headerForegroundColor: Colors.white,
                        dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
                          if (states.contains(WidgetState.selected)) {
                            return const Color(0xFF00D4FF);
                          }
                          if (states.contains(WidgetState.hovered)) {
                            return Colors.white.withOpacity(0.1);
                          }
                          return Colors.transparent;
                        }),
                        dayForegroundColor: WidgetStateProperty.resolveWith((states) {
                          if (states.contains(WidgetState.selected)) {
                            return Colors.white;
                          }
                          if (states.contains(WidgetState.disabled)) {
                            return Colors.white.withOpacity(0.3);
                          }
                          return Colors.white;
                        }),
                        todayBackgroundColor: WidgetStateProperty.resolveWith((states) {
                          if (states.contains(WidgetState.selected)) {
                            return const Color(0xFF00D4FF);
                          }
                          return Colors.white.withOpacity(0.2);
                        }),
                        todayForegroundColor: WidgetStateProperty.all(Colors.white),
                        yearBackgroundColor: WidgetStateProperty.resolveWith((states) {
                          if (states.contains(WidgetState.selected)) {
                            return const Color(0xFF00D4FF);
                          }
                          return Colors.transparent;
                        }),
                        yearForegroundColor: WidgetStateProperty.all(Colors.white),
                        dayShape: WidgetStateProperty.all(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        todayBorder: BorderSide(
                          color: const Color(0xFF00D4FF).withOpacity(0.5),
                          width: 1,
                        ),
                      ),
                    ),
                    child: CalendarDatePicker(
                      initialDate: selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: currentDate,
                      onDateChanged: (date) {
                        // Update state immediately without popping
                        if (mounted) {
                          setState(() {
                            _searchDate = date;
                            _applyDateSearch();
                          });
                        }
                        
                        // Close the dialog after a brief delay
                        Future.delayed(const Duration(milliseconds: 50), () {
                          if (mounted && context.mounted) {
                            Navigator.of(context, rootNavigator: true).pop();
                          }
                        });
                      },
                    ),
                  ),
                ),
                
                // Action Buttons
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: Colors.white.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: const Text(
                              'Cancel',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (_searchDate != null) ...[
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              // Close the dialog first, then update state
                              Navigator.of(context).pop();
                              
                              // Use a slight delay to avoid navigation conflicts
                              Future.delayed(const Duration(milliseconds: 100), () {
                                if (mounted) {
                                  setState(() {
                                    _searchDate = null;
                                    _applyDateSearch();
                                  });
                                }
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.red.withOpacity(0.4),
                                  width: 1,
                                ),
                              ),
                              child: const Text(
                                'Clear',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.red,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _clearSearch() {
    setState(() {
      _searchDate = null;
      _applyDateSearch();
    });
  }

  String _formatWeekRange(DateTime start, DateTime end) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    
    if (start.month == end.month) {
      return '${start.day}-${end.day} ${months[start.month - 1]} ${start.year}';
    } else {
      return '${start.day} ${months[start.month - 1]} - ${end.day} ${months[end.month - 1]} ${start.year}';
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0F0F23), // Dark blue-purple
              Color(0xFF1A1A2E), // Medium dark blue
              Color(0xFF16213E), // Dark navy
              Color(0xFF0F0F23), // Back to dark blue-purple
            ],
            stops: [0.0, 0.3, 0.7, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header - clean without search button
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF0F0F23).withOpacity(0.95),
                      const Color(0xFF1A1A2E).withOpacity(0.90),
                      const Color(0xFF16213E).withOpacity(0.85),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                child: const Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Weekly Stats',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Search Date Button - positioned below header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    GestureDetector(
                      onTap: _showDatePicker,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              const Color(0xFF00D4FF).withOpacity(0.3),
                              const Color(0xFF00D4FF).withOpacity(0.2),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFF00D4FF).withOpacity(0.5),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF00D4FF).withOpacity(0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.search,
                              color: const Color(0xFF00D4FF),
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Search Date',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.95),
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Date Search Result Banner
              if (_searchDate != null)
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: _buildSearchResultBanner(),
                ),
              
              // Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 100), // Optimized padding for bottom nav
                  child: _isLoading
                      ? _buildLoadingState()
                      : _displayedStats.isEmpty
                        ? _buildEmptyState()
                        : _buildWeeklyStatsList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildSearchResultBanner() {
    final weekData = _findWeekContainingDate(_searchDate!);
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF00D4FF).withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF00D4FF).withOpacity(0.4),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.search,
            color: const Color(0xFF00D4FF),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Search Result',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  weekData != null 
                      ? 'Week of ${_formatWeekRange(weekData['weekStart'], weekData['weekEnd'])}'
                      : 'No data found for ${_searchDate!.day}/${_searchDate!.month}/${_searchDate!.year}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: _clearSearch,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.close,
                color: Colors.white.withOpacity(0.8),
                size: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(
        color: Color(0xFF00D4FF),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Icon(
                Icons.bar_chart,
                size: 64,
                color: Colors.white.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _searchDate != null ? 'No activities found' : 'No weekly stats yet',
              style: TextStyle(
                fontSize: 20,
                color: Colors.white.withOpacity(0.8),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _searchDate != null 
                  ? 'Try searching for a different date'
                  : 'Start tracking your activities to see weekly statistics',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyStatsList() {
    return RefreshIndicator(
      onRefresh: _loadWeeklyStats,
      color: const Color(0xFF00D4FF),
      backgroundColor: Colors.white,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.only(left: 20, right: 20, top: 12, bottom: 20),
        itemCount: _displayedStats.length + (_isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _displayedStats.length) {
            return const Padding(
              padding: EdgeInsets.all(20),
              child: Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF00D4FF),
                ),
              ),
            );
          }

          final weekData = _displayedStats[index];
          return SlideTransition(
            position: _slideAnimation,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: ExpandableWeeklyStatsItem(
                weekData: weekData,
                index: index,
              ),
            ),
          );
        },
      ),
    );
  }
}