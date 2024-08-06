class Event {
  final String id;
  final String organizerId;
  final String title;
  final String description;
  final String address;
  final double lat;
  final double lon;
  final List<dynamic> images;
  final DateTime startDate;
  final DateTime endDate;
  final int maxParticipants;
  final int ticketsBooked;
  final double ticketPrice;

  Event({
    required this.id,
    required this.organizerId,
    required this.title,
    required this.description,
    required this.address,
    required this.lat,
    required this.lon,
    required this.images,
    required this.startDate,
    required this.endDate,
    required this.maxParticipants,
    required this.ticketsBooked,
    required this.ticketPrice,
  });

  // factory Event.fromJson(Map<String, dynamic> json) {
  //   return Event(
  //     id: json['_id'] ?? '',
  //     organizerId: json['organizerId'] ?? '',
  //     title: json['title'] ?? '',
  //     description: json['description'] ?? '',
  //     address: json['address'] ?? '',
  //     lat: json['lat']?.toDouble() ?? 0.0,
  //     lon: json['lon']?.toDouble() ?? 0.0,
  //     images: json['images'] ?? [],
  //     startDate: DateTime.parse(json['startDate']),
  //     endDate: DateTime.parse(json['endDate']),
  //     maxParticipants: json['maxParticipants'] ?? 0,
  //     ticketsBooked: json['ticketsBooked'] ?? 0,
  //     createdAt: DateTime.parse(json['createdAt']),
  //     updatedAt: DateTime.parse(json['updatedAt']),
  //   );
  // }
}
