import 'dart:collection';

import 'package:dreamguard/src/authentication/authentication_function.dart';
import 'package:flutter/material.dart';
import 'package:dreamguard/src/user_profile/user_profile_function.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

final _formKeyUserData = GlobalKey<FormState>();
bool _autoValidateUserData = false;
bool _isValidatedUserData = false;

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool isEditing = false;
  final ProfileFunction profileFunction = ProfileFunction();
  UserData? userData;
  bool isLoading = true;
  String? error;
  
  // Controllers for form fields
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController surnameController = TextEditingController();
  final TextEditingController dobController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }
  
  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    surnameController.dispose();
    dobController.dispose();
    usernameController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      final data = await profileFunction.getUserData(context);
      setState(() {
        userData = data;
        isLoading = false;
        
        // Set controller values
        nameController.text = data.name ?? '';
        emailController.text = data.email;
        surnameController.text = data.surname ?? '';
        dobController.text = data.dateOfBirth ?? '';
        usernameController.text = data.username ?? '';
        phoneController.text = data.phoneNumber ?? '';
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        error = e.toString();
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.failedToLoad)),
        );
      }
    }
  }
  
  Future<void> _saveChanges() async {
    if (userData == null) return;
    
    setState(() {
      isLoading = true;
    });
    
    try {
      // Update userData with form values
      userData!.name = nameController.text;
      userData!.email = emailController.text;
      userData!.surname = surnameController.text;
      userData!.dateOfBirth = dobController.text;
      userData!.username = usernameController.text;
      userData!.phoneNumber = phoneController.text;
      
      await profileFunction.updateProfile(context, userData!);
      
      setState(() {
        isEditing = false;
        isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.profileUpdated)),
        );
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.failedToUpdate)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isLoading 
        ? const Center(child: CircularProgressIndicator())
        : error != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error: $error'),
                  ElevatedButton(
                    onPressed: _refreshProfile,
                    child: Text(AppLocalizations.of(context)!.tryAgain),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Section: Title
              Text(
                AppLocalizations.of(context)!.profileTitle,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),

            // Profile Background and Avatar
            Stack(
              clipBehavior: Clip.none,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16.0),
                  child: Image.asset(
                    'assets/images/profile_background.png',
                    width: double.infinity,
                    height: 200,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  bottom: -50,
                  left: 20,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Display current user profile image
                      CircleAvatar(
                        radius: 66,
                        backgroundColor: Colors.grey[300],
                        backgroundImage: userData?.profileImageUrl != null && userData!.profileImageUrl!.isNotEmpty
                          ? NetworkImage(userData!.profileImageUrl!)
                          : null,
                        
                        child: userData?.profileImageUrl != null && userData!.profileImageUrl!.isNotEmpty
                          ? null
                          : const Icon(
                              Icons.person,
                              size: 50,
                              color: Colors.white,
                            ),
                      )
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20), // space for avatar overlap

            // Add upload button with camera icon
            Center(
              child: 
                Padding(
                padding: const EdgeInsets.only(bottom: 20.0),
                child: ElevatedButton.icon(
                  onPressed: () async {
                    print('Camera icon tapped');
                    try {
                      final pickedFile = await ProfileFunction().pickImage();
                      if (pickedFile != null) {
                        setState(() {
                          isLoading = true;
                        });
                        
                        final newImageUrl = await ProfileFunction().uploadProfileImage(context, pickedFile);
                        if (newImageUrl != null) {
                          setState(() {
                            userData?.profileImageUrl = newImageUrl;
                            isLoading = false;
                          });
                          
                          // Force refresh the image
                          imageCache.clear();
                          imageCache.clearLiveImages();
                          
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(AppLocalizations.of(context)!.profilePictureUpdated)),
                          );
                        }
                      }
                    } catch (e) {
                      print('Error updating profile picture: $e');
                      setState(() {
                        isLoading = false;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(AppLocalizations.of(context)!.errorUpdatingImage)),
                      );
                    }
                  },
                  icon: const Icon(Icons.photo_camera),
                  label: Text(AppLocalizations.of(context)!.uploadProfilePhoto),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                ),
              ),
            ),

            // Tabs for "My Details", "Password", "Dream History", "Dream Statistics"
            DefaultTabController(
              length: 4,
              child: Column(
                children: [
                  TabBar(
                    labelColor: Theme.of(context).brightness == Brightness.dark 
                      ? Colors.white 
                      : Colors.black,
                    unselectedLabelColor: Theme.of(context).brightness == Brightness.dark 
                      ? Colors.grey[400] 
                      : Colors.grey,
                    indicatorColor: Theme.of(context).brightness == Brightness.dark 
                      ? Colors.white 
                      : Colors.black,
                    tabs: [
                      Tab(text: AppLocalizations.of(context)!.myDetails),
                      Tab(text: AppLocalizations.of(context)!.passwordTab),
                      Tab(text: AppLocalizations.of(context)!.dreamHistoryTab),
                      Tab(text: AppLocalizations.of(context)!.dreamStatisticsTab),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Edit / Save button
                  Align(
                    alignment: Alignment.centerRight,
                    child: OutlinedButton(
                      onPressed: () {
                        if (isEditing) {
                          _saveChanges();
                        } else {
                          setState(() {
                            isEditing = true;
                          });
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF3495C2)),
                      ),
                      child: Text(
                        isEditing ? AppLocalizations.of(context)!.saveChanges : AppLocalizations.of(context)!.editProfile,
                        style: const TextStyle(color: Color(0xFF3495C2)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Tab Content
                  SizedBox(
                    height: 400,
                    child: TabBarView(
                      children: [
                        // 1) My Details
                        _buildDetailsTab(),

                        // 2) Password
                        PasswordTab(),

                        // 3) Dream History
                        DreamHistoryTab(),

                        // 4) Dream Statistics
                        DreamStatisticsTab(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ------------------ My Details Tab ------------------
  Widget _buildDetailsTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKeyUserData,
        child: Column(
          children: [
            // Row 1: Name + Email
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: nameController,
                    enabled: isEditing,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.firstName,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: emailController,
                    enabled: isEditing,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.email,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Row 2: Surname + DOB
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: surnameController,
                    enabled: isEditing,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.lastName,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: dobController,
                    enabled: isEditing,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.dateOfBirth,
                      hintText: 'YYYY-MM-DD',
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      if (userData != null) {
                        userData!.dateOfBirth = value;
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Row 3: Username + Phone (moved up)
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: usernameController,
                    enabled: isEditing,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.username,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: phoneController,
                    enabled: isEditing,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.phoneNumber,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Gender field
            TextFormField(
              enabled: isEditing,
              initialValue: userData?.gender,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.gender,
                border: const OutlineInputBorder(),
              ),
              onChanged: (value) {
                if (userData != null) {
                  userData!.gender = value;
                }
              },
            ),
            const SizedBox(height: 16),

            // Region field
            TextFormField(
              enabled: isEditing,
              initialValue: userData?.region,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.region,
                border: const OutlineInputBorder(),
              ),
              onChanged: (value) {
                if (userData != null) {
                  userData!.region = value;
                }
              },
            ),
            const SizedBox(height: 16),

            // Education field
            TextFormField(
              enabled: isEditing,
              initialValue: userData?.education,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.education,
                border: const OutlineInputBorder(),
              ),
              onChanged: (value) {
                if (userData != null) {
                  userData!.education = value;
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _refreshProfile() async {
    setState(() {
      isLoading = true;
      error = null;
    });
    
    try {
      final newUserData = await profileFunction.getUserData(context);
      setState(() {
        userData = newUserData;
        
        // Update controllers
        nameController.text = newUserData.name ?? '';
        emailController.text = newUserData.email;
        surnameController.text = newUserData.surname ?? '';
        dobController.text = newUserData.dateOfBirth ?? '';
        usernameController.text = newUserData.username ?? '';
        phoneController.text = newUserData.phoneNumber ?? '';
        
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        error = AppLocalizations.of(context)!.errorLoadingData;
      });
    }
  }

  Future<void> _refreshProfileImage(String newImageUrl) async {
    if (userData != null) {
      setState(() {
        userData!.profileImageUrl = newImageUrl;
      });
      
      // Clear the image cache to force reload
      imageCache.clear();
      imageCache.clearLiveImages();
      
      // Pre-cache the new image
      final NetworkImage image = NetworkImage(newImageUrl);
      await precacheImage(image, context);
    }
  }

  Future<void> _pickAndUploadImage(BuildContext context) async {
    try {
      // Show a feedback message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.openingImagePicker)),
      );
      
      // Let user pick an image
      final pickedFile = await ProfileFunction().pickImage();
      print('Picked file: ${pickedFile?.path}');
      
      if (pickedFile != null) {
        setState(() {
          isLoading = true;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.uploadingImage)),
        );
        
        // Upload to backend
        final newImageUrl = await ProfileFunction().uploadProfileImage(context, pickedFile);
        print('Received new image URL: $newImageUrl');
        
        if (newImageUrl != null) {
          // Refresh the entire profile to ensure we have the latest data
          await _refreshProfile();
          
          // Also explicitly update the image and clear cache
          await _refreshProfileImage(newImageUrl);
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(AppLocalizations.of(context)!.profilePictureUpdated)),
            );
          }
        } else {
          setState(() {
            isLoading = false;
          });
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(AppLocalizations.of(context)!.failedToUpdateProfilePicture)),
            );
          }
        }
      }
    } catch (e) {
      print('Error in profile picture update: $e');
      setState(() {
        isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.errorUpdatingImage)),
        );
      }
    }
  }
}

class ProfileHeader extends StatelessWidget {
  const ProfileHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          height: 200,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: const AssetImage('assets/images/profile_background.png'),
              fit: BoxFit.cover,
              colorFilter: ColorFilter.mode(
                Colors.black.withOpacity(0.3),
                BlendMode.darken,
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 20,
          left: 20,
          child: Stack(
            children: [
              CircleAvatar(
                radius: 50,
                backgroundColor: Colors.grey[300],
                child: const Icon(
                  Icons.person,
                  size: 50,
                  color: Colors.white,
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.camera_alt),
                    onPressed: () {
                      // Implement image picker
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class MyDetailsTab extends StatefulWidget {
  const MyDetailsTab({super.key});

  @override
  _MyDetailsTabState createState() => _MyDetailsTabState();
}

class _MyDetailsTabState extends State<MyDetailsTab> {
  late Future<UserData> userDataFuture;
  final _formKey = GlobalKey<FormState>();
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    userDataFuture = ProfileFunction().fetchProfile(context);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserData>(
      future: userDataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final userData = snapshot.data!;
        
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.personalInfo,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          if (_isEditing) {
                            if (_formKey.currentState!.validate()) {
                              // Save changes
                              ProfileFunction().updateProfile(context, userData);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(AppLocalizations.of(context)!.profileUpdated)),
                              );
                            }
                          }
                          _isEditing = !_isEditing;
                        });
                      },
                      child: Text(_isEditing ? AppLocalizations.of(context)!.save : AppLocalizations.of(context)!.editProfile),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                ProfileField(
                  label: AppLocalizations.of(context)!.firstName,
                  initialValue: userData.name ?? '',
                  enabled: _isEditing,
                  onChanged: (value) => userData.name = value,
                ),
                ProfileField(
                  label: AppLocalizations.of(context)!.lastName,
                  initialValue: userData.surname ?? '',
                  enabled: _isEditing,
                  onChanged: (value) => userData.surname = value,
                ),
                ProfileField(
                  label: AppLocalizations.of(context)!.username,
                  initialValue: userData.username ?? '',
                  enabled: _isEditing,
                  onChanged: (value) => userData.username = value,
                  validator: (value) {
                    if (value?.isEmpty ?? true) return AppLocalizations.of(context)!.usernameRequired;
                    if ((value?.length ?? 0) < 3) return AppLocalizations.of(context)!.usernameMustBeAtLeast3Characters;
                    return null;
                  },
                ),
                ProfileField(
                  label: AppLocalizations.of(context)!.email,
                  initialValue: userData.email,
                  enabled: _isEditing,
                  onChanged: (value) => userData.email = value,
                  validator: (value) {
                    if (value?.isEmpty ?? true) return AppLocalizations.of(context)!.emailRequired;
                    if (!value!.contains('@')) return AppLocalizations.of(context)!.invalidEmail;
                    return null;
                  },
                ),
                ProfileField(
                  label: AppLocalizations.of(context)!.dateOfBirth,
                  initialValue: userData.dateOfBirth ?? '',
                  enabled: _isEditing,
                  onChanged: (value) => userData.dateOfBirth = value,
                ),
                ProfileField(
                  label: AppLocalizations.of(context)!.phoneNumber,
                  initialValue: userData.phoneNumber ?? '',
                  enabled: _isEditing,
                  onChanged: (value) => userData.phoneNumber = value,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class ProfileField extends StatelessWidget {
  final String label;
  final String initialValue;
  final bool enabled;
  final Function(String) onChanged;
  final String? Function(String?)? validator;

  const ProfileField({
    super.key,
    required this.label,
    required this.initialValue,
    required this.enabled,
    required this.onChanged,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        initialValue: initialValue,
        enabled: enabled,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          filled: !enabled,
          fillColor: enabled ? null : Colors.grey[200],
        ),
        onChanged: onChanged,
        validator: validator,
      ),
    );
  }
}

// Placeholder widgets for other tabs
class PasswordTab extends StatelessWidget {
  const PasswordTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(child: Text(AppLocalizations.of(context)!.passwordTab));
  }
}

class DreamHistoryTab extends StatelessWidget {
  const DreamHistoryTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(child: Text(AppLocalizations.of(context)!.dreamHistoryTab));
  }
}

class DreamStatisticsTab extends StatelessWidget {
  const DreamStatisticsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(child: Text(AppLocalizations.of(context)!.dreamStatisticsTab));
  }
}
