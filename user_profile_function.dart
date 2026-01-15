import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:dreamguard/src/authentication/authentication_function.dart';
import 'package:dreamguard/src/app.dart'; // Add this import to access navigatorKey
import 'package:http_parser/http_parser.dart'; // Add this import for MediaType

const String baseUrl = 'https://dream-mend-dev.cogsci.uni-osnabrueck.de/api';

class UserData {
  String? name;
  String email;
  String? profileImageUrl;
  String? phoneNumber;
  String? username;
  String? surname;
  String? dateOfBirth;
  String? gender;
  String? region;
  String? education;
  String? headerImageUrl;
  int? id;

  UserData({
    this.name,
    required this.email,
    this.profileImageUrl,
    this.phoneNumber,
    this.username,
    this.surname,
    this.dateOfBirth,
    this.gender,
    this.region,
    this.education,
    this.headerImageUrl,
    this.id,
  });

  factory UserData.fromJson(Map<String, dynamic> json) {
    String? profileImageUrl = json['profile_image_url'] as String?;
    if (profileImageUrl != null && !profileImageUrl.startsWith('http')) {
      profileImageUrl =
          'https://dream-mend-dev.cogsci.uni-osnabrueck.de/api$profileImageUrl';
    }

    return UserData(
      id: json['id'] as int?,
      name: json['name'] as String?,
      email: json['email'] as String,
      profileImageUrl: profileImageUrl,
      phoneNumber: json['phone_number'] as String?,
      username: json['username'] as String?,
      surname: json['surname'] as String?,
      dateOfBirth: json['date_of_birth'] as String?,
      gender: json['gender'] as String?,
      region: json['region'] as String?,
      education: json['education'] as String?,
      headerImageUrl: json['header_image_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'profile_image_url': profileImageUrl,
      'phone_number': phoneNumber,
      'username': username,
      'surname': surname,
      'date_of_birth': dateOfBirth,
      'gender': gender,
      'region': region,
      'education': education,
      'header_image_url': headerImageUrl,
    };
  }
}

class ProfileFunction {
  Future<UserData> fetchProfile(BuildContext context) async {
    final jwtToken =
        await Provider.of<AuthModel>(context, listen: false).getJwtToken();

    final response = await http.get(
      Uri.parse('$baseUrl/profile'),
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $jwtToken',
      },
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = jsonDecode(response.body);
      return UserData.fromJson(responseData);
    } else {
      throw Exception('Failed to load user data');
    }
  }

  Future<void> updateProfile(BuildContext context, UserData userData) async {
    final jwtToken =
        await Provider.of<AuthModel>(context, listen: false).getJwtToken();

    final url = Uri.parse('$baseUrl/profile');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $jwtToken',
    };

    // Prepare the request body with only non-null fields
    final Map<String, dynamic> profileUpdates = {
      if (userData.username != null) 'username': userData.username,
      if (userData.name != null) 'name': userData.name,
      if (userData.surname != null) 'surname': userData.surname,
      if (userData.dateOfBirth != null) 'date_of_birth': userData.dateOfBirth,
      if (userData.phoneNumber != null) 'phone_number': userData.phoneNumber,
      if (userData.email.isNotEmpty) 'email': userData.email,
      if (userData.gender != null) 'gender': userData.gender,
      if (userData.region != null) 'region': userData.region,
      if (userData.education != null) 'education': userData.education,
    };

    try {
      print('Sending profile update: $profileUpdates');

      final response = await http.patch(url,
          headers: headers, body: jsonEncode(profileUpdates));

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        // Successfully updated profile fields
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        // Update local userData with response data
        userData = UserData.fromJson(responseData);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!')),
        );
      } else {
        throw Exception(
            'Failed to update profile: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error updating profile: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating profile: $e')),
      );
      rethrow;
    }
  }

  Future<XFile?> pickImage() async {
    print('pickImage function called');
    try {
      final ImagePicker picker = ImagePicker();
      print('ImagePicker initialized');

      // For Web platform specifically
      XFile? pickedFile;
      try {
        print('Attempting to pick image...');
        pickedFile = await picker.pickImage(
          source: ImageSource.gallery,
          maxWidth: 1024,
          maxHeight: 1024,
          imageQuality: 85,
        );
        print('Image picker completed. Result: ${pickedFile?.path}');
      } catch (e) {
        print('First attempt failed: $e');
        print('Trying with different parameters...');
        pickedFile = await picker.pickImage(
          source: ImageSource.gallery,
          maxWidth: 800,
          maxHeight: 800,
        );
        print('Second attempt completed. Result: ${pickedFile?.path}');
      }

      return pickedFile;
    } catch (e) {
      print('Fatal error in pickImage: $e');
      return null;
    }
  }

  Future<String?> uploadProfileImage(
      BuildContext context, XFile imageFile) async {
    try {
      final jwtToken =
          await Provider.of<AuthModel>(context, listen: false).getJwtToken();
      if (jwtToken == null) {
        throw Exception('Not authenticated');
      }

      print('Uploading image from path: ${imageFile.path}');

      // Read file as bytes
      final bytes = await imageFile.readAsBytes();
      print('Image size: ${bytes.length} bytes');

      // Create multipart request
      var request =
          http.MultipartRequest('PATCH', Uri.parse('$baseUrl/profile/image'));

      // Add authorization header
      request.headers['Authorization'] = 'Bearer $jwtToken';

      // Add the file
      request.files.add(http.MultipartFile.fromBytes(
        'profile_image',
        bytes,
        filename: 'profile_image.jpg',
      ));

      print('Sending request to: ${request.url}');

      // Send the request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('Image upload response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        try {
          final responseData = jsonDecode(response.body);
          final relativeImageUrl = responseData['profile_image_url'];
          if (relativeImageUrl != null) {
            final absoluteImageUrl =
                'https://dream-mend-dev.cogsci.uni-osnabrueck.de/api$relativeImageUrl';
            print('New absolute image URL: $absoluteImageUrl');
            return absoluteImageUrl;
          }
          return null;
        } catch (e) {
          print('Error parsing response: $e');
          throw Exception('Error parsing server response');
        }
      } else {
        throw Exception(
            'Failed to upload image: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error uploading profile image: $e');
      throw Exception('Error uploading image: $e');
    }
  }

  Future<void> updateEmail(BuildContext context, String newEmail) async {
    final jwtToken =
        await Provider.of<AuthModel>(context, listen: false).getJwtToken();

    final response = await http.patch(
      Uri.parse('$baseUrl/profile'),
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $jwtToken',
      },
      body: jsonEncode({'email': newEmail}),
    );

    if (response.statusCode == 200) {
      // Here, backend sends a verification code to the new email
      // The navigation to CheckMail page is handled in the UI
    } else {
      throw Exception(
          'Failed to initiate email change: ${response.statusCode}');
    }
  }

  Future<bool> verifyEmailChange(
      BuildContext context, String verificationCode) async {
    final jwtToken =
        await Provider.of<AuthModel>(context, listen: false).getJwtToken();

    final response = await http.post(
      Uri.parse('$baseUrl/verify-email'),
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $jwtToken',
      },
      body: jsonEncode({'token': verificationCode}),
    );

    if (response.statusCode == 200) {
      return true;
    } else {
      return false;
    }
  }

  Future<UserData> getUserData(BuildContext context) async {
    try {
      final String? jwtToken =
          await Provider.of<AuthModel>(context, listen: false).getJwtToken();

      if (jwtToken == null) {
        throw Exception('Not authenticated');
      }

      print('Fetching profile from: $baseUrl/profile');

      final response = await http.get(
        Uri.parse('$baseUrl/profile'),
        headers: {
          'Authorization': 'Bearer $jwtToken',
          'Content-Type': 'application/json',
        },
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Request timed out');
        },
      );

      print('Response status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return UserData.fromJson(data);
      } else {
        throw Exception('Failed to load user data: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching user data: $e');
      rethrow;
    }
  }
}
