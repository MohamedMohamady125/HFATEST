// lib/widgets/current_branch_widget.dart

import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/branch_notifier.dart';

class CurrentBranchWidget extends StatefulWidget {
  const CurrentBranchWidget({super.key});

  @override
  State<CurrentBranchWidget> createState() => _CurrentBranchWidgetState();
}

class _CurrentBranchWidgetState extends State<CurrentBranchWidget> {
  String _currentBranchName = 'Loading...';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentBranch();
    // Listen to branch changes
    BranchNotifier().addListener(_onBranchChanged);
  }

  @override
  void dispose() {
    BranchNotifier().removeListener(_onBranchChanged);
    super.dispose();
  }

  void _onBranchChanged() {
    print('🔄 CurrentBranchWidget: Branch change detected');
    if (mounted) {
      _loadCurrentBranch();
    }
  }

  Future<void> _loadCurrentBranch() async {
    try {
      // Method 1: Check BranchNotifier cache first
      final cachedName = BranchNotifier().currentBranchName;
      if (cachedName != null && cachedName.isNotEmpty) {
        setState(() {
          _currentBranchName = cachedName;
          _isLoading = false;
        });
        print('✅ CurrentBranchWidget: Using cached name: $cachedName');
        return;
      }

      // Method 2: Get fresh user profile
      final profileResult = await ApiService.getUserProfile();
      if (profileResult['success'] && profileResult['data'] != null) {
        final branchId = profileResult['data']['branch_id'];

        if (branchId != null) {
          await _fetchBranchName(branchId);
        } else {
          setState(() {
            _currentBranchName = 'No Branch Assigned';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _currentBranchName = 'Error Loading Branch';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ CurrentBranchWidget: Error loading branch: $e');
      setState(() {
        _currentBranchName = 'Error Loading Branch';
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchBranchName(int branchId) async {
    try {
      // Try the optimized branch name endpoint
      final nameResult = await ApiService.getBranchName(branchId);
      if (nameResult['success'] && nameResult['data']?['name'] != null) {
        final branchName = nameResult['data']['name'].toString().trim();
        setState(() {
          _currentBranchName = branchName;
          _isLoading = false;
        });
        // Update cache
        BranchNotifier().updateBranch(branchId, branchName);
        print('✅ CurrentBranchWidget: Loaded name via API: $branchName');
        return;
      }

      // Fallback to branch details
      final detailsResult = await ApiService.getBranchDetails(branchId);
      if (detailsResult['success'] && detailsResult['data']?['name'] != null) {
        final branchName = detailsResult['data']['name'].toString().trim();
        setState(() {
          _currentBranchName = branchName;
          _isLoading = false;
        });
        // Update cache
        BranchNotifier().updateBranch(branchId, branchName);
        print('✅ CurrentBranchWidget: Loaded name via details: $branchName');
        return;
      }

      // Final fallback
      setState(() {
        _currentBranchName = 'Branch #$branchId';
        _isLoading = false;
      });
    } catch (e) {
      print('❌ CurrentBranchWidget: Error fetching branch name: $e');
      setState(() {
        _currentBranchName = 'Branch #$branchId';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF007AFF).withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF007AFF).withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icon
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF007AFF).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.location_on,
              color: Color(0xFF007AFF),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Currently Managing',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                _isLoading
                    ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFF007AFF),
                      ),
                    )
                    : Text(
                      _currentBranchName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF007AFF),
                      ),
                    ),
              ],
            ),
          ),

          // Refresh button
          IconButton(
            onPressed: _isLoading ? null : _loadCurrentBranch,
            icon: Icon(
              Icons.refresh,
              color: _isLoading ? Colors.grey : const Color(0xFF007AFF),
              size: 18,
            ),
            tooltip: 'Refresh',
          ),
        ],
      ),
    );
  }
}
