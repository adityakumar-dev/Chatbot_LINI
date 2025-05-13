import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:resq.ai/providers/direction_provider.dart';
import 'package:resq.ai/providers/geolocator_handler.dart';
import 'package:resq.ai/widgets/common/alert_dailog.dart';
import 'dart:convert';
import '../../../models/user_details_model.dart';

class UserInfoScreen extends StatefulWidget {
  final int userId;
  const UserInfoScreen({super.key, required this.userId});

  @override
  State<UserInfoScreen> createState() => _UserInfoScreenState();
}

class _UserInfoScreenState extends State<UserInfoScreen> {
  UserDetailsModel? userDetails;
  bool isLoading = true;
  String? error;
  LatLng? userLocation;
  LatLng? adminPosition;
  bool isAdminPositionLoading = true;
  bool isRouteLoading = false;
  
  List<LatLng>? routeCoordinates;
  @override
  void initState() {
    super.initState();
    fetchUserDetails();
    fetchAdminPosition();
  }

  Future<void> fetchAdminPosition() async {
    try {
      Position position = await GeolocatorHandler.getCurrentLocation(context);
      setState(() {
        adminPosition = LatLng(position.latitude, position.longitude);
        isAdminPositionLoading = false;
      });
      if (userLocation != null) {
        fetchRouteCoordinates();
      }
    } catch(e) {
      kAlertDialog(
        context: context,
        title: 'Location Error',
        message: "Failed to find your location\n Error : ${e.toString()}",
        buttonText: "Okay",
        onPressed: () {
          Navigator.pop(context);
        }
      );
      print(e);
    }
  }

  Future<void> fetchUserDetails() async {
    try {
      final response = await http.get(
        Uri.parse('https://enabled-flowing-bedbug.ngrok-free.app/api/user/emergency/details/${widget.userId}'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          userDetails = UserDetailsModel(
            name: data['name'] ?? 'Unknown User',
            email: data['username'] ?? 'No email provided',
            phone: data['contact'] ?? 'No contact available',
            address: data['address'] ?? 'Address not provided',
            lastLocation: data['last_location'] ?? 'Location not available',
            requiredNeeds: data['required_needs'] ?? 'No specific needs',
            speciality: data['speciality'] ?? 'Not specified',
            emergencyContacts: (data['emergency_contacts']  as List).map((e) => {
            'name': e['name'].toString() ?? 'Unknown',
            'contact': e['phone'].toString() ?? 'No contact',
          }).toList() ?? [  ],

            createdAt: data['created_at'] ?? 'Unknown',
            lastLocationUpdatedAt: data['last_location_updated_at'] ?? 'Unknown',
          );
          
          if (data['last_location'] != null) {
            final locationParts = data['last_location'].split(',');
            if (locationParts.length == 2) {
              userLocation = LatLng(
                double.parse(locationParts[0]),
                double.parse(locationParts[1]),
              );
              if (adminPosition != null) {
                fetchRouteCoordinates();
              }
            }
          }
          isLoading = false;
        });
      } else {
        setState(() {
          error = 'Failed to load user details';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        error = 'Error: $e';
        isLoading = false;
      });
    }
  }

  Future<void> fetchRouteCoordinates() async {
    if (userLocation == null || adminPosition == null) {
      print('Cannot fetch route: locations not available');
      return;
    }

    try {
      setState(() {
        isRouteLoading = true;
      });
      
      routeCoordinates = await fetchRouteFromORS(userLocation!, adminPosition!);
      
      setState(() {
        isRouteLoading = false;
      });
    } catch(e) {
      setState(() {
        isRouteLoading = false;
      });
      kAlertDialog(
        context: context,
        title: 'Route Error',
        message: "Failed to fetch route\n Error : ${e.toString()}",
        buttonText: "Okay",
        onPressed: () {
          Navigator.pop(context);
        }
      );
      print(e);
    }
  }

  Widget _buildInfoCard(String title, String value, {IconData? icon}) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 16),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: value.toLowerCase().contains('not') || 
                             value.toLowerCase().contains('no') || 
                             value.toLowerCase().contains('unknown')
                          ? Colors.grey
                          : Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmergencyContacts() {
    if (userDetails!.emergencyContacts.isEmpty) {
      return Card(
        elevation: 2,
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(Icons.contact_emergency, size: 48, color: Colors.grey),
              SizedBox(height: 8),
              Text(
                'No Emergency Contacts',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.emergency, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Emergency Contacts',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...userDetails!.emergencyContacts.map((contact) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Theme.of(context).colorScheme.surfaceVariant,
                ),
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    const CircleAvatar(
                      child: Icon(Icons.person),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            contact['name'] ?? 'Unknown',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            contact['contact'] ?? 'No contact',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.phone),
                      onPressed: () {
                        FlutterPhoneDirectCaller.callNumber(contact['contact'] ?? 'No contact');
                        // Implement phone call functionality
                      },
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ],
                ),
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildMap() {
    if (userLocation == null) {
      return Card(
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(Icons.location_off, size: 48, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'Location not available',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'User has not shared their location',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        height: 300,
        child: Stack(
          children: [
            FlutterMap(
              options: MapOptions(
                center: userLocation,
                zoom: 13.0,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.app',
                ),
                if (routeCoordinates != null)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: routeCoordinates!,
                        strokeWidth: 4.0,
                        color: Colors.green,
                      ),
                    ],
                  ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: userLocation!,
                      width: 100,
                      height: 80,
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(6),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              userDetails!.name.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.black,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Icon(
                            Icons.location_on,
                            color: Colors.red,
                            size: 32,
                          ),
                        ],
                      ),
                    ),
                    if (adminPosition != null)
                      Marker(
                        point: adminPosition!,
                        width: 100,
                        height: 80,
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(6),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 4,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Text(
                                "You",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Icon(
                              Icons.location_on,
                              color: Colors.blue,
                              size: 32,
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
            if (isRouteLoading)
              const Positioned.fill(
                child: Center(
                  child: Card(
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Calculating route...',
                            style: TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Details'),
        elevation: 2,
      ),
      body: isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading user details...'),
                ],
              ),
            )
          : error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(
                        error!,
                        style: const TextStyle(color: Colors.red),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            isLoading = true;
                            error = null;
                          });
                          fetchUserDetails();
                          fetchAdminPosition();
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : Stack(
                  children: [
                    RefreshIndicator(
                      onRefresh: () async {
                        await Future.wait([
                          fetchUserDetails(),
                          fetchAdminPosition(),
                        ]);
                      },
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 24),
                            Center(
                              child: CircleAvatar(
                                radius: 50,
                                backgroundColor: Theme.of(context).colorScheme.primary,
                                child: Text(
                                  userDetails!.name[0].toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 36,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Center(
                              child: Text(
                                userDetails!.name,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            _buildInfoCard('Email', userDetails!.email, icon: Icons.email),
                            _buildInfoCard('Phone', userDetails!.phone, icon: Icons.phone),
                            _buildInfoCard('Address', userDetails!.address, icon: Icons.home),
                            _buildInfoCard('Speciality', userDetails!.speciality, icon: Icons.work),
                            _buildInfoCard('Required Needs', userDetails!.requiredNeeds, icon: Icons.medical_services),
                            _buildEmergencyContacts(),
                            SizedBox(height: 10,),
                            Column(
                              children: [
                               const Row(
                                children: [
                                 SizedBox(width: 24,),
                                  Text('Quick Map with Directions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),),
                                ],
                               ),
                               Row(
                                // mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                
                                Row(children: [
                                  SizedBox(width: 24,),
                                  Icon(Icons.location_on, color: Theme.of(context).colorScheme.primary,),
                                SizedBox(width: 2,),
                                Text('${userDetails!.name}', style: TextStyle(fontSize: 12, ),),
                                ],),
Spacer(),
                                Row(children: [
                                  SizedBox(width: 24,),
                                  Icon(Icons.location_on, color: Theme.of(context).colorScheme.secondary,),
                                SizedBox(width: 2,),
                                Text('You', style: TextStyle(fontSize: 12, ),),
                                ],),
                                SizedBox(width: 24,),
                             
                               ],),
                               
                                _buildMap(),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Row(
                                children: [
                                  const Icon(Icons.update, size: 16, color: Colors.grey),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      '${userDetails!.name} last updated at ${userDetails!.lastLocationUpdatedAt}',
                                      style: const TextStyle(
                                        color: Colors.grey,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                    if (isAdminPositionLoading)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Loading your location...',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Theme.of(context).colorScheme.secondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
    );
  }
}