import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/text_styles.dart';
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
  String _selectedDistrict = 'Pune'; 

  final List<String> _districts = [
    'Pune', 'Mumbai', 'Nagpur', 'Nashik', 'Aurangabad', 'Solapur'
  ];

  final List<String> _avatars = const [
    'luffy.jpg', 'zoro.jpg', 'sanji.jpg', 'Nami.jpg',
    'chopper.jpg', 'robin.jpg', 'ussop.jpg', 'brook.jpg', 'frenky.jpg'
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
    ref.read(userStoreProvider.notifier).updateProfile(
      username: _usernameController.text.trim(),
      avatarId: _selectedAvatar,
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1115),
      appBar: AppBar(
        title: Text('Edit Profile', style: AppTextStyles.h2.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_rounded, color: Colors.white70),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          )
        ],
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Background Glow
          Positioned(
            top: 50,
            left: -100,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
              child: Container(
                width: 300,
              height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primaryMint.withValues(alpha: 0.1),
                ),
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Choose Avatar', style: AppTextStyles.h3.copyWith(color: Colors.white)).animate().fade().slideX(),
                  const SizedBox(height: 16),
                  
                  // Avatar Grid (Glassmorphism)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                        ),
                        child: GridView.builder(
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
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isSelected ? AppColors.primaryMint : Colors.white10,
                                    width: isSelected ? 3 : 1,
                                  ),
                                  boxShadow: isSelected ? [
                                    BoxShadow(color: AppColors.primaryMint.withValues(alpha: 0.5), blurRadius: 15)
                                  ] : [],
                                ),
                                child: ClipOval(
                                  child: Image.asset(
                                    'assets/avatars/$avatar',
                                    fit: BoxFit.cover,
                                    errorBuilder: (ctx, error, stackTrace) => CircleAvatar(
                                      backgroundColor: const Color(0xFF1A1D24),
                                      child: Text(
                                        '${index + 1}',
                                        style: AppTextStyles.body.copyWith(
                                          color: isSelected ? AppColors.primaryMint : Colors.white54,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ).animate().fade(delay: (100 + index * 50).ms).scale();
                          },
                        ),
                      ),
                    ),
                  ).animate().fade(delay: 200.ms).slideY(),
                  
                  const SizedBox(height: 32),
                  
                  Text('Username', style: AppTextStyles.h3.copyWith(color: Colors.white)).animate().fade(delay: 300.ms),
                  const SizedBox(height: 12),
                  _buildGlassTextField(
                    controller: _usernameController,
                    hint: 'Enter your username',
                    icon: Icons.person_rounded,
                  ).animate().fade(delay: 400.ms).slideY(begin: 0.1),
                  
                  const SizedBox(height: 24),

                  Text('District', style: AppTextStyles.h3.copyWith(color: Colors.white)).animate().fade(delay: 500.ms),
                  const SizedBox(height: 12),
                  _buildGlassDropdown().animate().fade(delay: 600.ms).slideY(begin: 0.1),
                  
                  const SizedBox(height: 48),

                  GestureDetector(
                    onTap: _saveProfile,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      decoration: BoxDecoration(
                        color: AppColors.primaryMint,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(color: AppColors.primaryMint.withValues(alpha: 0.4), blurRadius: 20, offset: const Offset(0, 5))
                        ],
                      ),
                      child: Center(
                        child: Text(
                          'SAVE PROFILE',
                          style: AppTextStyles.h2.copyWith(color: AppColors.deepTealNavy, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ).animate().fade(delay: 700.ms).slideY(begin: 0.2, curve: Curves.easeOutBack),
                  
                  const SizedBox(height: 48),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassTextField({required TextEditingController controller, required String hint, required IconData icon}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: TextField(
          controller: controller,
          style: AppTextStyles.body.copyWith(color: Colors.white),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.05),
            hintText: hint,
            hintStyle: AppTextStyles.body.copyWith(color: Colors.white30),
            prefixIcon: Icon(icon, color: Colors.white54),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1), width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1), width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.primaryMint, width: 2),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassDropdown() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedDistrict,
              isExpanded: true,
              dropdownColor: const Color(0xFF1A1D24), // Solid color for dropdown menu
              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white54),
              style: AppTextStyles.body.copyWith(color: Colors.white),
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
      ),
    );
  }
}
