import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class HelpCenterScreen extends StatelessWidget {
  const HelpCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.helpCenterTitle),
        backgroundColor: theme.colorScheme.inversePrimary,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildSection(
            context,
            title: l10n.helpCenterBasicsTitle,
            icon: Icons.info_outline,
            children: [
              _buildHelpItem(
                context,
                title: l10n.helpCenterBasicsAddTitle,
                description: l10n.helpCenterBasicsAddDescription,
                icon: Icons.add_circle_outline,
              ),
              _buildHelpItem(
                context,
                title: l10n.helpCenterBasicsEditTitle,
                description: l10n.helpCenterBasicsEditDescription,
                icon: Icons.edit,
              ),
              _buildHelpItem(
                context,
                title: l10n.helpCenterBasicsDeleteTitle,
                description: l10n.helpCenterBasicsDeleteDescription,
                icon: Icons.delete_outline,
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSection(
            context,
            title: l10n.helpCenterVoiceTitle,
            icon: Icons.mic,
            children: [
              _buildHelpItem(
                context,
                title: l10n.helpCenterVoiceInputTitle,
                description: l10n.helpCenterVoiceInputDescription,
                icon: Icons.record_voice_over,
              ),
              _buildHelpItem(
                context,
                title: l10n.helpCenterVoiceTipsTitle,
                description: l10n.helpCenterVoiceTipsDescription,
                icon: Icons.lightbulb_outline,
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSection(
            context,
            title: l10n.helpCenterFAQTitle,
            icon: Icons.question_answer,
            children: [
              _buildFAQItem(
                context,
                question: l10n.helpCenterFAQ1Question,
                answer: l10n.helpCenterFAQ1Answer,
              ),
              _buildFAQItem(
                context,
                question: l10n.helpCenterFAQ2Question,
                answer: l10n.helpCenterFAQ2Answer,
              ),
              _buildFAQItem(
                context,
                question: l10n.helpCenterFAQ3Question,
                answer: l10n.helpCenterFAQ3Answer,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...children,
      ],
    );
  }

  Widget _buildHelpItem(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
  }) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: theme.colorScheme.secondary, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFAQItem(
    BuildContext context, {
    required String question,
    required String answer,
  }) {
    return ExpansionTile(
      title: Text(
        question,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Text(answer),
        ),
      ],
    );
  }
}
