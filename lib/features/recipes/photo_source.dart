import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Where a user's own recipe photo comes from (replaced by a fake in tests).
abstract class PhotoSource {
  /// Lets the user take or choose a photo and returns the path of a copy that lives in the
  /// app's own storage, or null if they cancelled.
  Future<String?> pick({required bool camera});
}

class ImagePickerPhotoSource implements PhotoSource {
  final ImagePicker _picker = ImagePicker();

  @override
  Future<String?> pick({required bool camera}) async {
    final file = await _picker.pickImage(
      source: camera ? ImageSource.camera : ImageSource.gallery,
      maxWidth: 1280,
      imageQuality: 82,
    );
    if (file == null) return null;
    final dir = Directory(
      p.join((await getApplicationDocumentsDirectory()).path, 'user_photos'),
    );
    await dir.create(recursive: true);
    final dest = p.join(
      dir.path,
      '${DateTime.now().microsecondsSinceEpoch}.jpg',
    );
    await File(file.path).copy(dest);
    return dest;
  }
}
