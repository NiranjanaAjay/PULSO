import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Sign up a new user
  Future<AuthResponse> signUp(String email, String password, String name) async {
    final response = await _supabase.auth.signUp(
      email: email,
      password: password,
    );

    // If sign up is successful, create the profile in our 'users' table
    if (response.user != null) {
      await _supabase.from('users').insert({
        'user_id': response.user!.id,
        'name': name,
      });
    }
    return response;
  }

  // Sign in existing user
  Future<AuthResponse> signIn(String email, String password) async {
    return await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  // Get current user profile with secure ID check
  Future<Map<String, dynamic>?> fetchCurrentUserProfile() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;

    try {
      // Fetch basic user info
      final userData = await _supabase
          .from('users')
          .select()
          .eq('user_id', user.id)
          .maybeSingle();

      // Fetch medical history
      final medicalData = await _supabase
          .from('medical_history')
          .select()
          .eq('user_id', user.id)
          .maybeSingle();
      
      return {
        'user': userData,
        'medical': medicalData,
      };
    } catch (e) {
      print('Error fetching profile: $e');
      return null;
    }
  }

  // Check if user has medical history
  Future<bool> hasMedicalHistory() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return false;

    try {
      final data = await _supabase
          .from('medical_history')
          .select()
          .eq('user_id', user.id)
          .maybeSingle();
      return data != null;
    } catch (e) {
      return false;
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }
}

Future<void> saveMedicalHistory({
  required int age,
  required String gender,
  required String conditions,
}) async {
  final user = Supabase.instance.client.auth.currentUser;
  
  if (user != null) {
    await Supabase.instance.client.from('medical_history').insert({
      'user_id': user.id,
      'age_at_record': age,
      'gender': gender,
      'existing_conditions': conditions,
    });
  }
}