import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../services/api_service.dart';
import '../../../services/branch_notifier.dart'; // ✅ ADD THIS

class SwitchBranchScreen extends StatefulWidget {
  const SwitchBranchScreen({super.key});

  @override
  State<SwitchBranchScreen> createState() => _SwitchBranchScreenState();
}

class _SwitchBranchScreenState extends State<SwitchBranchScreen>
    with TickerProviderStateMixin {
  List<Map<String, dynamic>> _branches = [];
  Map<String, dynamic>? _currentBranch;
  bool _isLoading = true;
  bool _isSwitching = false;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadBranchesAndCurrentBranch();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
  }

  Future<void> _loadBranchesAndCurrentBranch() async {
    setState(() => _isLoading = true);

    try {
      final branchesResult = await ApiService.getAllBranches();
      final profileResult = await ApiService.getUserProfile();

      if (branchesResult['success'] && profileResult['success']) {
        setState(() {
          _branches = List<Map<String, dynamic>>.from(
            branchesResult['data'] ?? [],
          );
          _currentBranch = _branches.firstWhere(
            (branch) => branch['id'] == profileResult['data']['branch_id'],
            orElse: () => _branches.isNotEmpty ? _branches.first : {},
          );
        });
        _fadeController.forward();
      } else {
        _showError('Failed to load branches');
      }
    } catch (e) {
      print('❌ Error loading branches: $e');
      _showError('Failed to load branch data');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ✅ SIMPLE SOLUTION: Replace _switchToBranch with this quick login approach

  Future<void> _switchToBranch(Map<String, dynamic> branch) async {
    if (branch['id'] == _currentBranch?['id']) {
      _showInfo('You are already managing ${branch['name']}');
      return;
    }

    final confirmed =
        await showDialog<bool>(
          context: context,
          builder:
              (context) => AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                title: Text(
                  'Switch to ${branch['name']}?',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                content: Text(
                  'This will reload the app with ${branch['name']} data.',
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: Color(0xFF007AFF)),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF007AFF),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Switch'),
                  ),
                ],
              ),
        ) ??
        false;

    if (!confirmed) return;

    setState(() => _isSwitching = true);

    try {
      print(
        '🔄 QUICK LOGIN: Switching to branch ${branch['id']} (${branch['name']})',
      );

      // ✅ STEP 1: Get branch-specific credentials
      final branchCredentials = _getBranchCredentials(branch['id']);

      if (branchCredentials == null) {
        _showError('Branch credentials not found for ${branch['name']}');
        return;
      }

      print('🔄 QUICK LOGIN: Using credentials for branch ${branch['id']}');

      // ✅ STEP 2: Quick login with branch credentials
      final loginResult = await ApiService.login(
        branchCredentials['email']!,
        branchCredentials['password']!,
      );

      if (loginResult['success']) {
        print('✅ QUICK LOGIN: Successfully logged into ${branch['name']}');

        // ✅ STEP 3: Update BranchNotifier immediately
        BranchNotifier().updateBranch(
          branch['id'],
          branch['name'] ?? 'Unknown Branch',
        );

        _showSuccess('Switched to ${branch['name']}');
        HapticFeedback.lightImpact();

        // ✅ STEP 4: Navigate to home and replace entire navigation stack
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            // Clear the entire navigation stack and go to home
            Navigator.of(context).pushNamedAndRemoveUntil(
              '/home', // Your home route name
              (route) => false, // Remove all previous routes
            );
          }
        });
      } else {
        final error = loginResult['error'] ?? 'Login failed';
        print('❌ QUICK LOGIN: Failed - $error');
        _showError('Failed to switch to ${branch['name']}: $error');
      }
    } catch (e) {
      print('❌ QUICK LOGIN: Exception - $e');
      _showError('Network error occurred while switching branch');
    } finally {
      setState(() => _isSwitching = false);
    }
  }

  // ✅ STEP 5: Add this method to store branch credentials
  Map<String, String>? _getBranchCredentials(int branchId) {
    // 🔐 HARDCODED BRANCH CREDENTIALS
    // Replace these with your actual branch account credentials
    final branchCredentials = <int, Map<String, String>>{
      1: {'email': 'hadayek@gmail.com', 'password': 'MmmM1234'},
      2: {'email': 'maadi@gmail.com', 'password': 'MmmM1234'},
      3: {'email': 'newcairo@gmail.com', 'password': 'MmmM1234'},
      4: {'email': 'october@gmail.com', 'password': 'MmmM1234'},
      5: {'email': 'nasrcity@gmail.com', 'password': 'MmmM1234'},
      // Add more branches as needed
    };

    return branchCredentials[branchId];
  }

  // ✅ OPTIONAL: Add this method for even better UX
  Future<void> _quickSwitchWithLoadingOverlay(
    Map<String, dynamic> branch,
  ) async {
    // Show full-screen loading overlay
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => WillPopScope(
            onWillPop: () async => false,
            child: Container(
              color: Colors.black.withOpacity(0.8),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(
                      color: Color(0xFF007AFF),
                      strokeWidth: 3,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Switching to ${branch['name']}...',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Please wait while we load the branch data',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          ),
    );

    // Perform the quick login
    await _switchToBranch(branch);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(message, style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(message, style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF007AFF),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _showInfo(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(message, style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF007AFF),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      appBar: AppBar(
        title: const Text(
          'Switch Branch',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF007AFF),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadBranchesAndCurrentBranch,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Color(0xFF007AFF)),
                    SizedBox(height: 16),
                    Text('Loading branches...', style: TextStyle(fontSize: 16)),
                  ],
                ),
              )
              : FadeTransition(opacity: _fadeAnimation, child: _buildContent()),
    );
  }

  Widget _buildContent() {
    if (_branches.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_off, size: 64, color: Colors.grey[600]),
            const SizedBox(height: 16),
            const Text(
              'No Branches Available',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'No branches are configured in the system.',
              style: TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _branches.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return _currentBranch != null
              ? _buildCurrentBranchHeader()
              : const SizedBox.shrink();
        }
        final branch = _branches[index - 1];
        final isCurrentBranch = branch['id'] == _currentBranch?['id'];
        return _buildBranchCard(branch, isCurrentBranch);
      },
    );
  }

  Widget _buildCurrentBranchHeader() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.location_on,
                    color: Color(0xFF007AFF),
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _currentBranch?['name'] ?? 'Unknown Branch',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Current Branch',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBranchCard(Map<String, dynamic> branch, bool isCurrentBranch) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side:
            isCurrentBranch
                ? const BorderSide(color: Color(0xFF007AFF), width: 2)
                : BorderSide.none,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap:
            isCurrentBranch || _isSwitching
                ? null
                : () => _switchToBranch(branch),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor:
                    isCurrentBranch
                        ? const Color(0xFF007AFF)
                        : const Color(0xFF007AFF).withOpacity(0.2),
                child: const Icon(
                  Icons.location_on,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      branch['name'] ?? 'Unknown Branch',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    if (branch['address'] != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        branch['address'],
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              if (isCurrentBranch)
                Chip(
                  label: const Text(
                    'Active',
                    style: TextStyle(color: Color(0xFF007AFF), fontSize: 12),
                  ),
                  backgroundColor: const Color(0xFF007AFF).withOpacity(0.1),
                )
              else if (_isSwitching)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Color(0xFF007AFF),
                    strokeWidth: 2,
                  ),
                )
              else
                IconButton(
                  icon: const Icon(
                    Icons.info_outline,
                    color: Color(0xFF007AFF),
                  ),
                  onPressed:
                      () => showDialog(
                        context: context,
                        builder:
                            (context) => AlertDialog(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              title: Text(
                                branch['name'] ?? 'Branch Details',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              content: SingleChildScrollView(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (branch['address'] != null)
                                      ListTile(
                                        leading: const Icon(
                                          Icons.location_on,
                                          color: Color(0xFF007AFF),
                                        ),
                                        title: Text(
                                          branch['address'],
                                          style: const TextStyle(fontSize: 16),
                                        ),
                                      ),
                                    if (branch['phone'] != null)
                                      ListTile(
                                        leading: const Icon(
                                          Icons.phone,
                                          color: Color(0xFF007AFF),
                                        ),
                                        title: Text(
                                          branch['phone'],
                                          style: const TextStyle(fontSize: 16),
                                        ),
                                      ),
                                    if (branch['practice_days'] != null)
                                      ListTile(
                                        leading: const Icon(
                                          Icons.calendar_today,
                                          color: Color(0xFF007AFF),
                                        ),
                                        title: Text(
                                          'Practice Days: ${branch['practice_days']}',
                                          style: const TextStyle(fontSize: 16),
                                        ),
                                      ),
                                    ListTile(
                                      leading: const Icon(
                                        Icons.tag,
                                        color: Color(0xFF007AFF),
                                      ),
                                      title: Text(
                                        'Branch ID: ${branch['id']}',
                                        style: const TextStyle(fontSize: 16),
                                      ),
                                    ),
                                    if (branch['video_url'] != null)
                                      ListTile(
                                        leading: const Icon(
                                          Icons.video_library,
                                          color: Color(0xFF007AFF),
                                        ),
                                        title: Text(
                                          'Video URL: ${branch['video_url']}',
                                          style: const TextStyle(fontSize: 16),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: const Text(
                                    'Close',
                                    style: TextStyle(color: Color(0xFF007AFF)),
                                  ),
                                ),
                              ],
                            ),
                      ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
