import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_theme.dart';
import '../../widgets/character_avatar.dart';
import '../../services/auth_service.dart';
import '../../services/kid_service.dart';
import '../../models/kid.dart';

class ProfileSelectScreen extends StatefulWidget {
  const ProfileSelectScreen({super.key});

  @override
  State<ProfileSelectScreen> createState() => _ProfileSelectScreenState();
}

class _ProfileSelectScreenState extends State<ProfileSelectScreen> {
  List<Kid> _kids = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadKids();
  }

  Future<void> _loadKids() async {
    try {
      final user = AuthService.instance.currentUser;
      if (user == null) {
        setState(() {
          _errorMessage = 'User not authenticated';
          _isLoading = false;
        });
        return;
      }

      final kids = await KidService.getKidsForUser(user.id);
      setState(() {
        _kids = kids;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load profiles: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _showCreateKidDialog() async {
    final nameController = TextEditingController();
    String selectedAvatarType = 'hero1';

    final result = await showDialog<Kid>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.white,
              elevation: 0,
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Text(
                'Add New Profile',
                style: GoogleFonts.manrope(fontWeight: FontWeight.bold),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      hintText: "Enter child's name",
                      border: OutlineInputBorder(),
                    ),
                    style: GoogleFonts.manrope(),
                    autofocus: true,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Choose Avatar:',
                    style: GoogleFonts.manrope(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    children: CharacterType.values.map((type) {
                      final typeString = type.toString().split('.').last;
                      return GestureDetector(
                        onTap: () {
                          setDialogState(() {
                            selectedAvatarType = typeString;
                          });
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: selectedAvatarType == typeString
                                ? Border.all(color: AppColors.primary, width: 3)
                                : null,
                          ),
                          child: CharacterAvatar(
                            radius: 25,
                            characterType: type,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.manrope(),
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (nameController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please enter a name')),
                      );
                      return;
                    }

                    try {
                      final user = AuthService.instance.currentUser;
                      if (user == null) throw Exception('User not authenticated');

                      final newKid = await KidService.createKid(
                        userId: user.id,
                        name: nameController.text.trim(),
                        avatarType: selectedAvatarType,
                      );
                      Navigator.of(context).pop(newKid);
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to create profile: $e')),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    shadowColor: Colors.transparent,
                    surfaceTintColor: Colors.transparent,
                  ),
                  child: Text(
                    'Add',
                    style: GoogleFonts.manrope(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != null) {
      setState(() {
        _kids.add(result);
      });
    }
  }

  CharacterType _getCharacterType(String avatarType) {
    switch (avatarType) {
      case 'hero1':
        return CharacterType.hero1;
      case 'hero2':
        return CharacterType.hero2;
      case 'cloud':
        return CharacterType.cloud;
      default:
        return CharacterType.hero1;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.whiteScreenBackground,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 40),
            Text(
              'Select profile',
              style: GoogleFonts.manrope(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 80),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessage != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _errorMessage!,
                                style: GoogleFonts.manrope(
                                  color: Colors.red,
                                  fontSize: 16,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _loadKids,
                                child: Text(
                                  'Retry',
                                  style: GoogleFonts.manrope(),
                                ),
                              ),
                            ],
                          ),
                        )
                      : GridView.count(
                          crossAxisCount: 2,
                          padding: const EdgeInsets.symmetric(horizontal: 30),
                          mainAxisSpacing: 20,
                          crossAxisSpacing: 20,
                          children: [
                            // Existing kids
                            ..._kids.map((kid) => _buildProfileCard(
                                  kid.name,
                                  avatarType: _getCharacterType(kid.avatarType),
                                  onTap: () {
                                    // Pass the selected kid to child home screen
                                    Navigator.pushNamed(
                                      context,
                                      '/child-home',
                                      arguments: kid,
                                    );
                                  },
                                )),
                            // Add new profile card
                            _buildAddProfileCard(context),
                          ],
                        ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushNamed(context, '/parent-login');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.textLight,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0, // NO shadow
                  shadowColor: Colors.transparent,
                  surfaceTintColor: Colors.transparent,
                ),
                icon: const Icon(Icons.settings, color: AppColors.textLight),
                label: Text(
                  'Settings',
                  style: GoogleFonts.manrope(
                    color: AppColors.textLight,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard(
    String name, {
    required VoidCallback onTap,
    CharacterType avatarType = CharacterType.hero1,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: const BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CharacterAvatar(
                radius: 40,
                characterType: avatarType,
              ),
              const SizedBox(height: 16),
              Text(
                name,
                style: GoogleFonts.manrope(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddProfileCard(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _showCreateKidDialog,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: const BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.all(Radius.circular(16)),
            // NO shadows, NO elevation, completely flat
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.add_circle_outline,
                size: 60,
                color: AppColors.grey,
              ),
              const SizedBox(height: 16),
              Text(
                'Add New',
                style: GoogleFonts.manrope(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
