class UserDetailsModel {
  final String name;
  final String email;
  final String phone;
  final String address;
  final String lastLocation;
  final String requiredNeeds;
  final String speciality;
  final List<Map<String, String>> emergencyContacts;
  final String createdAt;
  final String lastLocationUpdatedAt;

  UserDetailsModel({
    required this.name,
    required this.email,
    required this.phone,
    required this.address,
    required this.lastLocation,
    required this.requiredNeeds,
    required this.speciality,
    required this.emergencyContacts,
    required this.createdAt,
    required this.lastLocationUpdatedAt,
  });
}


//  id = Column(Integer, primary_key=True)
//     username = Column(String, unique=True, nullable=False)
//     password = Column(String, nullable=False)
//     contact = Column(String, nullable=False)
//     name = Column(String, nullable=False)
//     last_location = Column(String, nullable=True)
//     required_needs = Column(String, nullable=True)
//     speciality = Column(String, nullable=True)
//     address = Column(String, nullable=True)
//     # [{"name" : "", "contact" :""}]
//     emergency_contacts = Column(JSON, nullable=True)  # List of emergency contacts
//     created_at = Column(DateTime, default=datetime.utcnow)
//     last_location_updated_at = Column(DateTime, default=datetime.utcnow)