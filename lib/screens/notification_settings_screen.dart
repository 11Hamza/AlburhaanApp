import 'package:flutter/material.dart';
import '../services/notification_service.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  final NotificationService _notificationService = NotificationService();

  bool _holdReady = true;
  bool _dueSoon = true;
  bool _overdue = true;
  bool _newBooks = false;
  bool _newVideos = false;
  bool _announcements = true;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    // In a real app, load from SharedPreferences or backend
    // For now, use defaults
  }

  Future<void> _saveSettings() async {
    setState(() => _isSaving = true);

    try {
      // Subscribe/unsubscribe from FCM topics based on settings
      if (_holdReady) {
        await _notificationService.subscribeToTopic('hold_ready');
      } else {
        await _notificationService.unsubscribeFromTopic('hold_ready');
      }

      if (_dueSoon) {
        await _notificationService.subscribeToTopic('due_soon');
      } else {
        await _notificationService.unsubscribeFromTopic('due_soon');
      }

      if (_overdue) {
        await _notificationService.subscribeToTopic('overdue');
      } else {
        await _notificationService.unsubscribeFromTopic('overdue');
      }

      if (_newBooks) {
        await _notificationService.subscribeToTopic('new_books');
      } else {
        await _notificationService.unsubscribeFromTopic('new_books');
      }

      if (_newVideos) {
        await _notificationService.subscribeToTopic('new_videos');
      } else {
        await _notificationService.unsubscribeFromTopic('new_videos');
      }

      if (_announcements) {
        await _notificationService.subscribeToTopic('announcements');
      } else {
        await _notificationService.unsubscribeFromTopic('announcements');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notification settings saved')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save settings: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Settings'),
      ),
      body: ListView(
        children: [
          // Account Notifications
          _SectionHeader(title: 'Account Notifications'),
          _NotificationTile(
            icon: Icons.bookmark,
            iconColor: Colors.green,
            title: 'Hold Ready',
            subtitle: 'When your held book is ready for pickup',
            value: _holdReady,
            onChanged: (v) => setState(() => _holdReady = v),
          ),
          _NotificationTile(
            icon: Icons.schedule,
            iconColor: Colors.orange,
            title: 'Due Soon',
            subtitle: 'Reminder before books are due',
            value: _dueSoon,
            onChanged: (v) => setState(() => _dueSoon = v),
          ),
          _NotificationTile(
            icon: Icons.warning,
            iconColor: Colors.red,
            title: 'Overdue',
            subtitle: 'When books become overdue',
            value: _overdue,
            onChanged: (v) => setState(() => _overdue = v),
          ),

          const Divider(height: 32),

          // Content Notifications
          _SectionHeader(title: 'Content Updates'),
          _NotificationTile(
            icon: Icons.library_books,
            iconColor: Colors.blue,
            title: 'New Books',
            subtitle: 'When new books are added to the library',
            value: _newBooks,
            onChanged: (v) => setState(() => _newBooks = v),
          ),
          _NotificationTile(
            icon: Icons.video_library,
            iconColor: Colors.purple,
            title: 'New Videos',
            subtitle: 'When new videos are added',
            value: _newVideos,
            onChanged: (v) => setState(() => _newVideos = v),
          ),

          const Divider(height: 32),

          // General
          _SectionHeader(title: 'General'),
          _NotificationTile(
            icon: Icons.campaign,
            iconColor: Colors.teal,
            title: 'Announcements',
            subtitle: 'Library news and announcements',
            value: _announcements,
            onChanged: (v) => setState(() => _announcements = v),
          ),

          const SizedBox(height: 24),

          // Save Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: FilledButton(
              onPressed: _isSaving ? null : _saveSettings,
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Save Settings'),
            ),
          ),

          const SizedBox(height: 16),

          // Info Text
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Notification preferences are synced with your device. You can also manage notifications in your device settings.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _NotificationTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      secondary: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: iconColor, size: 24),
      ),
      title: Text(title),
      subtitle: Text(
        subtitle,
        style: Theme.of(context).textTheme.bodySmall,
      ),
      value: value,
      onChanged: onChanged,
    );
  }
}
