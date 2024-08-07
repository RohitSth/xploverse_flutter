import 'package:cloud_firestore/cloud_firestore.dart';

// Defining properties
class Event {
  final String id;
  final String organizerId;
  final String title;
  final String description;
  final String address;
  final double latitude;
  final double longitude;
  final List<String> images;
  final List<String> categories;
  final DateTime startDate;
  final DateTime endDate;
  final int maxParticipants;
  final int ticketsBooked;
  final double ticketPrice;

// Constructors
  Event({
    required this.id,
    required this.organizerId,
    required this.title,
    required this.description,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.images,
    required this.categories,
    required this.startDate,
    required this.endDate,
    required this.maxParticipants,
    required this.ticketsBooked,
    required this.ticketPrice,
  });

  // Convert Event object to a map ToJSON
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'organizerId': organizerId,
      'title': title,
      'description': description,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'images': images,
      'categories': categories,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'maxParticipants': maxParticipants,
      'ticketsBooked': ticketsBooked,
      'ticketPrice': ticketPrice,
    };
  }

  // Create an Event object from a map (Firestore document) FromJSON
  factory Event.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return Event(
      id: doc.id,
      organizerId: data['organizerId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      address: data['address'] ?? '',
      latitude: (data['latitude'] ?? 0).toDouble(),
      longitude: (data['longitude'] ?? 0).toDouble(),
      images: List<String>.from(data['images'] ?? []),
      categories: List<String>.from(data['categories'] ?? []),
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: (data['endDate'] as Timestamp).toDate(),
      maxParticipants: data['maxParticipants'] ?? 0,
      ticketsBooked: data['ticketsBooked'] ?? 0,
      ticketPrice: (data['ticketPrice'] ?? 0).toDouble(),
    );
  }

  static fromDocument(QueryDocumentSnapshot<Map<String, dynamic>> doc) {}
}
