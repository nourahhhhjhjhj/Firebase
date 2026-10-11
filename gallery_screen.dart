import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// معرض صور يقرأ من Firebase Storage (المجلد images/) ويسمح برفع صور جديدة.
class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  static const _folder = 'images';

  late Future<List<String>> _imagesFuture;
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    _imagesFuture = _loadImages();
  }

  Future<List<String>> _loadImages() async {
    final result = await FirebaseStorage.instance.ref(_folder).listAll();
    return Future.wait(result.items.map((ref) => ref.getDownloadURL()));
  }

  void _refresh() => setState(() => _imagesFuture = _loadImages());

  void _showMessage(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _upload() async {
    final picked = await ImagePicker()
        .pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked == null) return;

    setState(() => _uploading = true);
    try {
      final bytes = await picked.readAsBytes();
      final name = DateTime.now().millisecondsSinceEpoch.toString();
      await FirebaseStorage.instance.ref('$_folder/$name').putData(
            bytes,
            SettableMetadata(contentType: picked.mimeType ?? 'image/jpeg'),
          );
      _showMessage('تم رفع الصورة');
      if (mounted) _refresh();
    } on FirebaseException catch (e) {
      _showMessage('فشل الرفع: ${e.message ?? e.code}');
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('معرض الصور'),
        actions: [
          IconButton(
            tooltip: 'تحديث',
            icon: const Icon(Icons.refresh),
            onPressed: _refresh,
          ),
          IconButton(
            tooltip: 'تسجيل الخروج',
            icon: const Icon(Icons.logout),
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _uploading ? null : _upload,
        tooltip: 'رفع صورة',
        child: _uploading
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.add_photo_alternate),
      ),
      body: FutureBuilder<List<String>>(
        future: _imagesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'تعذر تحميل الصور.\nتأكد من تفعيل Storage وقواعد الوصول في Firebase.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                        onPressed: _refresh, child: const Text('إعادة المحاولة')),
                  ],
                ),
              ),
            );
          }
          final urls = snapshot.data ?? [];
          if (urls.isEmpty) {
            return const Center(
              child: Text('لا توجد صور بعد.\nاضغط الزر لرفع أول صورة.',
                  textAlign: TextAlign.center),
            );
          }
          return GridView.builder(
            padding: const EdgeInsets.all(8),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 200,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
            ),
            itemCount: urls.length,
            itemBuilder: (context, i) => ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                urls[i],
                fit: BoxFit.cover,
                loadingBuilder: (context, child, progress) => progress == null
                    ? child
                    : const Center(child: CircularProgressIndicator()),
                errorBuilder: (context, error, stack) =>
                    const Center(child: Icon(Icons.broken_image)),
              ),
            ),
          );
        },
      ),
    );
  }
}
