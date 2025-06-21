import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../services/notification_api_service.dart';
import '../../widgets/clean_widgets.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen>
    with TickerProviderStateMixin {
  
  final NotificationApiService _apiService = NotificationApiService();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  NotificationSettings? _settings;
  bool _isLoading = true;
  bool _isSaving = false;

  // Controllers for text fields
  final TextEditingController _dailyMessageController = TextEditingController();
  final TextEditingController _weeklyMessageController = TextEditingController();

  // Day names for selection
  final List<String> _dayNames = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
  final List<String> _fullDayNames = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadSettings();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
      ),
    );

    _animationController.forward();
  }

  Future<void> _loadSettings() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final settings = await _apiService.getNotificationSettings(user.uid);
        if (settings != null) {
          setState(() {
            _settings = settings;
            _dailyMessageController.text = settings.dailyReminder.message;
            _weeklyMessageController.text = settings.weeklyProgress.message;
            _isLoading = false;
          });
        } else {
          // Create default settings if none exist
          _createDefaultSettings();
        }
      }
    } catch (e) {
      print('Error loading settings: $e');
      _createDefaultSettings();
    }
  }

  void _createDefaultSettings() {
    setState(() {
      _settings = NotificationSettings(
        dailyReminder: DailyReminder(
          enabled: true,
          time: '07:00',
          message: 'Good morning! Time for your daily workout! 💪',
          days: [1, 2, 3, 4, 5], // Monday to Friday
        ),
        weeklyProgress: WeeklyProgress(
          enabled: true,
          day: 0, // Sunday
          time: '19:00',
          message: 'Check out your weekly progress! 📊',
        ),
        achievementNotifications: true,
        motivationalMessages: true,
      );
      _dailyMessageController.text = _settings!.dailyReminder.message;
      _weeklyMessageController.text = _settings!.weeklyProgress.message;
      _isLoading = false;
    });
  }

  Future<void> _saveSettings() async {
    if (_settings == null || _isSaving) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Update settings with current text field values
        final updatedSettings = _settings!.copyWith(
          dailyReminder: _settings!.dailyReminder.copyWith(
            message: _dailyMessageController.text.trim(),
          ),
          weeklyProgress: _settings!.weeklyProgress.copyWith(
            message: _weeklyMessageController.text.trim(),
          ),
        );

        final success = await _apiService.updateNotificationSettings(user.uid, updatedSettings);
        
        if (success) {
          setState(() {
            _settings = updatedSettings;
          });
          
          // Redirect to profile page after successful save
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              context.go('/profile');
            }
          });
        } else {
          throw Exception('Failed to save settings');
        }
      }
    } catch (e) {
      print('Error saving settings: $e');
      // Just continue without showing notification
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _dailyMessageController.dispose();
    _weeklyMessageController.dispose();
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
          child: _isLoading ? _buildLoadingState() : _buildContent(),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Colors.white),
          SizedBox(height: 16),
          Text(
            'Loading notification settings...',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      children: [
        _buildHeader(),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Column(
                  children: [
                    _buildDailyReminderSection(),
                    const SizedBox(height: 20),
                    _buildWeeklyProgressSection(),
                    const SizedBox(height: 20),
                    _buildOtherNotificationsSection(),
                    const SizedBox(height: 20),
                    _buildSaveButton(),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.only(top: 16.0, left: 20, right: 20),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.go('/profile'),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withOpacity(0.4),
                    Colors.white.withOpacity(0.2),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withOpacity(0.4),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.arrow_back,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Text(
              'Notification Settings',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildDailyReminderSection() {
    if (_settings == null) return const SizedBox();

    return CleanCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF00E676).withOpacity(0.8),
                      const Color(0xFF00E676).withOpacity(0.6),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00E676).withOpacity(0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(Icons.alarm, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              const Text(
                'Daily Reminder',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Enable/Disable Switch
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: const Text(
                  'Enable daily reminders',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
              Switch(
                value: _settings!.dailyReminder.enabled,
                onChanged: (value) {
                  setState(() {
                    _settings = _settings!.copyWith(
                      dailyReminder: _settings!.dailyReminder.copyWith(enabled: value),
                    );
                  });
                },
                activeColor: const Color(0xFF00E676),
              ),
            ],
          ),
          
          if (_settings!.dailyReminder.enabled) ...[
            const SizedBox(height: 16),
            
            // Time Picker
            _buildTimePicker(
              'Reminder Time',
              _settings!.dailyReminder.time,
              (time) {
                setState(() {
                  _settings = _settings!.copyWith(
                    dailyReminder: _settings!.dailyReminder.copyWith(time: time),
                  );
                });
              },
            ),
            
            const SizedBox(height: 16),
            
            // Days Selection
            _buildDaysSelection(),
            
            const SizedBox(height: 16),
            
            // Custom Message
            _buildMessageField(
              'Custom Message',
              _dailyMessageController,
              'Enter your daily reminder message...',
            ),
          ],
        ],
      ),
    );
  }
  Widget _buildWeeklyProgressSection() {
    if (_settings == null) return const SizedBox();

    return CleanCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF2196F3).withOpacity(0.8),
                      const Color(0xFF2196F3).withOpacity(0.6),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2196F3).withOpacity(0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(Icons.calendar_today, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              const Text(
                'Weekly Progress',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Enable/Disable Switch
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: const Text(
                  'Enable weekly progress',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
              Switch(
                value: _settings!.weeklyProgress.enabled,
                onChanged: (value) {
                  setState(() {
                    _settings = _settings!.copyWith(
                      weeklyProgress: _settings!.weeklyProgress.copyWith(enabled: value),
                    );
                  });
                },
                activeColor: const Color(0xFF2196F3),
              ),
            ],
          ),
          
          if (_settings!.weeklyProgress.enabled) ...[
            const SizedBox(height: 16),
            
            // Day Picker
            _buildDayPicker(),
            
            const SizedBox(height: 16),
            
            // Time Picker
            _buildTimePicker(
              'Report Time',
              _settings!.weeklyProgress.time,
              (time) {
                setState(() {
                  _settings = _settings!.copyWith(
                    weeklyProgress: _settings!.weeklyProgress.copyWith(time: time),
                  );
                });
              },
            ),
            
            const SizedBox(height: 16),
            
            // Custom Message
            _buildMessageField(
              'Custom Message',
              _weeklyMessageController,
              'Enter your weekly progress message...',
            ),
          ],
        ],
      ),
    );
  }
  Widget _buildOtherNotificationsSection() {
    if (_settings == null) return const SizedBox();

    return CleanCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF9C27B0).withOpacity(0.8),
                      const Color(0xFF9C27B0).withOpacity(0.6),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF9C27B0).withOpacity(0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(Icons.notifications_active, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              const Text(
                'Other Notifications',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Achievement Notifications
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Achievement Notifications',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                    Text(
                      'Get notified when you unlock achievements',
                      style: TextStyle(fontSize: 12, color: Colors.white70),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _settings!.achievementNotifications,
                onChanged: (value) {
                  setState(() {
                    _settings = _settings!.copyWith(achievementNotifications: value);
                  });
                },
                activeColor: const Color(0xFF9C27B0),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Motivational Messages
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Motivational Messages',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                    Text(
                      'Receive encouraging messages to stay motivated',
                      style: TextStyle(fontSize: 12, color: Colors.white70),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _settings!.motivationalMessages,
                onChanged: (value) {
                  setState(() {
                    _settings = _settings!.copyWith(motivationalMessages: value);
                  });
                },
                activeColor: const Color(0xFF9C27B0),
              ),
            ],
          ),
        ],
      ),
    );
  }





  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: GestureDetector(
        onTap: _isSaving ? null : _saveSettings,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: _isSaving
                  ? [
                      Colors.grey.withOpacity(0.6),
                      Colors.grey.withOpacity(0.4),
                    ]
                  : [
                      const Color(0xFF4CAF50).withOpacity(0.8),
                      const Color(0xFF4CAF50).withOpacity(0.6),
                    ],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: (_isSaving ? Colors.grey : const Color(0xFF4CAF50)).withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: _isSaving
              ? const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Saving...',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                )
              : const Text(
                  'Save Settings',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildTimePicker(String label, String currentTime, Function(String) onTimeChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () async {
            final timeParts = currentTime.split(':');
            final initialTime = TimeOfDay(
              hour: int.parse(timeParts[0]),
              minute: int.parse(timeParts[1]),
            );
            
            final selectedTime = await showTimePicker(
              context: context,
              initialTime: initialTime,
            );
            
            if (selectedTime != null) {
              final formattedTime = '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}';
              onTimeChanged(formattedTime);
            }
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
            ),
            child: Row(
              children: [
                const Icon(Icons.access_time, color: Colors.white70),
                const SizedBox(width: 12),
                Text(
                  currentTime,
                  style: const TextStyle(fontSize: 16, color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDaysSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Reminder Days',
          style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: List.generate(7, (index) {
            final isSelected = _settings!.dailyReminder.days.contains(index);
            return GestureDetector(
              onTap: () {
                setState(() {
                  final days = List<int>.from(_settings!.dailyReminder.days);
                  if (isSelected) {
                    days.remove(index);
                  } else {
                    days.add(index);
                  }
                  _settings = _settings!.copyWith(
                    dailyReminder: _settings!.dailyReminder.copyWith(days: days),
                  );
                });
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            const Color(0xFF00E676).withOpacity(0.8),
                            const Color(0xFF00E676).withOpacity(0.6),
                          ],
                        )
                      : null,
                  color: isSelected ? null : Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF00E676).withOpacity(0.5)
                        : Colors.white.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Center(
                  child: Text(
                    _dayNames[index],
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildDayPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Report Day',
          style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: _settings!.weeklyProgress.day,
              dropdownColor: const Color(0xFF2C2C2C),
              style: const TextStyle(color: Colors.white),
              icon: const Icon(Icons.arrow_drop_down, color: Colors.white70),
              items: List.generate(7, (index) {
                return DropdownMenuItem<int>(
                  value: index,
                  child: Text(
                    _fullDayNames[index],
                    style: const TextStyle(color: Colors.white),
                  ),
                );
              }),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _settings = _settings!.copyWith(
                      weeklyProgress: _settings!.weeklyProgress.copyWith(day: value),
                    );
                  });
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMessageField(String label, TextEditingController controller, String hint) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: 2,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
            filled: true,
            fillColor: Colors.white.withOpacity(0.1),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.white, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}
