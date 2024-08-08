import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_xploverse/features/event/presentation/navigator/booked_provider.dart';
import 'package:flutter_xploverse/features/event/presentation/navigator/events_provider.dart';
import 'package:intl/intl.dart';

class EventsScreen extends ConsumerWidget {
  const EventsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allEvents = ref.watch(eventsProvider);
    final bookedEvents = ref.watch(bookedNotifierProvider);

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : Colors.black;

    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.only(
                  left: 16, top: 16, right: 16, bottom: 100),
              itemCount: allEvents.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.70,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemBuilder: (context, index) {
                final event = allEvents[index];
                return Card(
                  clipBehavior: Clip.antiAlias,
                  color: isDarkMode ? Colors.grey[800] : Colors.white,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AspectRatio(
                        aspectRatio: 16 / 9,
                        child: Image.asset(
                          event.images[0],
                          fit: BoxFit.cover,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              event.title,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(color: textColor),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 1),
                            Text(
                              event.description,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: textColor.withOpacity(0.8)),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 1),
                            Text(
                              _formatDateTime(event.startDate),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: textColor.withOpacity(0.8)),
                            ),
                            Text(
                              'Nrs. ${event.ticketPrice}',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: textColor,
                                  ),
                            ),
                            // Single button with conditional text based on event ID
                            TextButton(
                              onPressed: () {
                                if (bookedEvents.any((bookedEvent) =>
                                    bookedEvent.id == event.id)) {
                                  ref
                                      .read(bookedNotifierProvider.notifier)
                                      .removeEvent(event);
                                } else {
                                  ref
                                      .read(bookedNotifierProvider.notifier)
                                      .addEvent(event);
                                }
                              },
                              style: TextButton.styleFrom(
                                foregroundColor: bookedEvents.any(
                                        (bookedEvent) =>
                                            bookedEvent.id == event.id)
                                    ? Colors.red
                                    : Colors.blue,
                              ),
                              child: Text(
                                bookedEvents.any((bookedEvent) =>
                                        bookedEvent.id == event.id)
                                    ? 'Remove'
                                    : 'Book',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return DateFormat('MMM d, h:mm a').format(dateTime);
  }
}
