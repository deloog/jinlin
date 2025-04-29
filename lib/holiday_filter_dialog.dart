import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:jinlin_app/special_date.dart';

class HolidayFilterDialog extends StatefulWidget {
  final Set<SpecialDateType> selectedTypes;
  final Function(Set<SpecialDateType>) onApply;

  const HolidayFilterDialog({
    Key? key,
    required this.selectedTypes,
    required this.onApply,
  }) : super(key: key);

  @override
  State<HolidayFilterDialog> createState() => _HolidayFilterDialogState();
}

class _HolidayFilterDialogState extends State<HolidayFilterDialog> {
  late Set<SpecialDateType> _selectedTypes;

  @override
  void initState() {
    super.initState();
    // 创建一个副本，避免直接修改传入的集合
    _selectedTypes = Set.from(widget.selectedTypes);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text(l10n.holidayFilterTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.holidayFilterDescription,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            _buildCheckboxTile(
              SpecialDateType.statutory,
              l10n.statutoryHoliday,
              Colors.red[700]!,
              Icons.flag_circle,
            ),
            _buildCheckboxTile(
              SpecialDateType.traditional,
              l10n.traditionalHoliday,
              Colors.orange[700]!,
              Icons.cake,
            ),
            _buildCheckboxTile(
              SpecialDateType.memorial,
              l10n.memorialDay,
              Colors.blue[700]!,
              Icons.star_border,
            ),
            _buildCheckboxTile(
              SpecialDateType.solarTerm,
              l10n.solarTerm,
              Colors.green[700]!,
              Icons.wb_sunny,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancelButton),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onApply(_selectedTypes);
            Navigator.of(context).pop();
          },
          child: Text(l10n.applyButton),
        ),
      ],
    );
  }

  Widget _buildCheckboxTile(
    SpecialDateType type,
    String title,
    Color color,
    IconData icon,
  ) {
    return CheckboxListTile(
      title: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Text(title),
        ],
      ),
      value: _selectedTypes.contains(type),
      activeColor: color,
      onChanged: (bool? value) {
        setState(() {
          if (value == true) {
            _selectedTypes.add(type);
          } else {
            _selectedTypes.remove(type);
          }
        });
      },
    );
  }
}
