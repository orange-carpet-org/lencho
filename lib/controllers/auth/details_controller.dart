import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart'; // Import Hive package
import 'package:lencho/models/UserDetails.dart';
import 'package:lencho/screens/home/home_page.dart';

class DetailsController extends GetxController {
  static DetailsController get instance => Get.find();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Hive box for session data.
  late Box sessionBox;

  @override
  void onInit() {
    super.onInit();
    initHive();
  }

  Future<void> initHive() async {
    // Open the Hive box for session management.
    sessionBox = await Hive.openBox('sessionBox');
  }

  /// Creates (or updates) a user document in Firestore using the user's UID.
  Future<void> createUser(UserDetails user) async {
    await _db
        .collection("UserDetails")
        .doc(user.uid)
        .set(user.toMap(), SetOptions(merge: true));
  }

  // Controllers for each address detail.
  final TextEditingController streetAddressController = TextEditingController();
  final TextEditingController cityController = TextEditingController();
  final TextEditingController stateController = TextEditingController();
  final TextEditingController postalZipController = TextEditingController();

  /// Submits the user details (address) to Firestore and creates a session.
  Future<void> submitDetails() async {
    final String streetAddress = streetAddressController.text.trim();
    final String city = cityController.text.trim();
    final String state = stateController.text.trim();
    final String postalZip = postalZipController.text.trim();

    // Validate required fields.
    if (streetAddress.isEmpty ||
        city.isEmpty ||
        state.isEmpty ||
        postalZip.isEmpty) {
      Get.snackbar('Error', 'Please fill in all the details.');
      return;
    }

    // Retrieve the current user.
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      Get.snackbar('Error', 'User not logged in.');
      return;
    }

    // Create a UserDetails instance using the input data.
    final userDetails = UserDetails(
      uid: user.uid,
      email: user.email ?? '',
      streetAddress: streetAddress,
      city: city,
      state: state,
      postalZip: postalZip,
      updatedAt: DateTime.now(),
    );

    // Save the details to Firestore.
    try {
      await createUser(userDetails);
      // Create (or update) session details in Hive.
      sessionBox.put('detailsSubmitted', true);
      Get.snackbar('Success', 'Your details have been updated.');
      // Redirect to HomePage after successful submission.
      Get.offAll(() => HomePage());
    } on FirebaseException catch (e) {
      Get.snackbar('Error', e.message ?? 'Failed to update details.');
    } catch (e) {
      Get.snackbar('Error', 'An unexpected error occurred.');
    }
  }

  /// Redirects to HomePage without submitting details, while still creating a session.
  void doThisLater() {
    // Optionally store a flag that indicates the user skipped submitting details.
    sessionBox.put('detailsSubmitted', false);
    Get.offAll(() => HomePage());
  }

  @override
  void onClose() {
    streetAddressController.dispose();
    cityController.dispose();
    stateController.dispose();
    postalZipController.dispose();
    sessionBox.close();
    super.onClose();
  }
}
