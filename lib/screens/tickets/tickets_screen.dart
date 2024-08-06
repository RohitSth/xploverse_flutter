import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_xploverse/providers/booked_provider.dart';

class TicketsScreen extends ConsumerStatefulWidget {
  const TicketsScreen({super.key});

  @override
  ConsumerState<TicketsScreen> createState() => _TicketsScreenState();
}

class _TicketsScreenState extends ConsumerState<TicketsScreen> {
  bool showCoupon = true;

  @override
  Widget build(BuildContext context) {
    final bookedEvents = ref.watch(bookedNotifierProvider);

    return Scaffold(
      body: Container(
          padding: const EdgeInsets.all(25),
          child: Column(
            children: bookedEvents.map((event) {
              return Container(
                padding: const EdgeInsets.only(top: 7, bottom: 7),
                child: Row(
                  children: [
                    Image.asset(event.images[0], width: 60, height: 60),
                    const SizedBox(width: 10),
                    Text(
                      event.title.length > 12
                          ? '${event.title.substring(0, 12)}...'
                          : event.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Expanded(child: SizedBox()),
                    Text('Nrs.${event.ticketPrice}')
                  ],
                ),
              );
            }).toList(),
          )),
    );
  }
}
