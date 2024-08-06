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
}
