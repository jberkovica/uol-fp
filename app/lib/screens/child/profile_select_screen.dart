import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_theme.dart';
import '../../widgets/profile_avatar.dart';
import '../../widgets/responsive_wrapper.dart';
import '../../services/auth_service.dart';
import '../../services/kid_service.dart';
import '../../services/app_state_service.dart';
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
    String selectedAvatarType = 'profile1';

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
                style: Theme.of(context).textTheme.headlineLarge,
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
                    style: Theme.of(context).textTheme.headlineLarge,
                    autofocus: true,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Choose Avatar:',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: ProfileType.values.map((type) {
                      final typeString = ProfileAvatar.typeToString(type);
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
                          child: ProfileAvatar(
                            radius: 28, // Smaller for mobile dialog
                            profileType: type,
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
                    style: Theme.of(context).textTheme.headlineLarge,
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
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.w600),
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

  ProfileType _getProfileType(String avatarType) {
    return ProfileAvatar.fromString(avatarType);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.secondary,
      body: Column(
        children: [
          // Consistent header using AppTheme
          AppTheme.screenHeader(
            context: context,
            title: 'Select profile',
            action: GestureDetector(
              onTap: () {
                Navigator.pushNamed(context, '/parent-dashboard');
              },
              child: const Icon(
                LucideIcons.settings,
                color: AppColors.textDark,
                size: 24,
              ),
            ),
          ),
          // Content
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
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.error,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadKids,
                              child: Text(
                                'Retry',
                                style: Theme.of(context).textTheme.headlineLarge,
                              ),
                            ),
                          ],
                        ),
                      )
                    : _buildModernProfileLayout(),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard(
    String name, {
    required VoidCallback onTap,
    ProfileType profileType = ProfileType.profile1,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: const BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.all(Radius.circular(20)),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Calculate avatar size based on screen width
              double avatarRadius;
              double fontSize;
              double padding;
              
              if (constraints.maxWidth < 600) {
                // Mobile: Large avatars but fit in card
                avatarRadius = 50.0;
                fontSize = 18.0;
                padding = 20.0;
              } else if (constraints.maxWidth < 900) {
                // Tablet: Medium avatars
                avatarRadius = 45.0;
                fontSize = 16.0;
                padding = 18.0;
              } else {
                // Desktop: Smaller avatars for grid
                avatarRadius = 40.0;
                fontSize = 14.0;
                padding = 16.0;
              }
              
              // Always use vertical centered layout (YouTube/Netflix style)
              return Padding(
                padding: EdgeInsets.all(padding),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ProfileAvatar(
                      radius: avatarRadius,
                      profileType: profileType,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      name,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontSize: fontSize,
                        color: AppColors.textDark,
                      ),
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }


  Widget _buildModernProfileLayout() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        
        if (screenWidth < 768) {
          // Mobile/Small tablet: Single column
          return _buildSingleColumnLayout();
        } else {
          // Large tablet/Desktop: Two columns
          return _buildTwoColumnLayout();
        }
      },
    );
  }

  Widget _buildSingleColumnLayout() {
    return SingleChildScrollView(
      padding: ResponsiveBreakpoints.getResponsiveAllPadding(context),
      child: Column(
        children: [
          ..._kids.map((kid) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _buildSimpleProfileCard(
              name: kid.name,
              profileType: _getProfileType(kid.avatarType),
              onTap: () {
                // Save selected kid to local storage
                AppStateService.saveSelectedKid(kid);
                Navigator.pushNamed(
                  context,
                  '/child-home',
                  arguments: kid,
                );
              },
            ),
          )),
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _buildAddProfileCard(),
          ),
        ],
      ),
    );
  }

  Widget _buildTwoColumnLayout() {
    final allItems = <Widget>[
      ..._kids.map((kid) => _buildSimpleProfileCard(
        name: kid.name,
        profileType: _getProfileType(kid.avatarType),
        onTap: () {
          // Save selected kid to local storage
          AppStateService.saveSelectedKid(kid);
          Navigator.pushNamed(
            context,
            '/child-home',
            arguments: kid,
          );
        },
      )),
      _buildAddProfileCard(),
    ];

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600), // Limit max width to group profiles
        child: GridView.count(
          padding: const EdgeInsets.all(24),
          crossAxisCount: 2,
          mainAxisSpacing: 8, // Further reduced vertical spacing
          crossAxisSpacing: 16, // Keep horizontal spacing
          childAspectRatio: 1.2,
          shrinkWrap: true,
          physics: const AlwaysScrollableScrollPhysics(),
          children: allItems,
        ),
      ),
    );
  }

  Widget _buildSimpleProfileCard({
    required String name,
    required ProfileType profileType,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ProfileAvatar(
              radius: 60, // Increased from 50 to 60
              profileType: profileType,
            ),
            const SizedBox(height: 12),
            Text(
              name,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.normal, // Changed from bold to normal
                color: AppColors.textDark,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddProfileCard() {
    return GestureDetector(
      onTap: _showCreateKidDialog,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.orange.withValues(alpha: 0.3), // Light orange like in your design
                shape: BoxShape.circle,
              ),
              child: const Icon(
                LucideIcons.plus,
                size: 32,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Add profile',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.normal,
                color: AppColors.textDark,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
