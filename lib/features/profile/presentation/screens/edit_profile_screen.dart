import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/state/user_state.dart';
import 'settings_screen.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final TextEditingController _usernameController = TextEditingController();
  String _selectedAvatar = '';
  String _selectedDistrict = 'Pune'; // Default mock

  final List<String> _districts = [
    'Pune', 'Mumbai', 'Nagpur', 'Nashik', 'Aurangabad', 'Solapur'
  ];

  final List<String> _avatars = [
    'avatar_1.png', 'avatar_2.png', 'avatar_3.png', 'avatar_4.png',
    'avatar_5.png', 'avatar_6.png', 'avatar_7.png', 'avatar_8.png'
  ];

  @override
  void initState() {
    super.initState();
    final user = ref.read(userStoreProvider);
    _usernameController.text = user.username;
    _selectedAvatar = user.avatarId;
  }

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  void _saveProfile() {
    // Save to global user state
    ref.read(userStoreProvider.notifier).updateProfile(
      username: _usernameController.text.trim(),
      avatarId: _selectedAvatar,
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.backgroundDark : AppColors.backgroundLight;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Edit Profile', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.backgroundLight,
        elevation: 0,
        foregroundColor: textColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_rounded),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          )
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Choose Avatar', style: AppTypography.titleSemiBold.copyWith(color: textColor, fontSize: 18)),
              const SizedBox(height: 16),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: _avatars.length,
                itemBuilder: (context, index) {
                  final avatar = _avatars[index];
                  final isSelected = _selectedAvatar == avatar;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedAvatar = avatar;
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? AppColors.skyBlue : Colors.transparent,
                          width: 4,
                        ),
                      ),
                      child: CircleAvatar(
                        backgroundColor: AppColors.surfaceLight,
                        // If avatars don't exist yet, this will fallback nicely.
                        // We use a dummy child to show it's selectable for now if asset is missing.
                        child: Text('${index + 1}', style: const TextStyle(color: AppColors.textPrimaryLight, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 32),
              
              Text('Username', style: AppTypography.titleSemiBold.copyWith(color: textColor, fontSize: 18)),
              const SizedBox(height: 8),
              TextField(
                controller: _usernameController,
                style: TextStyle(color: textColor),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: isDark ? AppColors.surfaceDark : Colors.white,
                  hintText: 'Enter your username',
                  hintStyle: TextStyle(color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: AppColors.borderLight, width: 2),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: AppColors.borderLight, width: 2),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: AppColors.skyBlue, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              Text('District', style: AppTypography.titleSemiBold.copyWith(color: textColor, fontSize: 18)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDark : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderLight, width: 2),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedDistrict,
                    isExpanded: true,
                    dropdownColor: isDark ? AppColors.surfaceDark : Colors.white,
                    style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.w600),
                    items: _districts.map((String district) {
                      return DropdownMenuItem<String>(
                        value: district,
                        child: Text(district),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _selectedDistrict = newValue;
                        });
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 48),

              SizedBox(
                width: double.infinity,
                child: CustomButton(
                  text: 'SAVE PROFILE',
                  onPressed: _saveProfile,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
