import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:mind_deck/core/extensions/string_extension.dart';
import 'package:mind_deck/core/failures.dart';
import 'package:permission_handler/permission_handler.dart';

class MediaService {
  final ImagePicker _picker;
  MediaService({required ImagePicker picker}) : _picker = picker;
  Future<bool> requestCameraPermission() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  Future<bool> requestGalleryPermission() async {
    var status = await Permission.photos.request();
    if (status.isDenied && Platform.isAndroid) {
      status = await Permission.storage.request();
    }
    return status.isGranted || status.isLimited;
  }

  Future<File?> pickImage() async {
    final hasPermission = await requestGalleryPermission();
    if (!hasPermission) {
      throw PermissionFailure(message: 'permission_gallery_denied'.tr);
    }
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
      return image != null ? File(image.path) : null;
    } catch (e) {
      throw UnknownFailure(message: '${'error_pick_image'.tr} $e');
    }
  }

  Future<List<File>> pickMultipleImages() async {
    final hasPermission = await requestGalleryPermission();
    if (!hasPermission) {
      throw PermissionFailure(message: 'permission_gallery_denied'.tr);
    }
    try {
      final List<XFile> images = await _picker.pickMultiImage(imageQuality: 80);
      if (images.isEmpty) return [];
      return images.map((xFile) => File(xFile.path)).toList();
    } catch (e) {
      throw UnknownFailure(message: '${'error_pick_images'.tr} $e');
    }
  }

  Future<File?> takePhoto() async {
    final hasPermission = await requestCameraPermission();
    if (!hasPermission) {
      throw PermissionFailure(message: 'permission_camera_denied'.tr);
    }
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.camera, imageQuality: 80);
      return image != null ? File(image.path) : null;
    } catch (e) {
      throw UnknownFailure(message: '${'error_take_photo'.tr} $e');
    }
  }

  Future<String> fileToBase64(File file) async {
    try {
      final bytes = await file.readAsBytes();
      final base64String = base64Encode(bytes);
      return base64String;
    } catch (e) {
      throw UnknownFailure(message: '${"error_encoding_image".tr} $e');
    }
  }
}
