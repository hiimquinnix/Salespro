import 'dart:io';

import 'package:image_picker/image_picker.dart';

class ImagePickerUtil {

  static final _imagePicker = ImagePicker(); 


  static Future<File?> pickImage() async {
    
    var pickedFile = await _imagePicker.pickImage(source: ImageSource.gallery, imageQuality: 25);
    return (pickedFile?.path ?? "").isEmpty ? null : File(pickedFile?.path ?? "");
  }
}
