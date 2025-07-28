import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../services/auth_services.dart'; // Add this import

class ApiService {
  // Replace with your actual backend URL
  static const String baseUrl =
      'https://marvelous-tranquility.railway.internal';
      
  static const _storage = FlutterSecureStorage();

  // Make storage accessible for other classes
  static FlutterSecureStorage get storage => _storage;

  // Get headers with auth token
  // Replace your _getHeaders() method in ApiService with this:

  static Future<Map<String, String>> _getHeaders() async {
    // Try to get token from storage
    final token = await _storage.read(key: 'auth_token');

    print(
      '🔍 _getHeaders() - Token from storage: ${token != null ? 'Available (${token.substring(0, 20)}...)' : 'Missing'}',
    );

    // If no token, check if we should try to get login data from AuthService
    if (token == null) {
      print('❌ No token in ApiService storage, checking AuthService...');
      try {
        // Import your AuthService and check its data
        final loginData = await AuthService.getLoginData();
        print('🔍 AuthService data: $loginData');

        if (loginData['token'] != null) {
          // Store the token in ApiService storage
          await _storage.write(key: 'auth_token', value: loginData['token']);
          await _storage.write(key: 'user_type', value: loginData['user_type']);
          await _storage.write(key: 'user_id', value: loginData['user_id']);

          print('✅ Synced token from AuthService to ApiService');

          final headers = {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${loginData['token']}',
          };

          print('🔍 _getHeaders() - Final headers: ${headers.keys.toList()}');
          return headers;
        }
      } catch (e) {
        print('❌ Error syncing from AuthService: $e');
      }
    }

    final headers = {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };

    print('🔍 _getHeaders() - Final headers: ${headers.keys.toList()}');
    return headers;
  }

  // Add these methods to your ApiService class

  // =================== INVITE LINK ENDPOINTS ===================

  // Replace ALL your invite methods in ApiService with these complete versions:

  static Future<Map<String, dynamic>> createInviteLink() async {
    try {
      print('🔗 Creating invite link...');
      final headers = await _getHeaders();

      final response = await http.post(
        Uri.parse('$baseUrl/users/invite/create'), // ✅ FIXED: Added /users
        headers: headers,
      );

      print('🔗 Create invite response: ${response.statusCode}');
      print('🔗 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return {
          'success': responseData['success'] ?? true,
          'invite_token': responseData['invite_token'],
          'invite_url': responseData['invite_url'],
          'expires_at': responseData['expires_at'],
        };
      } else {
        return {
          'success': false,
          'error': 'HTTP ${response.statusCode}: ${response.body}',
        };
      }
    } catch (e) {
      print('❌ Error creating invite link: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> loginWithInvite(
    String inviteToken,
  ) async {
    try {
      print('🔗 Logging in with invite token: $inviteToken');

      final response = await http.post(
        Uri.parse('$baseUrl/users/invite/login'), // ✅ FIXED: Added /users
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'invite_token': inviteToken}),
      );

      print('🔗 Invite login response: ${response.statusCode}');
      print('🔗 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Store the auth token
        if (data['token'] != null) {
          await _storage.write(key: 'auth_token', value: data['token']);

          // Store user info
          final userType = data['user']?['role']?.toString() ?? 'athlete';
          await _storage.write(key: 'user_type', value: userType);
          await _storage.write(
            key: 'user_id',
            value: data['user']?['id']?.toString() ?? '',
          );

          print('🔗 Stored user_type: $userType');
        }

        return {
          'success': data['success'] ?? true,
          'data': {
            'access_token': data['token'],
            'user_type': data['user']?['role'],
            'user_id': data['user']?['id'],
            'user': data['user'],
          },
          'message': data['message'],
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'error': errorData['detail'] ?? 'Login with invite failed',
        };
      }
    } catch (e) {
      print('❌ Error logging in with invite: $e');
      return {
        'success': false,
        'error': 'Network error. Please check your connection.',
      };
    }
  }

  static Future<Map<String, dynamic>> validateInviteToken(String token) async {
    try {
      print('🔗 Validating invite token: $token');

      final response = await http.get(
        Uri.parse(
          '$baseUrl/users/invite/validate/$token',
        ), // ✅ FIXED: Added /users
        headers: {'Content-Type': 'application/json'},
      );

      print('🔗 Validate invite response: ${response.statusCode}');
      print('🔗 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return {
          'success': true,
          'valid': responseData['valid'],
          'user_name': responseData['user_name'],
          'user_email': responseData['user_email'],
          'user_role': responseData['user_role'],
          'expires_at': responseData['expires_at'],
          'message': responseData['message'],
        };
      } else {
        return {
          'success': false,
          'error': 'HTTP ${response.statusCode}: ${response.body}',
        };
      }
    } catch (e) {
      print('❌ Error validating invite token: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> getMyInviteLinks() async {
    try {
      print('🔗 Getting my invite links...');
      final headers = await _getHeaders();

      final response = await http.get(
        Uri.parse('$baseUrl/users/invite/my-links'), // ✅ FIXED: Added /users
        headers: headers,
      );

      print('🔗 My invite links response: ${response.statusCode}');
      print('🔗 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return {
          'success': responseData['success'] ?? true,
          'invite_links': responseData['invite_links'] ?? [],
        };
      } else {
        return {
          'success': false,
          'error': 'HTTP ${response.statusCode}: ${response.body}',
        };
      }
    } catch (e) {
      print('❌ Error getting invite links: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> invalidateInviteLink(String token) async {
    try {
      print('🔗 Invalidating invite link: $token');
      final headers = await _getHeaders();

      final response = await http.delete(
        Uri.parse('$baseUrl/users/invite/$token'), // ✅ FIXED: Added /users
        headers: headers,
      );

      print('🔗 Invalidate invite response: ${response.statusCode}');
      print('🔗 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return {
          'success': responseData['success'] ?? true,
          'message': responseData['message'],
        };
      } else {
        return {
          'success': false,
          'error': 'HTTP ${response.statusCode}: ${response.body}',
        };
      }
    } catch (e) {
      print('❌ Error invalidating invite link: $e');
      return {'success': false, 'error': e.toString()};
    }
  }
  // =================== AUTH ENDPOINTS ===================

  static Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      print('Login response status: ${response.statusCode}');
      print('Login response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('Parsed data: $data');

        // Your backend returns "token" not "access_token"
        if (data['token'] != null) {
          await _storage.write(key: 'auth_token', value: data['token']);

          // Your backend returns user.role not user_type
          final userType = data['user']?['role']?.toString() ?? 'athlete';
          await _storage.write(key: 'user_type', value: userType);
          await _storage.write(
            key: 'user_id',
            value: data['user']?['id']?.toString() ?? '',
          );

          print('Stored user_type: $userType');
        }

        // Return the data with normalized field names for consistency
        return {
          'success': true,
          'data': {
            'access_token': data['token'],
            'user_type': data['user']?['role'],
            'user_id': data['user']?['id'],
            'user': data['user'],
          },
        };
      } else {
        return {'success': false, 'error': 'Login failed'};
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // Add this enhanced registration method to your ApiService class

  // =================== ENHANCED REGISTRATION ENDPOINT ===================

  static Future<Map<String, dynamic>> register(
    Map<String, dynamic> userData,
  ) async {
    try {
      print('🔄 Starting athlete registration...');

      // Create a copy for logging without password
      final logData = Map<String, dynamic>.from(userData);
      logData.remove('password');
      print('🔄 Registration data: $logData');

      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(userData), // Send original data with password
      );

      print('🔄 Registration response status: ${response.statusCode}');
      print('🔄 Registration response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        print('✅ Registration successful');
        return {
          'success': true,
          'data': responseData,
          'message':
              responseData['message'] ??
              'Registration request submitted successfully',
        };
      } else if (response.statusCode == 400) {
        // Handle validation errors
        final errorData = jsonDecode(response.body);
        String errorMessage = 'Registration failed';

        if (errorData['detail'] != null) {
          errorMessage = errorData['detail'];
        } else if (errorData['message'] != null) {
          errorMessage = errorData['message'];
        }

        print('❌ Registration validation error: $errorMessage');
        return {'success': false, 'error': errorMessage};
      } else if (response.statusCode == 422) {
        // Handle Pydantic validation errors
        final errorData = jsonDecode(response.body);
        String errorMessage = 'Invalid data provided';

        if (errorData['detail'] != null && errorData['detail'] is List) {
          final List<dynamic> errors = errorData['detail'];
          if (errors.isNotEmpty) {
            final firstError = errors[0];
            if (firstError['msg'] != null) {
              errorMessage = firstError['msg'];
            }
          }
        }

        print('❌ Registration validation error (422): $errorMessage');
        return {'success': false, 'error': errorMessage};
      } else {
        print('❌ Registration failed with status: ${response.statusCode}');
        return {
          'success': false,
          'error': 'Registration failed. Please try again.',
        };
      }
    } catch (e) {
      print('❌ Registration exception: $e');
      return {
        'success': false,
        'error': 'Network error. Please check your connection and try again.',
      };
    }
  }

  // =================== USER ENDPOINTS ===================

  static Future<Map<String, dynamic>> getUserProfile() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/users/me'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        return {'success': false, 'error': 'Failed to get profile'};
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> getPublicBranches() async {
    try {
      print('🔄 Getting public branches for registration...');

      // No authentication required for this endpoint
      final response = await http.get(
        Uri.parse('$baseUrl/branches/public'),
        headers: {'Content-Type': 'application/json'},
      );

      print('🔄 Public branches response status: ${response.statusCode}');
      print('🔄 Public branches response body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> branches = jsonDecode(response.body);
        print('✅ Retrieved ${branches.length} public branches');
        return {'success': true, 'data': branches};
      } else {
        print('❌ Failed to get public branches: ${response.statusCode}');
        return {'success': false, 'error': 'Failed to load branches'};
      }
    } catch (e) {
      print('❌ Exception getting public branches: $e');
      return {'success': false, 'error': 'Network error loading branches'};
    }
  }

  static Future<Map<String, dynamic>> updateProfile(
    Map<String, dynamic> userData,
  ) async {
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse('$baseUrl/users/me'),
        headers: headers,
        body: jsonEncode(userData),
      );

      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        return {'success': false, 'error': 'Failed to update profile'};
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // =================== REGISTRATION REQUESTS ENDPOINTS ===================

  static Future<Map<String, dynamic>> getRegistrationRequests() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/users/requests'),
        headers: headers,
      );

      print('🔄 Registration requests response: ${response.statusCode}');
      print('🔄 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> requests = jsonDecode(response.body);
        return {'success': true, 'data': requests};
      } else {
        return {
          'success': false,
          'error': 'HTTP ${response.statusCode}: ${response.body}',
        };
      }
    } catch (e) {
      print('❌ Error getting registration requests: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> approveRegistrationRequest(
    int requestId,
  ) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/users/approve/$requestId'),
        headers: headers,
      );

      print('🔄 Approve request response: ${response.statusCode}');
      print('🔄 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return {
          'success': true,
          'message':
              responseData['message'] ?? 'Registration approved successfully',
        };
      } else {
        return {
          'success': false,
          'error': 'HTTP ${response.statusCode}: ${response.body}',
        };
      }
    } catch (e) {
      print('❌ Error approving registration: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> rejectRegistrationRequest(
    int requestId,
  ) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/users/reject/$requestId'),
        headers: headers,
      );

      print('🔄 Reject request response: ${response.statusCode}');
      print('🔄 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return {
          'success': true,
          'message':
              responseData['message'] ??
              'Registration request rejected successfully',
        };
      } else {
        return {
          'success': false,
          'error': 'HTTP ${response.statusCode}: ${response.body}',
        };
      }
    } catch (e) {
      print('❌ Error rejecting registration: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  // =================== ATHLETE ENDPOINTS ===================

  static Future<Map<String, dynamic>> getAthleteHome() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/athlete/home'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        return {'success': false, 'error': 'Failed to get athlete home data'};
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> getAthleteGear() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/gear/athlete'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        return {'success': false, 'error': 'Failed to get gear data'};
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // =================== ATHLETE MANAGEMENT ENDPOINTS ===================

  static Future<Map<String, dynamic>> getAllAthletes() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/athletes/all'),
        headers: headers,
      );

      print('🔄 Get all athletes response: ${response.statusCode}');
      print('🔄 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> athletes = jsonDecode(response.body);
        return {'success': true, 'data': athletes};
      } else {
        return {
          'success': false,
          'error': 'HTTP ${response.statusCode}: ${response.body}',
        };
      }
    } catch (e) {
      print('❌ Error getting all athletes: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> deleteAthlete(int athleteId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/athletes/$athleteId'),
        headers: headers,
      );

      print('🔄 Delete athlete response: ${response.statusCode}');
      print('🔄 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return {
          'success': true,
          'message': responseData['message'] ?? 'Athlete deleted successfully',
        };
      } else {
        return {
          'success': false,
          'error': 'HTTP ${response.statusCode}: ${response.body}',
        };
      }
    } catch (e) {
      print('❌ Error deleting athlete: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  // =================== COACH ENDPOINTS ===================

  static Future<Map<String, dynamic>> getCoachHome() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/coach/home'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        return {'success': false, 'error': 'Failed to get coach home data'};
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> getBranches() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/branches/'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        return {'success': false, 'error': 'Failed to get branches'};
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // =================== ATTENDANCE ENDPOINTS ===================

  static Future<Map<String, dynamic>> getAttendance() async {
    try {
      final headers = await _getHeaders();
      final userId = await getUserId();

      final response = await http.get(
        Uri.parse('$baseUrl/attendance/athlete/$userId/week'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        return {'success': false, 'error': 'Failed to get attendance'};
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> markAttendance(
    int athleteId,
    bool present,
  ) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/attendance/mark'),
        headers: headers,
        body: jsonEncode({'athlete_id': athleteId, 'present': present}),
      );

      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        return {'success': false, 'error': 'Failed to mark attendance'};
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // =================== THREADS/CHAT ENDPOINTS ===================

  static Future<Map<String, dynamic>> getThreads() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/threads/'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        return {'success': false, 'error': 'Failed to get threads'};
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> getThreadsForBranch(
    String branchId,
  ) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/threads/branch/$branchId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        return {'success': false, 'error': 'Failed to get threads'};
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> getThreadPosts(int threadId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/threads/$threadId/posts'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        return {'success': false, 'error': 'Failed to get posts'};
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> createThread(
    String branchId,
    String title,
  ) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/threads/branch/$branchId/create'),
        headers: headers,
        body: jsonEncode({'title': title}),
      );

      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        return {'success': false, 'error': 'Failed to create thread'};
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> postToThread(
    int threadId,
    String message,
  ) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/threads/$threadId/post'),
        headers: headers,
        body: jsonEncode({'message': message}),
      );

      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        return {'success': false, 'error': 'Failed to send message'};
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> sendMessage(
    int threadId,
    String message,
  ) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/threads/$threadId/messages'),
        headers: headers,
        body: jsonEncode({'message': message}),
      );

      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        return {'success': false, 'error': 'Failed to send message'};
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // =================== NOTIFICATIONS ENDPOINTS ===================

  static Future<Map<String, dynamic>> getNotifications() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/notifications/'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        return {'success': false, 'error': 'Failed to get notifications'};
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // =================== PAYMENTS ENDPOINTS ===================

  // Replace the getPayments method in your ApiService with this enhanced version:

  static Future<Map<String, dynamic>> getPayments() async {
    try {
      print('🔄 Getting payments...');
      final headers = await _getHeaders();
      final userId = await getUserId();
      print('🔄 User ID: $userId');

      if (userId == null) {
        return {'success': false, 'error': 'User ID not found'};
      }

      // The backend expects user_id for the payments endpoint
      final response = await http.get(
        Uri.parse('$baseUrl/payments/$userId/status'),
        headers: headers,
      );

      print('🔄 Payment response status: ${response.statusCode}');
      print('🔄 Payment response body: ${response.body}');
      print('🔄 Payment response headers: ${response.headers}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        print('🔄 Parsed payment data: $responseData');
        return {'success': true, 'data': responseData};
      } else if (response.statusCode == 404) {
        print(
          'ℹ️ No payment records found (404) - this is normal for new users',
        );
        // Return empty payment data structure for current month
        final now = DateTime.now();
        final currentDueKey =
            '${now.year}-${now.month.toString().padLeft(2, '0')}-01';
        return {
          'success': true,
          'data': {currentDueKey: 'pending'},
        };
      } else {
        print('❌ Payment API error: ${response.statusCode}');
        return {
          'success': false,
          'error': 'HTTP ${response.statusCode}: ${response.body}',
        };
      }
    } catch (e) {
      print('❌ Exception in getPayments: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  // =================== PAYMENT MANAGEMENT ENDPOINTS ===================

  static Future<Map<String, dynamic>> getPaymentSummary(int branchId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/payments/summary/$branchId'),
        headers: headers,
      );

      print('🔄 Payment summary response: ${response.statusCode}');
      print('🔄 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return {'success': true, 'data': data};
      } else {
        return {
          'success': false,
          'error': 'HTTP ${response.statusCode}: ${response.body}',
        };
      }
    } catch (e) {
      print('❌ Error getting payment summary: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> markPayment({
    required int athleteId,
    required String sessionDate,
    required String status,
  }) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/payments/mark'),
        headers: headers,
        body: jsonEncode({
          'athlete_id': athleteId,
          'session_date': sessionDate,
          'status': status,
        }),
      );

      print('🔄 Mark payment response: ${response.statusCode}');
      print('🔄 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return {
          'success': true,
          'message':
              responseData['message'] ?? 'Payment status updated successfully',
          'debug': responseData['debug'],
        };
      } else {
        return {
          'success': false,
          'error': 'HTTP ${response.statusCode}: ${response.body}',
        };
      }
    } catch (e) {
      print('❌ Error marking payment: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  // Add this method to your ApiService class in the THREADS/CHAT ENDPOINTS section:

  // =================== THREADS/CHAT ENDPOINTS ===================

  static Future<Map<String, dynamic>> deleteAllHeadCoachMessages(
    String branchId,
  ) async {
    try {
      print('🔄 Deleting all head coach messages for branch: $branchId');
      final headers = await _getHeaders();

      final response = await http.delete(
        Uri.parse(
          '$baseUrl/threads/branch/$branchId/delete-head-coach-messages',
        ),
        headers: headers,
      );

      print('🔄 Delete messages response: ${response.statusCode}');
      print('🔄 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return {
          'success': true,
          'message': responseData['message'] ?? 'Messages deleted successfully',
          'deleted_count': responseData['deleted_count'] ?? 0,
        };
      } else {
        return {
          'success': false,
          'error': 'HTTP ${response.statusCode}: ${response.body}',
        };
      }
    } catch (e) {
      print('❌ Error deleting head coach messages: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> getAthletePaymentStatus(
    int athleteId,
  ) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/payments/$athleteId/status'),
        headers: headers,
      );

      print('🔄 Athlete payment status response: ${response.statusCode}');
      print('🔄 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> statusData = jsonDecode(response.body);
        return {'success': true, 'data': statusData};
      } else {
        return {
          'success': false,
          'error': 'HTTP ${response.statusCode}: ${response.body}',
        };
      }
    } catch (e) {
      print('❌ Error getting athlete payment status: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  // =================== MEASUREMENTS ENDPOINTS ===================

  // Replace the getMeasurements method in your ApiService with this enhanced version:

  static Future<Map<String, dynamic>> getMeasurements() async {
    try {
      print('🔄 Making request to get measurements...');
      final headers = await _getHeaders();
      print('🔄 Headers: $headers');

      final response = await http.get(
        Uri.parse('$baseUrl/athlete/measurements'),
        headers: headers,
      );

      print('🔄 Get measurements response: ${response.statusCode}');
      print('🔄 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        print('🔄 Parsed measurements data: $responseData');
        return {'success': true, 'data': responseData};
      } else if (response.statusCode == 404) {
        print('ℹ️ No measurements found (404)');
        return {
          'success': true,
          'data': null,
        }; // No measurements yet, but not an error
      } else {
        print('❌ Measurements API failed: ${response.statusCode}');
        return {
          'success': false,
          'error': 'HTTP ${response.statusCode}: ${response.body}',
        };
      }
    } catch (e) {
      print('❌ Exception in getMeasurements: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> saveMeasurements(
    Map<String, double> measurements,
  ) async {
    try {
      final headers = await _getHeaders();

      // ONLY send fields that have actual values (no nulls)
      final cleanMeasurements = <String, double>{};
      measurements.forEach((key, value) {
        if (value != null && value > 0) {
          cleanMeasurements[key] = value;
        }
      });

      if (cleanMeasurements.isEmpty) {
        return {'success': false, 'error': 'No valid measurements to save'};
      }

      print('🔄 Sending measurements: $cleanMeasurements');

      final response = await http.post(
        Uri.parse('$baseUrl/athlete/measurements'),
        headers: headers,
        body: jsonEncode(cleanMeasurements),
      );

      print('🔄 Measurements response: ${response.statusCode}');
      print('🔄 Response body: ${response.body}');

      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        return {
          'success': false,
          'error': 'HTTP ${response.statusCode}: ${response.body}',
        };
      }
    } catch (e) {
      print('❌ Error saving measurements: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  // =================== PERFORMANCE LOGS ENDPOINTS ===================

  static Future<Map<String, dynamic>> getPerformanceLogs() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/athlete/performance-logs'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        // Handle both direct array and wrapped response
        if (responseData is List) {
          return {'success': true, 'data': responseData};
        } else if (responseData is Map && responseData['data'] != null) {
          // Handle nested structure
          final data = responseData['data'];
          if (data is Map && data['data'] is List) {
            return {'success': true, 'data': data['data']};
          } else if (data is List) {
            return {'success': true, 'data': data};
          }
        }

        return {'success': true, 'data': responseData};
      } else {
        return {'success': false, 'error': 'Failed to get performance logs'};
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> getAthletePerformanceLogsById(
    int athleteId,
  ) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/athletes/$athleteId/performance-logs'),
        headers: headers,
      );

      print('🔄 Athlete performance logs response: ${response.statusCode}');
      print('🔄 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        // Handle both direct array and wrapped response
        if (responseData is List) {
          return {'success': true, 'data': responseData};
        } else if (responseData is Map && responseData['data'] != null) {
          // Handle nested structure
          final data = responseData['data'];
          if (data is Map && data['data'] is List) {
            return {'success': true, 'data': data['data']};
          } else if (data is List) {
            return {'success': true, 'data': data};
          }
        }

        return {'success': true, 'data': responseData};
      } else {
        return {
          'success': false,
          'error': 'HTTP ${response.statusCode}: ${response.body}',
        };
      }
    } catch (e) {
      print('❌ Error getting athlete performance logs: $e');
      return {'success': false, 'error': e.toString()};
    }
  }
  // Add these methods to your ApiService class

  static Future<Map<String, dynamic>> getAthleteMeasurementsById(
    int athleteId,
  ) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/athletes/$athleteId/measurements'),
        headers: headers,
      );

      print('🔄 Athlete measurements response: ${response.statusCode}');
      print('🔄 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return {'success': true, 'data': responseData};
      } else {
        return {
          'success': false,
          'error': 'HTTP ${response.statusCode}: ${response.body}',
        };
      }
    } catch (e) {
      print('❌ Error getting athlete measurements: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> savePerformanceLog(
    Map<String, dynamic> logData,
  ) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/athlete/performance-log'),
        headers: headers,
        body: jsonEncode(logData),
      );

      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        return {'success': false, 'error': 'Failed to save performance log'};
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> replaceAllPerformanceLogs(
    List<Map<String, String>> logs,
  ) async {
    try {
      final headers = await _getHeaders();
      final url = '$baseUrl/athlete/performance-logs/replace-all';
      final requestBody = jsonEncode({'logs': logs});

      print('🔄 API Call Details:');
      print('   URL: $url');
      print('   Headers: $headers');
      print('   Body: $requestBody');

      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: requestBody,
      );

      print('🔄 Response Details:');
      print('   Status Code: ${response.statusCode}');
      print('   Response Body: ${response.body}');
      print('   Response Headers: ${response.headers}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return {
          'success': responseData['success'] ?? true,
          'created_count': responseData['created_count'] ?? 0,
          'deleted_count': responseData['deleted_count'] ?? 0,
          'message': responseData['message'] ?? 'Success',
        };
      } else {
        return {
          'success': false,
          'error': 'HTTP ${response.statusCode}: ${response.body}',
        };
      }
    } catch (e) {
      print('❌ Exception in replaceAllPerformanceLogs: $e');
      return {'success': false, 'error': 'Exception: ${e.toString()}'};
    }
  }

  // =================== CHANGE PASSWORD ENDPOINT ===================

  static Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/auth/change-password'),
        headers: headers,
        body: jsonEncode({
          'current_password': currentPassword,
          'new_password': newPassword,
          'confirm_password': confirmPassword,
        }),
      );

      print('🔄 Change password response: ${response.statusCode}');
      print('🔄 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return {
          'success': responseData['success'] ?? true,
          'message': responseData['message'] ?? 'Password changed successfully',
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'error': errorData['detail'] ?? 'Failed to change password',
        };
      }
    } catch (e) {
      print('❌ Error changing password: $e');
      return {'success': false, 'error': 'Network error: ${e.toString()}'};
    }
  }

  // =================== MONTHLY ATTENDANCE ENDPOINTS ===================

  static Future<Map<String, dynamic>> getAthleteMonthlyAttendance(
    int athleteId,
    int year,
    int month,
  ) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse(
          '$baseUrl/attendance/athlete/$athleteId/monthly?year=$year&month=$month',
        ),
        headers: headers,
      );

      print('🔄 Monthly attendance response: ${response.statusCode}');
      print('🔄 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> attendanceData = jsonDecode(response.body);
        return {'success': true, 'data': attendanceData};
      } else {
        return {
          'success': false,
          'error': 'HTTP ${response.statusCode}: ${response.body}',
        };
      }
    } catch (e) {
      print('❌ Error getting monthly attendance: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> getAthleteAttendanceStats(
    int athleteId,
    int year,
  ) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/attendance/athlete/$athleteId/stats?year=$year'),
        headers: headers,
      );

      print('🔄 Attendance stats response: ${response.statusCode}');
      print('🔄 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> stats = jsonDecode(response.body);
        return {'success': true, 'data': stats};
      } else {
        return {
          'success': false,
          'error': 'HTTP ${response.statusCode}: ${response.body}',
        };
      }
    } catch (e) {
      print('❌ Error getting attendance stats: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  // =================== COACH ASSIGNMENT ENDPOINTS ===================

  static Future<Map<String, dynamic>> getAllCoaches() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/coaches/all'),
        headers: headers,
      );

      print('🔄 Get all coaches response: ${response.statusCode}');
      print('🔄 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> coaches = jsonDecode(response.body);
        return {'success': true, 'data': coaches};
      } else {
        return {
          'success': false,
          'error': 'HTTP ${response.statusCode}: ${response.body}',
        };
      }
    } catch (e) {
      print('❌ Error getting all coaches: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> getAllBranches() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/branches/all'),
        headers: headers,
      );

      print('🔄 Get all branches response: ${response.statusCode}');
      print('🔄 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> branches = jsonDecode(response.body);
        return {'success': true, 'data': branches};
      } else {
        return {
          'success': false,
          'error': 'HTTP ${response.statusCode}: ${response.body}',
        };
      }
    } catch (e) {
      print('❌ Error getting all branches: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> getCoachAssignments(int coachId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/coaches/$coachId/assignments'),
        headers: headers,
      );

      print('🔄 Get coach assignments response: ${response.statusCode}');
      print('🔄 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> assignments = jsonDecode(response.body);
        return {'success': true, 'data': assignments};
      } else {
        return {
          'success': false,
          'error': 'HTTP ${response.statusCode}: ${response.body}',
        };
      }
    } catch (e) {
      print('❌ Error getting coach assignments: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> assignCoachToBranch(
    int coachId,
    int branchId,
  ) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/coaches/$coachId/assign'),
        headers: headers,
        body: jsonEncode({'branch_id': branchId}),
      );

      print('🔄 Assign coach response: ${response.statusCode}');
      print('🔄 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return {
          'success': true,
          'message': responseData['message'] ?? 'Coach assigned successfully',
        };
      } else {
        return {
          'success': false,
          'error': 'HTTP ${response.statusCode}: ${response.body}',
        };
      }
    } catch (e) {
      print('❌ Error assigning coach: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> unassignCoachFromBranch(
    int coachId,
    int branchId,
  ) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/coaches/$coachId/unassign'),
        headers: headers,
        body: jsonEncode({'branch_id': branchId}),
      );

      print('🔄 Unassign coach response: ${response.statusCode}');
      print('🔄 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return {
          'success': true,
          'message': responseData['message'] ?? 'Coach unassigned successfully',
        };
      } else {
        return {
          'success': false,
          'error': 'HTTP ${response.statusCode}: ${response.body}',
        };
      }
    } catch (e) {
      print('❌ Error unassigning coach: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> getCoachAssignmentStats() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/coaches/assignment-stats'),
        headers: headers,
      );

      print('🔄 Get assignment stats response: ${response.statusCode}');
      print('🔄 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> stats = jsonDecode(response.body);
        return {'success': true, 'data': stats};
      } else {
        return {
          'success': false,
          'error': 'HTTP ${response.statusCode}: ${response.body}',
        };
      }
    } catch (e) {
      print('❌ Error getting assignment stats: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  // =================== SWITCH BRANCH ENDPOINT ===================

  static Future<Map<String, dynamic>> switchBranch(int branchId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/branches/select-branch/$branchId'),
        headers: headers,
      );

      print('🔄 Switch branch response: ${response.statusCode}');
      print('🔄 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return {
          'success': true,
          'message': responseData['message'] ?? 'Branch switched successfully',
        };
      } else {
        return {
          'success': false,
          'error': 'HTTP ${response.statusCode}: ${response.body}',
        };
      }
    } catch (e) {
      print('❌ Error switching branch: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> getBranchDetails(int branchId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/branches/$branchId'),
        headers: headers,
      );

      print('🔄 Get branch details response: ${response.statusCode}');
      print('🔄 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> branchData = jsonDecode(response.body);
        return {'success': true, 'data': branchData};
      } else {
        return {
          'success': false,
          'error': 'HTTP ${response.statusCode}: ${response.body}',
        };
      }
    } catch (e) {
      print('❌ Error getting branch details: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  // =================== WEEKLY ATTENDANCE ENDPOINTS ===================

  static Future<Map<String, dynamic>> getBranchSessionDates(
    int branchId,
  ) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/attendance/branch/$branchId/session-dates'),
        headers: headers,
      );

      print('🔄 Branch session dates response: ${response.statusCode}');
      print('🔄 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> dates = jsonDecode(response.body);
        return {'success': true, 'data': dates};
      } else {
        return {
          'success': false,
          'error': 'HTTP ${response.statusCode}: ${response.body}',
        };
      }
    } catch (e) {
      print('❌ Error getting branch session dates: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> getBranchDayAttendance(
    int branchId,
    String sessionDate,
  ) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/attendance/branch/$branchId/day/$sessionDate'),
        headers: headers,
      );

      print('🔄 Branch day attendance response: ${response.statusCode}');
      print('🔄 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> attendance = jsonDecode(response.body);
        return {'success': true, 'data': attendance};
      } else {
        return {
          'success': false,
          'error': 'HTTP ${response.statusCode}: ${response.body}',
        };
      }
    } catch (e) {
      print('❌ Error getting branch day attendance: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  // Replace the markWeeklyAttendance method in your ApiService with this fixed version:

  static Future<Map<String, dynamic>> markWeeklyAttendance({
    required int athleteId,
    required String sessionDate,
    required String status,
    String? notes, // ✅ ADD: Optional notes parameter
  }) async {
    try {
      final headers = await _getHeaders();

      // ✅ FIXED: Include notes in the request body
      final requestBody = {
        'athlete_id': athleteId,
        'session_date': sessionDate,
        'status': status,
      };

      // Add notes only if they exist and are not empty
      if (notes != null && notes.trim().isNotEmpty) {
        requestBody['notes'] = notes.trim();
      }

      print(
        '🔄 Mark weekly attendance request body: $requestBody',
      ); // Debug log

      final response = await http.post(
        Uri.parse('$baseUrl/attendance/mark'),
        headers: headers,
        body: jsonEncode(requestBody),
      );

      print('🔄 Mark weekly attendance response: ${response.statusCode}');
      print('🔄 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return {
          'success': true,
          'message':
              responseData['message'] ?? 'Attendance marked successfully',
        };
      } else {
        return {
          'success': false,
          'error': 'HTTP ${response.statusCode}: ${response.body}',
        };
      }
    } catch (e) {
      print('❌ Error marking weekly attendance: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> getDayAttendance(String date) async {
    try {
      final headers = await _getHeaders();

      // Get user profile to get branch_id first
      final profileResponse = await getUserProfile();
      if (!profileResponse['success'] || profileResponse['data'] == null) {
        return {'success': false, 'error': 'Failed to get user profile'};
      }

      final branchId = profileResponse['data']['branch_id'];
      if (branchId == null) {
        return {
          'success': false,
          'error': 'Branch ID not found in user profile',
        };
      }

      final response = await http.get(
        Uri.parse('$baseUrl/attendance/branch/$branchId/day/$date'),
        headers: headers,
      );

      print('🔄 Day attendance response: ${response.statusCode}');
      print('🔄 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> attendance = jsonDecode(response.body);
        return {'success': true, 'data': attendance};
      } else {
        return {
          'success': false,
          'error': 'HTTP ${response.statusCode}: ${response.body}',
        };
      }
    } catch (e) {
      print('❌ Error getting day attendance: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  // =================== GEAR MANAGEMENT ENDPOINTS ===================

  // =================== UTILITY METHODS ===================

  static Future<void> logout() async {
    await _storage.deleteAll();
  }

  static Future<bool> isLoggedIn() async {
    final token = await _storage.read(key: 'auth_token');
    return token != null;
  }

  static Future<String?> getUserType() async {
    return await _storage.read(key: 'user_type');
  }

  static Future<String?> getUserId() async {
    return await _storage.read(key: 'user_id');
  }

  static Future<Map<String, dynamic>> setCoachActiveBranch(int branchId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/coach/set-active-branch/$branchId'),
        headers: headers,
      );

      print('🔄 Set active branch response: ${response.statusCode}');
      print('🔄 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return {
          'success': true,
          'message': responseData['message'] ?? 'Branch set successfully',
          'new_active_branch_id': responseData['new_active_branch_id'],
          'new_active_branch_name': responseData['new_active_branch_name'],
        };
      } else {
        return {
          'success': false,
          'error': 'HTTP ${response.statusCode}: ${response.body}',
        };
      }
    } catch (e) {
      print('❌ Error setting active branch: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> getCoachAssignedBranches() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/coach/assigned-branches'),
        headers: headers,
      );

      print('🔄 Get assigned branches response: ${response.statusCode}');
      print('🔄 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return {'success': true, 'data': responseData};
      } else {
        return {
          'success': false,
          'error': 'HTTP ${response.statusCode}: ${response.body}',
        };
      }
    } catch (e) {
      print('❌ Error getting assigned branches: $e');
      return {'success': false, 'error': e.toString()};
    }
  }
  // Add this method to your ApiService class in the GEAR MANAGEMENT ENDPOINTS section

  // =================== GEAR MANAGEMENT ENDPOINTS ===================
  // =================== GEAR MANAGEMENT ENDPOINTS ===================

  // Add these methods to your GEAR MANAGEMENT ENDPOINTS section in api_service.dart

  // =================== GEAR MANAGEMENT ENDPOINTS ===================

  static Future<Map<String, dynamic>> getAllBranchesForGear() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/gear/branches/all'),
        headers: headers,
      );

      print('🔄 Get all branches for gear response: ${response.statusCode}');
      print('🔄 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return {
          'success': responseData['success'] ?? true,
          'branches': responseData['branches'] ?? [],
        };
      } else {
        return {
          'success': false,
          'error': 'HTTP ${response.statusCode}: ${response.body}',
        };
      }
    } catch (e) {
      print('❌ Error getting all branches for gear: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> postGear(
    String branchId,
    String content,
  ) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/gear/$branchId'),
        headers: headers,
        body: jsonEncode({'content': content}),
      );

      print('🔄 Post gear response: ${response.statusCode}');
      print('🔄 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return {
          'success': true,
          'message': responseData['message'] ?? 'Gear updated successfully',
        };
      } else {
        return {
          'success': false,
          'error': 'HTTP ${response.statusCode}: ${response.body}',
        };
      }
    } catch (e) {
      print('❌ Error posting gear: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> getGearForBranch(String branchId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/gear/$branchId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        return {'success': false, 'error': 'Failed to get gear data'};
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
  // Add this method to your ApiService class in the ATHLETE ENDPOINTS section

  // =================== ATHLETE ENDPOINTS ===================

  // Replace the getAthleteIdFromUserId method in your ApiService with this enhanced version:

  static Future<Map<String, dynamic>> getAthleteIdFromUserId() async {
    try {
      print('🔄 Making request to /athlete/me...');
      final headers = await _getHeaders();
      print('🔄 Headers: $headers');

      final response = await http.get(
        Uri.parse('$baseUrl/athlete/me'),
        headers: headers,
      );

      print('🔄 Get athlete ID response: ${response.statusCode}');
      print('🔄 Response body: ${response.body}');
      print('🔄 Response headers: ${response.headers}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('🔄 Parsed JSON data: $data');
        return {'success': true, 'data': data};
      } else if (response.statusCode == 404) {
        return {
          'success': false,
          'error': 'Athlete record not found - HTTP 404: ${response.body}',
        };
      } else if (response.statusCode == 403) {
        return {
          'success': false,
          'error': 'Access denied - HTTP 403: ${response.body}',
        };
      } else {
        return {
          'success': false,
          'error': 'HTTP ${response.statusCode}: ${response.body}',
        };
      }
    } catch (e) {
      print('❌ Exception in getAthleteIdFromUserId: $e');
      return {'success': false, 'error': 'Network error: ${e.toString()}'};
    }
  }

  static Future<Map<String, dynamic>> forgotPassword(String email) async {
    try {
      print('🔄 Sending forgot password request for: $email');

      final response = await http.post(
        Uri.parse('$baseUrl/auth/forgot-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      print('🔄 Forgot password response: ${response.statusCode}');
      print('🔄 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return {
          'success': responseData['success'] ?? true,
          'message': responseData['detail'] ?? 'Reset code sent successfully',
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'error': errorData['detail'] ?? 'Failed to send reset code',
        };
      }
    } catch (e) {
      print('❌ Exception in forgot password: $e');
      return {
        'success': false,
        'error': 'Network error. Please check your connection.',
      };
    }
  }

  static Future<Map<String, dynamic>> verifyResetCode({
    required String email,
    required String code,
  }) async {
    try {
      print('🔄 Verifying reset code for: $email');

      final response = await http.post(
        Uri.parse('$baseUrl/auth/verify-reset-code'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'code': code}),
      );

      print('🔄 Verify code response: ${response.statusCode}');
      print('🔄 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return {
          'success': responseData['success'] ?? true,
          'message': responseData['detail'] ?? 'Code verified successfully',
          'user_name': responseData['user_name'],
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'error': errorData['detail'] ?? 'Invalid or expired code',
        };
      }
    } catch (e) {
      print('❌ Exception in verify reset code: $e');
      return {
        'success': false,
        'error': 'Network error. Please check your connection.',
      };
    }
  }

  static Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String code,
    required String newPassword,
    required String confirmPassword,
  }) async {
    try {
      print('🔄 Resetting password for: $email');

      final response = await http.post(
        Uri.parse('$baseUrl/auth/reset-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'code': code,
          'new_password': newPassword,
          'confirm_password': confirmPassword,
        }),
      );

      print('🔄 Reset password response: ${response.statusCode}');
      print('🔄 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return {
          'success': responseData['success'] ?? true,
          'message': responseData['detail'] ?? 'Password reset successfully',
          'user_name': responseData['user_name'],
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'error': errorData['detail'] ?? 'Failed to reset password',
        };
      }
    } catch (e) {
      print('❌ Exception in reset password: $e');
      return {
        'success': false,
        'error': 'Network error. Please check your connection.',
      };
    }
  }
}
