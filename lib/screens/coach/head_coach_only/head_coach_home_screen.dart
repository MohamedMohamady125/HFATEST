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
import 'assign_coaches_screen.dart';
import '../../../widgets/current_branch_widget.dart';

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

  void _navigateToCoachAssignment() {
    HapticFeedback.lightImpact();
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const AssignCoachesScreen()),
    );
  }

  void _showComingSoon(String feature) {
    final s = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(s.featureComingSoon(feature)),
        backgroundColor: Colors.blue,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
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
        backgroundColor: const Color(0xFFF5F7FA),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: Color(0xFF1E88E5)),
              const SizedBox(height: 20),
              Text(
                s.loadingDashboard,
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 80,
                color: Colors.redAccent,
              ),
              const SizedBox(height: 20),
              Text(
                _error!,
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.redAccent,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loadUserData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E88E5),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  s.retry,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
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
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.home, size: 28),
              label: s.home,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.chat, size: 28),
              label: s.threads,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.inventory, size: 28),
              label: s.gear,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.account_circle, size: 28),
              label: s.profile,
            ),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: const Color(0xFF1E88E5),
          unselectedItemColor: Colors.grey[600],
          selectedLabelStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w400,
          ),
          onTap: _onItemTapped,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          elevation: 0,
        ),
      ),
    );
  }

  Widget _buildHomeScreenContent() {
    final s = AppLocalizations.of(context)!;
    return Column(
      children: [
        Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1976D2), Color(0xFF1E88E5), Color(0xFF42A5F5)],
            ),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(40),
              bottomRight: Radius.circular(40),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 36),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s.welcome(_firstName),
                              style: const TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              s.coachDashboard,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white.withOpacity(0.85),
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _buildSmallBranchWidget(),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [_buildToolsGrid(), const SizedBox(height: 48)],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSmallBranchWidget() {
    return GestureDetector(
      onTap: _navigateToSwitchBranch,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.25),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.4), width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.location_on_outlined,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              BranchNotifier().currentBranchName ?? _branchName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolsGrid() {
    final s = AppLocalizations.of(context)!;
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 20,
      crossAxisSpacing: 20,
      childAspectRatio: 1.2,
      children: [
        _buildToolCard(
          title: s.registrationRequests,
          onTap: _navigateToRegistrationRequests,
          color: const Color(0xFF4CAF50),
          icon: Icons.person_add,
        ),
        _buildToolCard(
          title: s.attendance,
          onTap: _navigateToWeeklyAttendance,
          color: const Color(0xFF26A69A),
          icon: Icons.check_circle,
        ),
        _buildToolCard(
          title: s.attendanceCalendar,
          onTap: _navigateToMonthlyAttendance,
          color: const Color(0xFF4CAF50),
          icon: Icons.calendar_today,
          isAttendanceCalendar: true,
        ),
        _buildToolCard(
          title: s.athletesList,
          onTap: _navigateToAthletesList,
          color: const Color(0xFF3F51B5),
          icon: Icons.group,
          isAthletesList: true,
        ),
        _buildToolCard(
          title: s.swimMeetPerformance,
          onTap: _navigateToPerformanceLogs,
          color: const Color(0xFFF44336),
          icon: Icons.pool,
          isSwimMeetPerformance: true,
        ),
        _buildToolCard(
          title: s.athletesMeasurements,
          onTap: _navigateToAthletesMeasurements,
          color: const Color(0xFF7E57C2),
          icon: Icons.straighten,
          isAthletesMeasurements: true,
        ),
        _buildToolCard(
          title: s.payments,
          onTap: _navigateToPaymentManagement,
          color: const Color(0xFFFFA000),
          icon: Icons.payment,
          isPayments: true,
        ),
        _buildToolCard(
          title: s.switchBranch,
          onTap: _navigateToSwitchBranch,
          color: const Color(0xFFFF9800),
          icon: Icons.swap_horiz,
          isSwitchBranch: true,
        ),
        _buildToolCard(
          title: s.attendanceSeason,
          onTap: () => _showComingSoon(s.attendanceSeason),
          color: const Color(0xFFAB47BC),
          icon: Icons.event,
          isAttendanceSeason: true,
        ),
        _buildToolCard(
          title: s.coachBranchAssignment,
          onTap: _navigateToCoachAssignment,
          color: const Color(0xFF78909C),
          icon: Icons.supervisor_account,
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
    IconData? icon,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: color.withOpacity(0.3), width: 1.5),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onTap,
            splashColor: color.withOpacity(0.1),
            highlightColor: color.withOpacity(0.05),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 32, color: color),
                  const SizedBox(height: 12),
                ],
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
