import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/activity_models.dart';
import '../../services/activity_storage_service.dart';
import '../../widgets/expandable_activity_item.dart';

class AllActivitiesScreen extends StatefulWidget {
  const AllActivitiesScreen({super.key});

  @override
  State<AllActivitiesScreen> createState() => _AllActivitiesScreenState();
}

class _AllActivitiesScreenState extends State<AllActivitiesScreen>
    with TickerProviderStateMixin {
  final ActivityStorageService _storageService = ActivityStorageService();
  final ScrollController _scrollController = ScrollController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  List<ActivitySession> _allActivities = [];
  List<ActivitySession> _filteredActivities = [];
  List<ActivitySession> _displayedActivities = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMoreData = true;
  ActivityType? _selectedFilter;
  
  // Pagination settings
  static const int _pageSize = 10;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _setupScrollListener();
    _loadAllActivities();
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= 
          _scrollController.position.maxScrollExtent - 200) {
        if (!_isLoadingMore && _hasMoreData) {
          _loadMoreActivities();
        }
      }
    });
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
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
    
    // Start repeating animation for shimmer effect
    _animationController.repeat();
  }

  Future<void> _loadAllActivities() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _currentPage = 0;
        _displayedActivities.clear();
      });
    }

    try {
      final activities = await _storageService.getActivities();
      activities.sort((a, b) => (b.endTime ?? DateTime.now()).compareTo(a.endTime ?? DateTime.now()));
      
      if (mounted) {
        setState(() {
          _allActivities = activities;
          _applyFilter();
          _loadFirstPage();
          _isLoading = false;
        });
        
        // Stop repeating animation and set to normal state for list animations
        _animationController.stop();
        _animationController.reset();
        _animationController.forward();
      }
    } catch (e) {
      print('Error loading activities: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _loadFirstPage() {
    _currentPage = 0;
    _hasMoreData = _filteredActivities.length > _pageSize;
    
    final endIndex = _pageSize.clamp(0, _filteredActivities.length);
    _displayedActivities = _filteredActivities.take(endIndex).toList();
  }

  Future<void> _loadMoreActivities() async {
    if (_isLoadingMore || !_hasMoreData) return;

    setState(() {
      _isLoadingMore = true;
    });

    // Simulate network delay for better UX
    await Future.delayed(const Duration(milliseconds: 300));

    if (mounted) {
      setState(() {
        _currentPage++;
        final startIndex = _currentPage * _pageSize;
        final endIndex = ((startIndex + _pageSize).clamp(0, _filteredActivities.length));
        
        if (startIndex < _filteredActivities.length) {
          final newItems = _filteredActivities.sublist(startIndex, endIndex);
          _displayedActivities.addAll(newItems);
          
          _hasMoreData = endIndex < _filteredActivities.length;
        } else {
          _hasMoreData = false;
        }
        
        _isLoadingMore = false;
      });
    }
  }

  void _applyFilter() {
    if (_selectedFilter == null) {
      _filteredActivities = List.from(_allActivities);
    } else {
      _filteredActivities = _allActivities.where((activity) => activity.type == _selectedFilter).toList();
    }
    
    // Reset pagination when filter changes
    _loadFirstPage();
  }

  void _setFilter(ActivityType? filter) {
    setState(() {
      _selectedFilter = filter;
      _applyFilter();
    });
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
              // Header dengan back button
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
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'All Activities',
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
              
              // Filter Buttons
              if (_allActivities.isNotEmpty)
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: _buildFilterSection(),
                  ),
                ),
                
              // Content
              Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _isLoading
                    ? _buildShimmerLoading()
                    : _allActivities.isEmpty
                        ? SlideTransition(
                            position: _slideAnimation,
                            child: FadeTransition(
                              opacity: _fadeAnimation,
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 120),
                                child: _buildEmptyState(),
                              ),
                            ),
                          )
                        : SlideTransition(
                            position: _slideAnimation,
                            child: FadeTransition(
                              opacity: _fadeAnimation,
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 60),
                                child: _buildActivitiesList(),
                              ),
                            ),
                          ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Icon(
                Icons.timeline,
                size: 64,
                color: Colors.white.withOpacity(0.9),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No activities yet',
              style: TextStyle(
                fontSize: 24,
                color: Colors.white.withOpacity(0.9),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Start your first workout to see your progress here',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 32),
            GestureDetector(
              onTap: () {
                context.go('/running-tracking');
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 255, 255, 255).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.directions_run,
                      color: Colors.white,
                      size: 24,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Start Running',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivitiesList() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _selectedFilter == null 
                ? 'Showing ${_displayedActivities.length} of ${_allActivities.length} activities'
                : 'Showing ${_displayedActivities.length} of ${_filteredActivities.length} ${_selectedFilter!.name} activities',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.8),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refreshActivities,
              color: const Color(0xFF00D4FF),
              backgroundColor: Colors.white,
              child: ListView.builder(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: _displayedActivities.length + (_hasMoreData ? 1 : 0),
                itemBuilder: (context, index) {
                  // Show loading indicator at the end
                  if (index == _displayedActivities.length) {
                    return _buildLoadingIndicator();
                  }
                  
                  final activity = _displayedActivities[index];
                  return AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      final animationValue = Curves.easeOut.transform(
                        ((index * 0.1) + _animationController.value).clamp(0.0, 1.0),
                      );
                      return Transform.translate(
                        offset: Offset(0, 30 * (1 - animationValue)),
                        child: Opacity(
                          opacity: animationValue,
                          child: ExpandableActivityItem(
                            key: ValueKey(activity.id),
                            activity: activity,
                            onDeleted: _loadAllActivities,
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filter by Activity',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.8),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterButton(
                  label: 'All',
                  isSelected: _selectedFilter == null,
                  onTap: () => _setFilter(null),
                  icon: Icons.apps,
                ),
                const SizedBox(width: 12),
                _buildFilterButton(
                  label: 'Running',
                  isSelected: _selectedFilter == ActivityType.running,
                  onTap: () => _setFilter(ActivityType.running),
                  icon: Icons.directions_run,
                ),
                const SizedBox(width: 12),
                _buildFilterButton(
                  label: 'Cycling',
                  isSelected: _selectedFilter == ActivityType.cycling,
                  onTap: () => _setFilter(ActivityType.cycling),
                  icon: Icons.directions_bike,
                ),
                const SizedBox(width: 12),
                _buildFilterButton(
                  label: 'Walking',
                  isSelected: _selectedFilter == ActivityType.walking,
                  onTap: () => _setFilter(ActivityType.walking),
                  icon: Icons.directions_walk,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildFilterButton({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required IconData icon,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected 
              ? const Color(0xFF00D4FF).withOpacity(0.3)
              : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected 
                ? const Color(0xFF00D4FF)
                : Colors.white.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected 
                  ? const Color(0xFF00D4FF)
                  : Colors.white.withOpacity(0.8),
              size: 18,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected 
                    ? const Color(0xFF00D4FF)
                    : Colors.white.withOpacity(0.8),
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Center(
        child: Column(
          children: [
            Container(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white.withOpacity(0.8)),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Loading more activities...',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerItem() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Container(
              height: 110,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1 + 0.05 * ((_animationController.value * 2) % 1)),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Activity icon placeholder
                    Container(
                      width: 45,
                      height: 45,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2 + 0.05 * ((_animationController.value * 2) % 1)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Content placeholder
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            height: 18,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2 + 0.05 * ((_animationController.value * 2) % 1)),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            height: 14,
                            width: 180,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15 + 0.05 * ((_animationController.value * 2) % 1)),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Container(
                                height: 14,
                                width: 70,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.15 + 0.05 * ((_animationController.value * 2) % 1)),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Container(
                                height: 14,
                                width: 70,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.15 + 0.05 * ((_animationController.value * 2) % 1)),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildShimmerLoading() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate how many items can fit based on available height
        final availableHeight = constraints.maxHeight - 40;
        final itemHeight = 110 + 16;
        final maxItems = (availableHeight / itemHeight).floor().clamp(1, 4);
        
        // If there's not enough space for even one shimmer item, show simple loading
        if (availableHeight < itemHeight) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(
                  color: Color(0xFF00D4FF),
                ),
                const SizedBox(height: 16),
                Text(
                  'Loading activities...',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          );
        }
        
        return SingleChildScrollView(
          padding: const EdgeInsets.only(top: 20),
          child: Column(
            children: [
              // Show calculated number of shimmer items
              for (int i = 0; i < maxItems; i++) _buildShimmerItem(),
            ],
          ),
        );
      },
    );
  }

  Future<void> _refreshActivities() async {
    await _loadAllActivities();
  }
}
