import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart' as fp;
import 'package:image_cropper/image_cropper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_offline_ai_doc_chat/core/utils/platform_utils.dart';

abstract class DocumentCaptureService {
  Future<File?> captureFromCamera();
  Future<File?> pickFromGallery();
  Future<File?> pickImageFile();
  Future<File?> pickPdf();
  Future<File?> cropImage(File imageFile, BuildContext context);
}

class DocumentCaptureServiceImpl implements DocumentCaptureService {
  final ImagePicker _imagePicker = ImagePicker();

  @override
  Future<File?> captureFromCamera() async {
    final XFile? photo =
        await _imagePicker.pickImage(source: ImageSource.camera);
    if (photo != null) return File(photo.path);
    return null;
  }

  @override
  Future<File?> pickFromGallery() async {
    final XFile? image =
        await _imagePicker.pickImage(source: ImageSource.gallery);
    if (image != null) return File(image.path);
    return null;
  }

  @override
  Future<File?> pickImageFile() async {
    final result = await fp.FilePicker.pickFiles(
      type: fp.FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'webp', 'bmp'],
    );
    if (result != null && result.files.single.path != null) {
      return File(result.files.single.path!);
    }
    return null;
  }

  @override
  Future<File?> pickPdf() async {
    final fp.FilePickerResult? result =
        await fp.FilePicker.pickFiles(
      type: fp.FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result != null && result.files.single.path != null) {
      return File(result.files.single.path!);
    }
    return null;
  }

  @override
  Future<File?> cropImage(File imageFile, BuildContext context) async {
    if (!supportsOcrCapture) return imageFile;

    try {
      final CroppedFile? croppedFile = await ImageCropper().cropImage(
        sourcePath: imageFile.path,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Image',
            toolbarColor: Theme.of(context).colorScheme.primary,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false,
          ),
          IOSUiSettings(title: 'Crop Image'),
          WebUiSettings(context: context),
        ],
      );

      if (croppedFile != null) return File(croppedFile.path);
      return null;
    } catch (_) {
      // If crop fails (e.g. misconfigured native activity), continue with original.
      return imageFile;
    }
  }
}
