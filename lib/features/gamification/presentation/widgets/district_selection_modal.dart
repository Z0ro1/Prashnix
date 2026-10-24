import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/district_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/text_styles.dart';

/// Clean, searchable district selector modal supporting light and dark themes.
class DistrictSelectionModal extends StatefulWidget {
  final String currentDistrict;
  final ValueChanged<String> onDistrictSelected;

  const DistrictSelectionModal({
    super.key,
    required this.currentDistrict,
    required this.onDistrictSelected,
  });

  static Future<void> show({
    required BuildContext context,
    required String currentDistrict,
    required ValueChanged<String> onDistrictSelected,
  }) {
    return showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      builder: (ctx) => DistrictSelectionModal(
        currentDistrict: currentDistrict,
        onDistrictSelected: onDistrictSelected,
      ),
    );
  }

  @override
  State<DistrictSelectionModal> createState() => _DistrictSelectionModalState();
}

class _DistrictSelectionModalState extends State<DistrictSelectionModal> {
  final TextEditingController _searchController = TextEditingController();
  List<String> _filtered = DistrictConstants.maharashtraDistricts;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filtered = DistrictConstants.maharashtraDistricts;
      } else {
        _filtered = DistrictConstants.maharashtraDistricts
            .where((d) => d.toLowerCase().contains(query))
            .toList();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF161F26) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1F2937);
    final mutedColor = isDark ? Colors.white60 : const Color(0xFF6B7280);
    final borderColor = isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.08);
    final inputBg = isDark ? Colors.white.withValues(alpha: 0.07) : const Color(0xFFF3F4F6);

    return Material(
      color: Colors.transparent,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.75,
        ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(top: BorderSide(color: borderColor, width: 1.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 30,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag Handle
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryGreen.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.location_on_rounded,
                      color: AppColors.primaryGreen,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Select District Leaderboard',
                          style: AppTextStyles.h3.copyWith(
                            color: textColor,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          'Maharashtra (36 Districts)',
                          style: AppTextStyles.caption.copyWith(color: mutedColor),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close_rounded, color: mutedColor),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Container(
                decoration: BoxDecoration(
                  color: inputBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderColor),
                ),
                child: TextField(
                  controller: _searchController,
                  style: TextStyle(color: textColor, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Search district (e.g. Nashik, Pune)...',
                    hintStyle: TextStyle(color: mutedColor, fontSize: 14),
                    prefixIcon: Icon(Icons.search_rounded, color: mutedColor, size: 20),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear_rounded, color: mutedColor, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              _onSearchChanged();
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 6),

            // District List
            Flexible(
              child: _filtered.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Text(
                        'No matching districts found.',
                        style: TextStyle(color: mutedColor),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _filtered.length,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemBuilder: (context, index) {
                        final district = _filtered[index];
                        final isSelected = district.toLowerCase() == widget.currentDistrict.toLowerCase();

                        return Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primaryGreen.withValues(alpha: isDark ? 0.15 : 0.1)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(14),
                            border: isSelected
                                ? Border.all(color: AppColors.primaryGreen.withValues(alpha: 0.6), width: 1.5)
                                : null,
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: () {
                                HapticFeedback.lightImpact();
                                Navigator.of(context).pop();
                                widget.onDistrictSelected(district);
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.pin_drop_rounded,
                                      size: 18,
                                      color: isSelected ? AppColors.primaryGreen : mutedColor,
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Text(
                                        district,
                                        style: TextStyle(
                                          color: isSelected ? (isDark ? Colors.white : AppColors.primaryGreenDark) : textColor,
                                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ),
                                    if (isSelected)
                                      Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: const BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: AppColors.primaryGreen,
                                        ),
                                        child: const Icon(
                                          Icons.check,
                                          size: 14,
                                          color: Colors.white,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}
