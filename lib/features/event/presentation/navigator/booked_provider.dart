import 'package:flutter_xploverse/features/event/presentation/viewmodel/event.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'booked_provider.g.dart';

@riverpod
class BookedNotifier extends _$BookedNotifier {
  // Inintial Value
  @override
  Set<Event> build() {
    return {};
  }

  // Methods to Update the State
  // Add Event
  void addEvent(Event event) {
    // Check if an event with the same ID already exists
    if (!state.any((existingEvent) => existingEvent.id == event.id)) {
      state = {...state, event};
    }
  }

  // Remove Event
  void removeEvent(Event event) {
    state =
        state.where((existingEvent) => existingEvent.id != event.id).toSet();
  }
}

@riverpod
double totalBookedAmount(ref) {
  final bookedEvents = ref.watch(bookedNotifierProvider);

  double total = 0.0;

  for (Event event in bookedEvents) {
    total += event.ticketPrice;
  }

  return total;
}
