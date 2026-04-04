class ShowModel {
  final String id;
  final String name;
  final String location;
  final String city;
  final String country;
  final DateTime? startDate;
  final DateTime? endDate;
  final int droneCount;
  final String status;
  final String category;
  final String health;
  final String permitStatus;
  final String productionStatus;
  final String designStatus;
  final String schedulingStatus;
  final String routingStatus;
  final String safetyStatus;
  final String notes;
  final int crewCount;

  const ShowModel({
    required this.id,
    required this.name,
    this.location = '',
    this.city = '',
    this.country = '',
    this.startDate,
    this.endDate,
    this.droneCount = 0,
    required this.status,
    required this.category,
    this.health = 'not_started',
    this.permitStatus = 'not_started',
    this.productionStatus = 'not_started',
    this.designStatus = 'not_started',
    this.schedulingStatus = 'not_started',
    this.routingStatus = 'not_started',
    this.safetyStatus = 'not_started',
    this.notes = '',
    this.crewCount = 0,
  });

  factory ShowModel.fromJson(Map<String, dynamic> json) => ShowModel(
        id: json['id'] as String,
        name: json['name'] as String,
        location: json['location'] as String? ?? '',
        city: json['city'] as String? ?? '',
        country: json['country'] as String? ?? '',
        startDate: json['start_date'] != null
            ? DateTime.tryParse(json['start_date'] as String)
            : null,
        endDate: json['end_date'] != null
            ? DateTime.tryParse(json['end_date'] as String)
            : null,
        droneCount: json['drone_count'] as int? ?? 0,
        status: json['status'] as String? ?? 'proposed',
        category: json['category'] as String? ?? 'OTHER',
        health: json['health'] as String? ?? 'not_started',
        permitStatus: json['permit_status'] as String? ?? 'not_started',
        productionStatus: json['production_status'] as String? ?? 'not_started',
        designStatus: json['design_status'] as String? ?? 'not_started',
        schedulingStatus: json['scheduling_status'] as String? ?? 'not_started',
        routingStatus: json['routing_status'] as String? ?? 'not_started',
        safetyStatus: json['safety_status'] as String? ?? 'not_started',
        notes: json['notes'] as String? ?? '',
        crewCount: json['crew_count'] as int? ?? 0,
      );
}
