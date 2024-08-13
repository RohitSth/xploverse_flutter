import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_xploverse/features/event/data/model/event.dart';
import 'package:latlong2/latlong.dart';

part 'events_provider.g.dart';

List<Event> allEvents = [
  // Music Festivals
  Event(
      id: '1',
      organizerId: 'of76dLxFp0T3FdDWdJOBNkRZdQo1',
      title: "Coachella Valley Music and Arts Festival",
      description:
          "Known for its diverse lineup of music, art installations, and desert vibes.",
      address: "Indio, CA, USA",
      latitude: 33.720577,
      longitude: -116.215561,
      images: [
        "images/ev.jpg",
      ],
      categories: ["Music"],
      startDate: DateTime(2024, 4, 12),
      endDate: DateTime(2024, 4, 19),
      maxParticipants: 125000,
      ticketsBooked: 50000,
      ticketPrice: 241.99),
  Event(
      id: '2',
      organizerId: 'of76dLxFp0T3FdDWdJOBNkRZdQo1',
      title: "Glastonbury Festival",
      description:
          "A legendary festival with a mix of music, arts, and performance, featuring iconic headliners.",
      address: "Pilton, UK",
      latitude: 51.166729,
      longitude: -2.590650,
      images: [
        "images/ev.jpg",
      ],
      categories: ["Music", "Festival"],
      startDate: DateTime(2024, 6, 26),
      endDate: DateTime(2024, 6, 30),
      maxParticipants: 200000,
      ticketsBooked: 100000,
      ticketPrice: 21.99),
  // Cultural Events
  Event(
      id: '3',
      organizerId: 'of76dLxFp0T3FdDWdJOBNkRZdQo1',
      title: "Carnaval",
      description:
          "A vibrant and colorful celebration with parades, music, and dancing.",
      address: "Various locations in Brazil",
      latitude: -14.235004, // Approximate coordinates for Brazil
      longitude: -51.925282,
      images: [
        "images/ev.jpg",
      ],
      categories: ["Music", "Festival"],
      startDate: DateTime(2024, 2, 16), // Example date
      endDate: DateTime(2024, 2, 25), // Example date
      maxParticipants: 1000000, // Example
      ticketsBooked: 500000, // Example
      ticketPrice: 21.99),
  Event(
    id: '4',
    organizerId: 'el5Ly9yBiCUfmnEiDWnOJjJG64v1',
    title: "Oktoberfest",
    description:
        "A traditional beer festival with food, music, and amusement rides.",
    address: "Munich, Germany",
    latitude: 48.135124,
    longitude: 11.581981,
    images: [
      "images/ev.jpg",
    ],
    categories: ["Music", "Food", "Festival"],
    startDate: DateTime(2024, 9, 20),
    endDate: DateTime(2024, 10, 6),
    maxParticipants: 6000000, // Example
    ticketsBooked: 3000000, // Example
    ticketPrice: 28.99,
  ),
  // Sporting Events
  Event(
    id: '5',
    organizerId: 'el5Ly9yBiCUfmnEiDWnOJjJG64v1',
    title: "The Olympics",
    description:
        "A global event featuring athletic competitions in various sports.",
    address: "Paris, France",
    latitude: 48.856613,
    longitude: 2.352222,
    images: [
      "images/ev.jpg",
    ],
    categories: ["Games", "Competitive"],
    startDate: DateTime(2024, 7, 26),
    endDate: DateTime(2024, 8, 11),
    maxParticipants: 10000, // Example for athletes
    ticketsBooked: 1000000, // Example for spectators
    ticketPrice: 28.99,
  ),
  // Art and Design Events
  Event(
    id: '6',
    organizerId: 'YThTSRn5DQOFQLaTQ0KT8QUMSiu1',
    title: "Art Basel Miami Beach",
    description:
        "A major international art fair featuring contemporary and modern art.",
    address: "Miami Beach, FL, USA",
    latitude: 40.761147,
    longitude: -73.985741,
    images: [
      "images/ev.jpg",
    ],
    categories: ["Music", "Outdoors"],
    startDate: DateTime(2024, 12, 4),
    endDate: DateTime(2024, 12, 8),
    maxParticipants: 50000,
    ticketsBooked: 20000,
    ticketPrice: 11.99,
  ),
  // Culinary Events
  Event(
    id: '7',
    organizerId: 'el5Ly9yBiCUfmnEiDWnOJjJG64v1',
    title: "Taste of London",
    description:
        "A food festival showcasing the best of London's restaurants and food stalls.",
    address: "NY, USA",
    latitude: 40.764412,
    longitude: -73.983818,
    images: [
      "images/ev.jpg",
    ],
    categories: ["Music", "Food"],
    startDate: DateTime(2024, 5, 16),
    endDate: DateTime(2024, 5, 19),
    maxParticipants: 50000,
    ticketsBooked: 20000,
    ticketPrice: 2.99,
  ),
  // Nature and Adventure Events
  Event(
    id: '8',
    organizerId: 'YThTSRn5DQOFQLaTQ0KT8QUMSiu1',
    title: "Kilimanjaro Climb",
    description:
        "A challenging but rewarding trek to the summit of Africa's highest mountain.",
    address: "Tanzania",
    latitude: -6.369028, // Approximate coordinates for Kilimanjaro
    longitude: 34.888821,
    images: [
      "images/ev.jpg",
    ],
    categories: ["Adventure", "Rock Climbing"],
    startDate: DateTime(2024, 10, 1), // Example date
    endDate: DateTime(2024, 10, 10), // Example date
    maxParticipants: 100,
    ticketsBooked: 50,
    ticketPrice: 8.99,
  ),
  // Business and Technology Events
  Event(
    id: '9',
    organizerId: 'YThTSRn5DQOFQLaTQ0KT8QUMSiu1',
    title: "CES",
    description:
        "The world's largest consumer electronics show, showcasing the latest technology and gadgets.",
    address: "Las Vegas, NV, USA",
    latitude: 36.169090,
    longitude: -115.140579,
    images: [
      "images/ev.jpg",
    ],
    categories: ["Electronics", "IT", "Festival"],
    startDate: DateTime(2024, 1, 7),
    endDate: DateTime(2024, 1, 10),
    maxParticipants: 170000,
    ticketsBooked: 100000,
    ticketPrice: 28.99,
  ),
  Event(
    id: '10',
    organizerId: 'el5Ly9yBiCUfmnEiDWnOJjJG64v1',
    title: "OKAY",
    description: "The world's largest consumer",
    address: "Srilanka",
    latitude: 7.873054,
    longitude: 80.771797,
    images: [
      "images/ev.jpg",
    ],
    categories: ["Music", "Food", "Festival"],
    startDate: DateTime(2024, 7, 7),
    endDate: DateTime(2024, 7, 10),
    maxParticipants: 170,
    ticketsBooked: 1000,
    ticketPrice: 6.99,
  ),
  Event(
    id: '11',
    organizerId: 'YThTSRn5DQOFQLaTQ0KT8QUMSiu1',
    title: "Helloo",
    description: "owcasing the latest technology and gadgets.",
    address: "Bhutan",
    latitude: 27.514162,
    longitude: 90.433601,
    images: [
      "images/ev.jpg",
    ],
    categories: ["Music", "Food"],
    startDate: DateTime(2024, 9, 7),
    endDate: DateTime(2024, 9, 10),
    maxParticipants: 170,
    ticketsBooked: 100,
    ticketPrice: 0.99,
  ),
  Event(
    id: '12',
    organizerId: 'el5Ly9yBiCUfmnEiDWnOJjJG64v1',
    title: "Nice",
    description: "Ice",
    address: "Las",
    latitude: 28.394857,
    longitude: 84.124008,
    images: [
      "images/ev.jpg",
    ],
    categories: ["Electronics", "IT", "Festival"],
    startDate: DateTime(2024, 2, 7),
    endDate: DateTime(2024, 2, 20),
    maxParticipants: 1000,
    ticketsBooked: 100,
    ticketPrice: 99.99,
  ),
];

// Generated providers
@riverpod
List<Event> events(ref) {
  return allEvents;
}

@riverpod
List<Event> reducedEvents(ref) {
  return allEvents.where((e) => e.ticketPrice < 50).toList();
}

@riverpod
List<LatLng> eventLatLngs(EventLatLngsRef ref) {
  final events = ref.watch(eventsProvider);
  return events
      .map((event) => LatLng(event.latitude, event.longitude))
      .toList();
}