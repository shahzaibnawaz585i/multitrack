import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:multitrack/screens/login_screen.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingScreen extends StatefulWidget {
  const SettingScreen({super.key});

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  static const Color backgroundColor = Color(0xFFF7F7F7);
  static const Color textColor = Color(0xFF292B32);
  static const Color pinkColor = Color(0xFFFF2F68);

  static const String _profileImageKey = 'saved_profile_image_path';

  final ImagePicker _imagePicker = ImagePicker();

  File? _selectedImage;

  @override
  void initState() {
    super.initState();

    _loadSavedProfileImage();
  }

  // ============================================================
  // LOAD SAVED PROFILE IMAGE
  // ============================================================

  Future<void> _loadSavedProfileImage() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();

      final String? savedPath = prefs.getString(_profileImageKey);

      if (savedPath == null || savedPath.isEmpty) {
        return;
      }

      final File savedImage = File(savedPath);

      final bool exists = await savedImage.exists();

      if (!exists) {
        await prefs.remove(_profileImageKey);
        return;
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _selectedImage = savedImage;
      });
    } catch (error) {
      debugPrint('LOAD PROFILE IMAGE ERROR: $error');
    }
  }

  // ============================================================
  // OPEN GALLERY + SAVE IMAGE PERMANENTLY
  // ============================================================

  Future<void> _openGallery() async {
    try {
      final XFile? pickedImage = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1200,
      );

      if (pickedImage == null) {
        return;
      }

      final Directory appDirectory = await getApplicationDocumentsDirectory();

      final String extension = pickedImage.path.contains('.')
          ? pickedImage.path.substring(pickedImage.path.lastIndexOf('.'))
          : '.jpg';

      final String permanentImagePath =
          '${appDirectory.path}/profile_image$extension';

      final File permanentImage = await File(
        pickedImage.path,
      ).copy(permanentImagePath);

      final SharedPreferences prefs = await SharedPreferences.getInstance();

      await prefs.setString(_profileImageKey, permanentImage.path);

      if (!mounted) {
        return;
      }

      setState(() {
        _selectedImage = permanentImage;
      });

      debugPrint('PROFILE IMAGE SAVED: ${permanentImage.path}');
    } catch (error, stackTrace) {
      debugPrint('IMAGE PICKER ERROR: $error');

      debugPrint('STACK TRACE: $stackTrace');

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gallery Error: $error')));
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,

      body: SafeArea(
        bottom: false,

        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),

          padding: const EdgeInsets.only(
            left: 10,
            right: 10,
            top: 50,
            bottom: 110,
          ),

          child: Column(
            children: [
              _buildAccountCard(),

              const SizedBox(height: 10),

              _buildSettingsCard(),

              const SizedBox(height: 10),

              const Text(
                'version 99.71.197',
                style: TextStyle(
                  color: textColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
              ),

              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // ACCOUNT CARD
  // ============================================================

  Widget _buildAccountCard() {
    return Stack(
      clipBehavior: Clip.none,

      children: [
        Container(
          width: double.infinity,
          height: 300,

          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),

          child: const Padding(
            padding: EdgeInsets.only(left: 38, right: 25, top: 85),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                AccountInfo(label: 'Name', value: 'mtdemo1'),

                SizedBox(height: 35),

                AccountInfo(label: 'User ID', value: 'mtdemo1'),

                SizedBox(height: 35),

                AccountInfo(label: 'Mobile Number', value: ''),
              ],
            ),
          ),
        ),

        const Positioned(
          top: 4,
          left: 120,

          child: Text(
            'Account',

            style: TextStyle(
              color: textColor,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        Positioned(top: -30, left: 25, child: _buildProfileImage()),
      ],
    );
  }

  // ============================================================
  // PROFILE IMAGE
  // ============================================================

  Widget _buildProfileImage() {
    return Stack(
      clipBehavior: Clip.none,

      children: [
        Container(
          width: 80,
          height: 80,

          padding: const EdgeInsets.all(5),

          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,

            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.10),
                blurRadius: 12,
                spreadRadius: 1,
                offset: const Offset(0, 3),
              ),
            ],
          ),

          child: ClipOval(
            child: _selectedImage != null
                ? Image.file(
                    _selectedImage!,
                    key: ValueKey(_selectedImage!.path),
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,

                    errorBuilder: (context, error, stackTrace) {
                      return _buildDefaultProfileImage();
                    },
                  )
                : _buildDefaultProfileImage(),
          ),
        ),

        Positioned(
          right: -2,
          bottom: 4,

          child: Material(
            color: pinkColor,
            shape: const CircleBorder(),
            elevation: 3,

            child: InkWell(
              onTap: _openGallery,
              customBorder: const CircleBorder(),

              child: const SizedBox(
                width: 38,
                height: 38,

                child: Icon(Icons.camera_alt, color: Colors.white, size: 20),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // DEFAULT PROFILE IMAGE
  // ============================================================

  Widget _buildDefaultProfileImage() {
    return Image.asset(
      'assets/profile.jpeg',

      width: double.infinity,
      height: double.infinity,

      fit: BoxFit.cover,

      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: const Color(0xFFF5F5F5),

          alignment: Alignment.center,

          child: const Icon(Icons.person, size: 65, color: Colors.grey),
        );
      },
    );
  }

  // ============================================================
  // SETTINGS CARD
  // ============================================================

  Widget _buildSettingsCard() {
    return Container(
      width: double.infinity,

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),

      child: Padding(
        padding: const EdgeInsets.only(
          left: 25,
          right: 20,
          top: 22,
          bottom: 15,
        ),

        child: Column(
          children: [
            Row(
              children: [
                SizedBox(
                  width: 40,
                  height: 40,

                  child: Image.asset(
                    'assets/settings.jpeg',
                    fit: BoxFit.contain,

                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Icons.settings,
                        color: Color(0xFF4D91C5),
                        size: 50,
                      );
                    },
                  ),
                ),

                const SizedBox(width: 22),

                const Text(
                  'Settings',

                  style: TextStyle(
                    color: textColor,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            SettingItem(
              image: 'assets/app_setting.png',
              title: 'App Settings' ,

              onTap: () {
                debugPrint('App Settings Clicked');
              },
            ),


            SettingItem(
              image: 'assets/live_support.png',
              title: 'Live Support',

              onTap: () {
                debugPrint('Live Support Clicked');
              },
            ),

            SettingItem(
              image: 'assets/downloaded_report.png',
              title: 'Downloaded Reports',

              onTap: () {
                debugPrint('Downloaded Reports Clicked');
              },
            ),

            SettingItem(
              image: 'assets/sign_out.png',
              title: 'Sign Out',

              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => LoginScreen()),
                );
               },
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// ACCOUNT INFO
// ============================================================

class AccountInfo extends StatelessWidget {
  final String label;
  final String value;

  const AccountInfo({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        Text(
          label,

          style: const TextStyle(
            color: Color(0xFFA8A8A8),
            fontSize: 12,
            fontWeight: FontWeight.w100,
          ),
        ),

        const SizedBox(height: 8),

        Text(
          value,

          style: const TextStyle(
            color: Color(0xFF292B32),
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }
}

// ============================================================
// SETTING ITEM
// ============================================================

class SettingItem extends StatelessWidget {
  final String image;
  final String title;
  final VoidCallback onTap;

  const SettingItem({
    super.key,
    required this.image,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,

      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),

        child: SizedBox(
          height: 50,

          child: Row(
            children: [
              SizedBox(
                width: 25,
                height: 25,

                child: Image.asset(
                  image,
                  fit: BoxFit.contain,

                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(
                      Icons.settings_outlined,
                      size: 35,
                      color: Colors.grey,
                    );
                  },
                ),
              ),

              const SizedBox(width: 18),

              Expanded(
                child: Text(
                  title,

                  style: const TextStyle(
                    color: Color(0xFF292B32),
                    fontSize: 14,
                    fontWeight: FontWeight(1)
                   ),
                ),
              ),

              const Icon(Icons.arrow_right, color: Color(0xFFFF2F68), size: 28),
            ],
          ),
        ),
      ),
    );
  }
}
