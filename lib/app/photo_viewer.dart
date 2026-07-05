import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme.dart';
import '../models.dart';

/// Opens a check-in photo full screen over Candela Night, with pinch-to-zoom
/// and the same minimal metadata the feed card shows.
void showPhotoViewer(BuildContext context, CheckInEvent event) {
  if (event.photoUrl == null) return;
  HapticFeedback.selectionClick();
  Navigator.push(
    context,
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => _PhotoViewerScreen(event: event),
    ),
  );
}

class _PhotoViewerScreen extends StatelessWidget {
  final CheckInEvent event;
  const _PhotoViewerScreen({required this.event});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: candelaNight,
      body: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: InteractiveViewer(
                maxScale: 4,
                child: Center(
                  child: Hero(
                    tag: 'checkin-photo-${event.checkinId}',
                    child: Image.network(
                      event.photoUrl!,
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => const Icon(
                        Icons.local_fire_department_rounded,
                        size: 48,
                        color: textDarkSecondary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(spacingScreen),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.topRight,
                    child: Material(
                      color: Colors.black.withValues(alpha: 0.4),
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () => Navigator.pop(context),
                        child: const SizedBox(
                          width: 40,
                          height: 40,
                          child: Icon(
                            Icons.close_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  Align(
                    alignment: Alignment.bottomLeft,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '@${event.user.username}',
                          style: textTheme.labelMedium?.copyWith(
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${event.place.name} · ${timeAgo(event.checkedInAt)}',
                          style: textTheme.bodySmall?.copyWith(
                            color: candelaAmber,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
