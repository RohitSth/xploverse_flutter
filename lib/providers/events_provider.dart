import 'package:flutter_xploverse/models/auth/event.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

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
      lat: 33.7175,
      lon: -116.3899,
      images: [
        "images/ev.jpg",
      ],
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
      lat: 51.1819,
      lon: -2.6738,
      images: [
        "images/ev.jpg",
      ],
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
      lat: -15.7942, // Approximate coordinates for Brazil
      lon: -47.8822,
      images: [
        "images/ev.jpg",
      ],
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
    lat: 48.1372,
    lon: 11.5755,
    images: [
      "images/ev.jpg",
    ],
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
    lat: 48.8566,
    lon: 2.3522,
    images: [
      "images/ev.jpg",
    ],
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
    lat: 25.7617,
    lon: -80.1918,
    images: [
      "images/ev.jpg",
    ],
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
    address: "London, UK",
    lat: 51.5074,
    lon: -0.1278,
    images: [
      "images/ev.jpg",
    ],
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
    lat: -3.0727, // Approximate coordinates for Kilimanjaro
    lon: 37.3583,
    images: [
      "images/ev.jpg",
    ],
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
    lat: 36.1699,
    lon: -115.1398,
    images: [
      "images/ev.jpg",
    ],
    startDate: DateTime(2024, 1, 7),
    endDate: DateTime(2024, 1, 10),
    maxParticipants: 170000,
    ticketsBooked: 100000,
    ticketPrice: 28.99,
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
