import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:invoicemaker/models/business_model.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BusinessProvider extends ChangeNotifier {
  // Temp image path used while editing a business logo before saving
  String? imagePath;

  List<BusinessModel> businesses = [];
  BusinessModel? activeBusiness;

  // Legacy compat — callers that still reference saveBusinessModel get active business
  BusinessModel? get saveBusinessModel => activeBusiness;

  BusinessModel? get defaultBusiness {
    if (businesses.isEmpty) return null;
    return businesses.firstWhere(
      (b) => b.isDefault,
      orElse: () => businesses.first,
    );
  }

  BusinessProvider() {
    _init();
  }

  Future<void> _init() async {
    await _migrateIfNeeded();
    await _loadBusinesses();
  }

  // One-time migration: old single-business key → new businesses list
  Future<void> _migrateIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    final oldData = prefs.getString('business');
    final newData = prefs.getString('businesses');

    if (oldData != null && newData == null) {
      final old = jsonDecode(oldData) as Map<String, dynamic>;
      final migrated = BusinessModel(
        id: 'legacy',
        businessName: old['businessName'] as String?,
        businessLogo: old['businessLogo'] as String?,
        isDefault: true,
      );
      await prefs.setString('businesses', jsonEncode([migrated.toJson()]));
      await prefs.setString('active_business_id', 'legacy');
      await prefs.remove('business');
    }
  }

  Future<void> _loadBusinesses() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('businesses');

    if (data != null) {
      final list = jsonDecode(data) as List<dynamic>;
      businesses = list
          .map((e) => BusinessModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    if (businesses.isNotEmpty) {
      final activeId = prefs.getString('active_business_id');
      if (activeId != null) {
        activeBusiness = businesses.firstWhere(
          (b) => b.id == activeId,
          orElse: () => businesses.first,
        );
      } else {
        activeBusiness = businesses.firstWhere(
          (b) => b.isDefault,
          orElse: () => businesses.first,
        );
      }
      imagePath = activeBusiness?.businessLogo;
    }

    notifyListeners();
  }

  Future<void> _saveBusinesses() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'businesses',
      jsonEncode(businesses.map((b) => b.toJson()).toList()),
    );
  }

  Future<void> setActiveBusiness(BusinessModel b) async {
    activeBusiness = b;
    imagePath = b.businessLogo;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('active_business_id', b.id);
    notifyListeners();
  }

  Future<void> setDefaultBusiness(String id) async {
    for (final b in businesses) {
      b.isDefault = b.id == id;
    }
    await _saveBusinesses();
    notifyListeners();
  }

  Future<void> addBusiness(String name, {String? id, String? logoPath}) async {
    final newBusiness = BusinessModel(
      id: id,
      businessName: name,
      isDefault: businesses.isEmpty,
      businessLogo: logoPath,
    );
    businesses.add(newBusiness);
    await _saveBusinesses();
    await setActiveBusiness(newBusiness);
  }

  Future<void> updateBusiness(String id, String? name, String? logoPath) async {
    final b = businesses.firstWhere((e) => e.id == id);
    b.businessName = name;
    b.businessLogo = (logoPath?.isNotEmpty ?? false) ? logoPath : null;
    if (activeBusiness?.id == id) {
      activeBusiness = b;
      imagePath = b.businessLogo;
    }
    await _saveBusinesses();
    notifyListeners();
  }

  Future<void> deleteBusiness(String id) async {
    businesses.removeWhere((b) => b.id == id);
    if (activeBusiness?.id == id) {
      activeBusiness = businesses.isNotEmpty ? businesses.first : null;
    }
    // Ensure at least one default
    if (businesses.isNotEmpty && !businesses.any((b) => b.isDefault)) {
      businesses.first.isDefault = true;
    }
    await _saveBusinesses();
    notifyListeners();
  }

  Future<String?> imagePickFunction({String? businessId}) async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
    );
    if (picked == null) return null;

    final cropped = await ImageCropper().cropImage(
      sourcePath: picked.path,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop Business Logo',
          toolbarColor: const Color(0xFF0D7377),
          toolbarWidgetColor: Colors.white,
          activeControlsWidgetColor: const Color(0xFF0D7377),
          backgroundColor: Colors.white,
          initAspectRatio: CropAspectRatioPreset.square,
          lockAspectRatio: false,
          showCropGrid: true,
          hideBottomControls: false,
          aspectRatioPresets: [
            CropAspectRatioPreset.square,
            CropAspectRatioPreset.ratio4x3,
            CropAspectRatioPreset.ratio16x9,
            CropAspectRatioPreset.original,
          ],
        ),
        IOSUiSettings(
          title: 'Crop Business Logo',
          cancelButtonTitle: 'Cancel',
          doneButtonTitle: 'Done',
          aspectRatioPresets: [
            CropAspectRatioPreset.square,
            CropAspectRatioPreset.ratio4x3,
            CropAspectRatioPreset.ratio16x9,
            CropAspectRatioPreset.original,
          ],
        ),
      ],
    );

    if (cropped == null) return null;

    final docsDir = await getApplicationDocumentsDirectory();
    final bid = businessId ?? activeBusiness?.id ?? 'default';
    final logoDir = Directory('${docsDir.path}/invoicemaker/$bid');
    if (!await logoDir.exists()) {
      await logoDir.create(recursive: true);
    }

    final savedPath = '${logoDir.path}/logo.jpg';
    await File(cropped.path).copy(savedPath);

    imagePath = savedPath;
    notifyListeners();
    return savedPath;
  }

  // ── Legacy methods kept for backward compat ──────────────────────────────

  Future<void> addBusinessData(BusinessModel ourBusiness) async {
    await addBusiness(ourBusiness.businessName ?? '');
  }

  Future<BusinessModel?> getString() async {
    if (activeBusiness != null) return activeBusiness;
    await _loadBusinesses();
    return activeBusiness;
  }

  Future<void> getSaveBusinessModel() async {
    await _loadBusinesses();
  }

  Future<void> updateBusinessData(String? name) async {
    if (activeBusiness == null) return;
    await updateBusiness(activeBusiness!.id, name, imagePath);
  }
}
