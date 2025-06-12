import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../widgets/character_avatar.dart';

class ProfileSelectScreen extends StatelessWidget {
  const ProfileSelectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.primary, AppColors.backgroundYellow],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 40),
              const Text(
                'Select profile',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 80),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  mainAxisSpacing: 20,
                  crossAxisSpacing: 20,
                  children: [
                    _buildProfileCard('Lea', onTap: () {
                      Navigator.pushNamed(context, '/child-home');
                    }),
                    _buildAddProfileCard(context),
                    // Add more profile cards as needed
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: TextButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(context, '/parent-login');
                  },
                  icon: const Icon(Icons.settings, color: Colors.white),
                  label: const Text(
                    'Settings',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileCard(String name, {required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Card(
        color: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CharacterAvatar(
              radius: 40,
              characterType: CharacterType.hero1,
            ),
            const SizedBox(height: 16),
            Text(
              name,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddProfileCard(BuildContext context) {
    return InkWell(
      onTap: () {
        // Show dialog to add new profile
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Add New Profile'),
              content: TextField(
                decoration: const InputDecoration(
                  hintText: "Enter child's name",
                ),
                autofocus: true,
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    // Add profile logic here
                    Navigator.of(context).pop();
                  },
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
      child: Card(
        color: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_circle_outline,
              size: 60,
              color: AppColors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'Add New',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
