// lib/screens/coach/head_coach_only/head_coach_home_screen.dart (or RegularCoachHomeScreen.dart)

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../services/api_service.dart';
import '../../../services/branch_notifier.dart';
import '../../auth/head_coach_login_screen.dart';
import '../shared/registration_requests_screen.dart';
import '../shared/monthly_attendance_screen.dart';
import '../shared/weekly_attendance_screen.dart';
import './payment_management_screen.dart';
import './athletes_list_screen.dart';
import './meets_performance_screen.dart';
import './switch_branch_screen.dart';
import './athletes_measurments_management_screen.dart';
import '../shared/threads.dart';
import '../shared/gear.dart';
import '../coach_profile_screen.dart';
import 'package:intl/intl.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
// Import the NEW screen you want to navigate to first
import 'assign_coaches_screen.dart'; // <--- CHANGE THIS IMPORT (or add if not there)

class RegularCoachHomeScreen extends StatefulWidget {
  const RegularCoachHomeScreen({super.key});

  @override
  State<RegularCoachHomeScreen> createState() => _RegularCoachHomeScreenState();
}

class _RegularCoachHomeScreenState extends State<RegularCoachHomeScreen> {
  Map<String, dynamic>? _user;
  String _name = '';
  String _branchName = '';
  bool _isLoading = true;
  String? _error;
  int _selectedIndex = 0;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedIndex);
    _loadUserData();

    BranchNotifier().addListener(_onBranchChangedInHome);
  }

  @override
  void dispose() {
    _pageController.dispose();
    BranchNotifier().removeListener(_onBranchChangedInHome);
    super.dispose();
  }

  void _onBranchChangedInHome() {
    print('🔄 Home screen detected branch change');
    if (mounted) {
      final newBranchName = BranchNotifier().currentBranchName;
      if (newBranchName != null) {
        setState(() {
          _branchName = newBranchName;
        });
      }
    }
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await ApiService.getUserProfile();
      if (result['success']) {
        final userData = result['data'];
        setState(() {
          _user = userData;
          _name = userData['name'] ?? '';
        });

        await _loadBranchInfo(userData['branch_id']);
      } else {
        setState(() {
          _error = AppLocalizations.of(context)!.failedToLoadProfile;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = AppLocalizations.of(context)!.failedToLoadProfile;
        _isLoading = false;
      });
    }
  }

  // ✅ FIXED: Replace _loadBranchInfo in your RegularCoachHomeScreen

  Future<void> _loadBranchInfo(int? branchId) async {
    if (branchId == null) {
      setState(() {
        _branchName = 'No Branch Assigned';
        _isLoading = false;
      });
      return;
    }

    try {
      print('🔄 Loading branch info for ID: $branchId');

      // ✅ Method 1: Try the optimized branch name endpoint first
      final nameResult = await ApiService.getBranchName(branchId);
      if (nameResult['success'] && nameResult['data'] != null) {
        final branchName = nameResult['data']['name'] ?? 'Unknown Branch';
        setState(() {
          _branchName = branchName;
          _isLoading = false;
        });
        BranchNotifier().updateBranch(branchId, branchName);
        print('✅ Branch name loaded via name endpoint: $branchName');
        return;
      }

      // ✅ Method 2: Fallback to full branch details
      final detailsResult = await ApiService.getBranchDetails(branchId);
      if (detailsResult['success'] && detailsResult['data'] != null) {
        final branchName = detailsResult['data']['name'] ?? 'Unknown Branch';
        setState(() {
          _branchName = branchName;
          _isLoading = false;
        });
        BranchNotifier().updateBranch(branchId, branchName);
        print('✅ Branch name loaded via details endpoint: $branchName');
        return;
      }

      // ✅ Method 3: Final fallback - get from branches list
      print('⚠️ Both name and details failed, trying branches list...');
      final branchesResult = await ApiService.getAllBranches();
      if (branchesResult['success']) {
        final branches = List<Map<String, dynamic>>.from(
          branchesResult['data'] ?? [],
        );
        final branch = branches.firstWhere(
          (b) => b['id'] == branchId,
          orElse: () => {'name': 'Branch #$branchId'},
        );
        final branchName = branch['name'] ?? 'Branch #$branchId';
        setState(() {
          _branchName = branchName;
          _isLoading = false;
        });
        BranchNotifier().updateBranch(branchId, branchName);
        print('✅ Branch name from branches list: $branchName');
        return;
      }

      // ✅ Ultimate fallback
      setState(() {
        _branchName = 'Branch #$branchId';
        _isLoading = false;
      });
      BranchNotifier().updateBranch(branchId, 'Branch #$branchId');
      print('⚠️ Using fallback branch name: Branch #$branchId');
    } catch (e) {
      print('❌ Error loading branch info: $e');
      setState(() {
        _branchName = 'Branch #$branchId';
        _isLoading = false;
      });
      BranchNotifier().updateBranch(branchId, 'Branch #$branchId');
    }
  }

  String get _firstName {
    if (_name.isEmpty) return '';
    return _name.split(' ')[0];
  }

  void _navigateToRegistrationRequests() {
    HapticFeedback.lightImpact();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const RegistrationRequestsScreen(),
      ),
    );
  }

  void _navigateToWeeklyAttendance() {
    HapticFeedback.lightImpact();
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const WeeklyAttendanceScreen()),
    );
  }

  void _navigateToMonthlyAttendance() {
    HapticFeedback.lightImpact();
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const MonthlyAttendanceScreen()),
    );
  }

  void _navigateToPaymentManagement() {
    HapticFeedback.lightImpact();
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const PaymentManagementScreen()),
    );
  }

  void _navigateToAthletesList() {
    HapticFeedback.lightImpact();
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const AthletesListScreen()));
  }

  void _navigateToPerformanceLogs() {
    HapticFeedback.lightImpact();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const PerformanceLogsManagementScreen(),
      ),
    );
  }

  void _navigateToAthletesMeasurements() {
    HapticFeedback.lightImpact();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const AthletesMeasurementsManagementScreen(),
      ),
    );
  }

  void _navigateToSwitchBranch() async {
    HapticFeedback.lightImpact();
    final result = await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const SwitchBranchScreen()));

    if (result == true && mounted) {
      print('🔄 Branch switch detected, reloading home screen data');
      await _loadUserData();
    }
  }

  // 👇 UPDATE THIS NAVIGATION METHOD to go to AssignCoachesScreen
  void _navigateToCoachAssignment() {
    HapticFeedback.lightImpact();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (context) =>
                const AssignCoachesScreen(), // <--- NAVIGATE TO ASSIGNCOACHESSCREEN
      ),
    );
  }

  void _showComingSoon(String feature) {
    final s = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(s.featureComingSoon(feature)),
        backgroundColor: Colors.blue,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      _pageController.jumpToPage(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context)!;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF0F2F5),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: Color(0xFF007AFF)),
              const SizedBox(height: 16),
              Text(s.loadingDashboard, style: const TextStyle(fontSize: 16)),
            ],
          ),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF0F2F5),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                _error!,
                style: const TextStyle(fontSize: 16, color: Colors.red),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(onPressed: _loadUserData, child: Text(s.retry)),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        children: [
          _buildHomeScreenContent(),
          const ThreadsScreen(),
          const GearScreen(),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: [
          BottomNavigationBarItem(icon: const Icon(Icons.home), label: s.home),
          BottomNavigationBarItem(
            icon: const Icon(Icons.chat),
            label: s.threads,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.inventory),
            label: s.gear,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.account_circle),
            label: s.profile,
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: const Color(0xFF007AFF),
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        elevation: 10,
      ),
    );
  }

  Widget _buildHomeScreenContent() {
    final s = AppLocalizations.of(context)!;
    return Column(
      children: [
        // Beautiful Header Section
        Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF007AFF), Color(0xFF0066CC), Color(0xFF0052A3)],
            ),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(30),
              bottomRight: Radius.circular(30),
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Welcome Text
                  Text(
                    s.welcome(_firstName),
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    s.coachDashboard,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.9),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Branch Info Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.location_on,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Current Branch',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _branchName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: _navigateToSwitchBranch,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.swap_horiz,
                              color: Colors.white,
                              size: 18,
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
        ),

        // Scrollable Content
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [_buildToolsGrid(), const SizedBox(height: 40)],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildToolsGrid() {
    final s = AppLocalizations.of(context)!;
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.1,
      children: [
        _buildToolCard(
          title: s.registrationRequests,
          onTap: _navigateToRegistrationRequests,
          color: Colors.green,
        ),
        _buildToolCard(
          title: s.attendance,
          onTap: _navigateToWeeklyAttendance,
          color: Colors.teal,
        ),
        _buildToolCard(
          title: s.attendanceCalendar,
          onTap: _navigateToMonthlyAttendance,
          color: Colors.green,
          isAttendanceCalendar: true,
          icon: '📅',
        ),
        _buildToolCard(
          title: s.athletesList,
          onTap: _navigateToAthletesList,
          color: Colors.indigo,
          isAthletesList: true,
          icon: '👥',
        ),
        _buildToolCard(
          title: s.swimMeetPerformance,
          onTap: _navigateToPerformanceLogs,
          color: Colors.red,
          isSwimMeetPerformance: true,
          icon: '🏊‍♂️',
        ),
        _buildToolCard(
          title: s.athletesMeasurements, // Updated to use localized string
          onTap: _navigateToAthletesMeasurements,
          color: Colors.deepPurple,
          isAthletesMeasurements: true,
          icon: '📏',
        ),
        _buildToolCard(
          title: s.payments,
          onTap: _navigateToPaymentManagement,
          color: Colors.amber,
          isPayments: true,
          icon: '💳',
        ),
        _buildToolCard(
          title: s.switchBranch,
          onTap: _navigateToSwitchBranch,
          color: Colors.orange,
          isSwitchBranch: true,
          icon: '🔄',
        ),
        _buildToolCard(
          title: s.attendanceSeason,
          onTap: () => _showComingSoon(s.attendanceSeason),
          color: Colors.purple,
          isAttendanceSeason: true,
        ),
        _buildToolCard(
          title: s.coachBranchAssignment, // Updated to use localized string
          onTap: _navigateToCoachAssignment,
          color: Colors.blueGrey,
          icon: '🧑‍🏫',
        ),
      ],
    );
  }

  Widget _buildToolCard({
    required String title,
    required VoidCallback onTap,
    required Color color,
    bool isPerformance = false,
    bool isAttendanceSeason = false,
    bool isAttendanceCalendar = false,
    bool isPayments = false,
    bool isAthletesList = false,
    bool isSwimMeetPerformance = false,
    bool isSwitchBranch = false,
    bool isAthletesMeasurements = false,
    String? icon,
  }) {
    Color backgroundColor = Colors.white;
    Color borderColor = Colors.transparent;
    Color textColor = Colors.black;
    double borderWidth = 0;

    if (isAttendanceSeason) {
      backgroundColor = Colors.white;
      borderColor = Colors.black;
      borderWidth = 2;
      textColor = Colors.black;
    } else if (isAttendanceCalendar) {
      backgroundColor = Colors.white;
      borderColor = const Color(0xFF34C759);
      borderWidth = 2;
      textColor = const Color(0xFF34C759);
    } else if (isPayments) {
      backgroundColor = Colors.white;
      borderColor = Colors.amber;
      borderWidth = 2;
      textColor = Colors.amber[700]!;
    } else if (isAthletesList) {
      backgroundColor = Colors.white;
      borderColor = Colors.indigo;
      borderWidth = 2;
      textColor = Colors.indigo[700]!;
    } else if (isSwimMeetPerformance) {
      backgroundColor = Colors.white;
      borderColor = Colors.red;
      borderWidth = 2;
      textColor = Colors.red[700]!;
    } else if (isSwitchBranch) {
      backgroundColor = Colors.white;
      borderColor = Colors.orange;
      borderWidth = 2;
      textColor = Colors.orange[700]!;
    } else if (isAthletesMeasurements) {
      backgroundColor = Colors.white;
      borderColor = Colors.deepPurple;
      borderWidth = 2;
      textColor = Colors.deepPurple[700]!;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(16),
          border:
              borderWidth > 0
                  ? Border.all(color: borderColor, width: borderWidth)
                  : null,
          boxShadow: [
            BoxShadow(
              color:
                  isAttendanceCalendar
                      ? const Color(0xFF34C759).withOpacity(0.15)
                      : isPayments
                      ? Colors.amber.withOpacity(0.15)
                      : isAthletesList
                      ? Colors.indigo.withOpacity(0.15)
                      : isSwimMeetPerformance
                      ? Colors.red.withOpacity(0.15)
                      : isSwitchBranch
                      ? Colors.orange.withOpacity(0.15)
                      : isAthletesMeasurements
                      ? Colors.deepPurple.withOpacity(0.15)
                      : Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
              textAlign: TextAlign.center,
            ),
            if (icon != null) ...[
              const SizedBox(height: 6),
              Text(icon, style: const TextStyle(fontSize: 22)),
            ],
          ],
        ),
      ),
    );
  }
}
