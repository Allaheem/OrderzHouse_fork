// ??? ????????
import 'package:flutter/material.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../l10n/app_localizations.dart';

class CreateProjectScreen extends StatelessWidget {
  const CreateProjectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.createProject)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            AppTextField(label: l10n.projectTitle),
            const SizedBox(height: AppSpacing.md),
            AppTextField(label: l10n.projectDescription, maxLines: 5),
            const SizedBox(height: AppSpacing.md),
            DropdownButtonFormField<String>(
              decoration: InputDecoration(labelText: l10n.projectType),
              items: [
                DropdownMenuItem(value: 'fixed', child: Text(l10n.fixedPrice)),
                DropdownMenuItem(value: 'hourly', child: Text(l10n.hourlyRate)),
                const DropdownMenuItem(
                  value: 'bidding',
                  child: Text('Bidding'),
                ),
              ],
              onChanged: (value) {},
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              label: l10n.budget,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: AppSpacing.lg),
            PrimaryButton(
              label: l10n.createProject,
              onPressed: () {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(l10n.projectCreated)));
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
