import 'package:flutter_xploverse/models/auth/event.dart';
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
