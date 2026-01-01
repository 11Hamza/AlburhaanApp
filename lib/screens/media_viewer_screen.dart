import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/book.dart';

enum MediaType { youtube, pdf, ebook }

class MediaViewerScreen extends StatelessWidget {
  final Book book;

  const MediaViewerScreen({super.key, required this.book});

  bool get hasYoutube => book.youtubeUrl != null && book.youtubeUrl!.isNotEmpty;
  bool get hasPdf => book.pdfUrl != null && book.pdfUrl!.isNotEmpty;
  bool get hasEbook => book.ebookUrl != null && book.ebookUrl!.isNotEmpty;
  bool get hasAnyMedia => hasYoutube || hasPdf || hasEbook;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (!hasAnyMedia) {
      return Scaffold(
        appBar: AppBar(title: const Text('Media')),
        body: const Center(
          child: Text('No media available for this book'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Available Media'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Book Info Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    colorScheme.primaryContainer,
                    colorScheme.primaryContainer.withOpacity(0.5),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Icon(Icons.book, size: 40, color: colorScheme.primary),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          book.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (book.author != null)
                          Text(
                            book.author!,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onPrimaryContainer.withOpacity(0.7),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            Text(
              'Available Content',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // YouTube Video Card
            if (hasYoutube)
              _MediaCard(
                icon: Icons.play_circle_filled,
                iconColor: Colors.red,
                title: 'Video Lecture',
                subtitle: 'Watch on YouTube',
                description: 'Watch video content related to this book',
                onTap: () => _launchUrl(context, book.youtubeUrl!),
              ),

            // PDF Card
            if (hasPdf)
              _MediaCard(
                icon: Icons.picture_as_pdf,
                iconColor: Colors.orange,
                title: 'PDF Document',
                subtitle: 'View or Download',
                description: 'Read the PDF version of this content',
                onTap: () => _launchUrl(context, book.pdfUrl!),
              ),

            // Ebook Card
            if (hasEbook)
              _MediaCard(
                icon: Icons.menu_book,
                iconColor: Colors.green,
                title: 'E-Book',
                subtitle: 'Read Online',
                description: 'Access the digital book version',
                onTap: () => _launchUrl(context, book.ebookUrl!),
              ),

            const SizedBox(height: 24),

            // Info note
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: colorScheme.onSurfaceVariant),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Content will open in your browser or appropriate app',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchUrl(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not open: $url')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error opening link: $e')),
        );
      }
    }
  }
}

class _MediaCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String description;
  final VoidCallback onTap;

  const _MediaCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 32),
              ),
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
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: iconColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A compact widget to show media buttons inline
class MediaButtonsRow extends StatelessWidget {
  final Book book;

  const MediaButtonsRow({super.key, required this.book});

  bool get hasYoutube => book.youtubeUrl != null && book.youtubeUrl!.isNotEmpty;
  bool get hasPdf => book.pdfUrl != null && book.pdfUrl!.isNotEmpty;
  bool get hasEbook => book.ebookUrl != null && book.ebookUrl!.isNotEmpty;
  bool get hasAnyMedia => hasYoutube || hasPdf || hasEbook;

  @override
  Widget build(BuildContext context) {
    if (!hasAnyMedia) return const SizedBox.shrink();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (hasYoutube)
          _MediaIconButton(
            icon: Icons.play_circle_filled,
            color: Colors.red,
            tooltip: 'Watch Video',
            url: book.youtubeUrl!,
          ),
        if (hasPdf)
          _MediaIconButton(
            icon: Icons.picture_as_pdf,
            color: Colors.orange,
            tooltip: 'View PDF',
            url: book.pdfUrl!,
          ),
        if (hasEbook)
          _MediaIconButton(
            icon: Icons.menu_book,
            color: Colors.green,
            tooltip: 'Read E-Book',
            url: book.ebookUrl!,
          ),
      ],
    );
  }
}

class _MediaIconButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String tooltip;
  final String url;

  const _MediaIconButton({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.url,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: () => _launchUrl(context, url),
          borderRadius: BorderRadius.circular(8),
          child: Tooltip(
            message: tooltip,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Icon(icon, color: color, size: 22),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _launchUrl(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not open: $url')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error opening link: $e')),
        );
      }
    }
  }
}
