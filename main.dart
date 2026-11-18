import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
    runApp(const SetupRequiredApp());
    return;
  }
  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
  runApp(const ShankaraApp());
}

class SetupRequiredApp extends StatelessWidget {
  const SetupRequiredApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: appTheme(),
    home: const Scaffold(
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(28),
          child: Text(
            'SHANKARA HEALING MUSIC\n\nKonfigurasi Supabase belum diisi.\nIkuti README.md untuk menyiapkan URL dan anon key.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    ),
  );
}

ThemeData appTheme() => ThemeData(
  brightness: Brightness.dark,
  scaffoldBackgroundColor: const Color(0xFF11100E),
  colorScheme: ColorScheme.fromSeed(
    seedColor: const Color(0xFFC9A45C),
    brightness: Brightness.dark,
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFF171511),
    foregroundColor: Color(0xFFE5C77D),
    centerTitle: true,
  ),
  cardTheme: const CardThemeData(
    color: Color(0xFF211E18),
    margin: EdgeInsets.zero,
  ),
);

class ShankaraApp extends StatelessWidget {
  const ShankaraApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'SHANKARA HEALING MUSIC',
    debugShowCheckedModeBanner: false,
    theme: appTheme(),
    home: const HomePage(),
  );
}

final supabase = Supabase.instance.client;

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int tab = 0;
  bool get signedIn => supabase.auth.currentUser != null;

  @override
  Widget build(BuildContext context) {
    final pages = [
      const MusicPage(),
      const GalleryPage(),
      const AccountPage(),
    ];
    return Scaffold(
      appBar: AppBar(
        title: const Text('SHANKARA HEALING MUSIC',
          style: TextStyle(fontSize: 16, letterSpacing: 1.2)),
      ),
      body: pages[tab],
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: (v) => setState(() => tab = v),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.music_note), label: 'Musik'),
          NavigationDestination(icon: Icon(Icons.photo_library), label: 'Galeri'),
          NavigationDestination(icon: Icon(Icons.person), label: 'Akun'),
        ],
      ),
    );
  }
}

class MusicPage extends StatelessWidget {
  const MusicPage({super.key});
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(20),
    children: [
      const SizedBox(height: 18),
      const Icon(Icons.spa, size: 62, color: Color(0xFFE5C77D)),
      const SizedBox(height: 12),
      const Text('Selamat Datang',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 25, color: Color(0xFFE5C77D))),
      const Text('Musik • Seni • Ketenangan',
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.white70)),
      const SizedBox(height: 28),
      Card(child: ListTile(
        leading: const Icon(Icons.headphones, color: Color(0xFFE5C77D)),
        title: const Text('Musik Relaksasi'),
        subtitle: const Text('Ruang untuk menikmati musik pilihan Shankara.'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pemutar musik akan diaktifkan pada tahap berikutnya.')),
        ),
      )),
      const SizedBox(height: 12),
      const Text('Musik dan audio akan ditambahkan setelah file audio original atau berlisensi tersedia.',
        style: TextStyle(color: Colors.white60)),
    ],
  );
}

class GalleryPage extends StatefulWidget {
  const GalleryPage({super.key});
  @override
  State<GalleryPage> createState() => _GalleryPageState();
}

class _GalleryPageState extends State<GalleryPage> {
  late Future<List<Map<String, dynamic>>> futurePhotos;
  bool admin = false;

  @override
  void initState() {
    super.initState();
    futurePhotos = loadPhotos();
    checkAdmin();
  }

  Future<List<Map<String, dynamic>>> loadPhotos() async {
    final rows = await supabase.from('photos')
      .select('id,title,description,price_rupiah,preview_url,is_active')
      .eq('is_active', true)
      .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<void> checkAdmin() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;
    try {
      final row = await supabase.from('profiles')
        .select('role').eq('id', user.id).maybeSingle();
      if (mounted) setState(() => admin = row?['role'] == 'admin');
    } catch (_) {}
  }

  void refresh() => setState(() => futurePhotos = loadPhotos());

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
        child: Row(children: [
          const Expanded(child: Text('GALERI FOTO',
            style: TextStyle(fontSize: 20, color: Color(0xFFE5C77D),
              letterSpacing: 1.3, fontWeight: FontWeight.bold))),
          if (admin) FilledButton.icon(
            onPressed: () async {
              await Navigator.push(context,
                MaterialPageRoute(builder: (_) => const AdminUploadPage()));
              refresh();
            },
            icon: const Icon(Icons.add_photo_alternate),
            label: const Text('Unggah'),
          ),
        ]),
      ),
      Expanded(
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: futurePhotos,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) return Center(
              child: Text('Galeri belum dapat dimuat.\n${snapshot.error}',
                textAlign: TextAlign.center),
            );
            final photos = snapshot.data ?? [];
            if (photos.isEmpty) return const Center(
              child: Text('Belum ada foto.\nKoleksi akan ditambahkan administrator.',
                textAlign: TextAlign.center),
            );
            return GridView.builder(
              padding: const EdgeInsets.all(14),
              itemCount: photos.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12,
                childAspectRatio: .68,
              ),
              itemBuilder: (context, index) {
                final photo = photos[index];
                return InkWell(
                  onTap: () => Navigator.push(context, MaterialPageRoute(
                    builder: (_) => PhotoDetailPage(photo: photo))),
                  child: Card(
                    clipBehavior: Clip.antiAlias,
                    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(child: photo['preview_url'] == null
                          ? const Icon(Icons.image, size: 54)
                          : Image.network(photo['preview_url'],
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                const Icon(Icons.broken_image, size: 48))),
                        Padding(
                          padding: const EdgeInsets.all(9),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${photo['title']}', maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text('Rp ${photo['price_rupiah']}',
                                style: const TextStyle(color: Color(0xFFE5C77D))),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    ],
  );
}

class PhotoDetailPage extends StatelessWidget {
  final Map<String, dynamic> photo;
  const PhotoDetailPage({super.key, required this.photo});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Detail Foto')),
    body: ListView(padding: const EdgeInsets.all(18), children: [
      if (photo['preview_url'] != null)
        ClipRRect(borderRadius: BorderRadius.circular(14),
          child: Image.network(photo['preview_url'], fit: BoxFit.contain)),
      const SizedBox(height: 18),
      Text('${photo['title']}', style: const TextStyle(fontSize: 22,
        color: Color(0xFFE5C77D), fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      Text('${photo['description'] ?? ''}'),
      const SizedBox(height: 18),
      Text('Rp ${photo['price_rupiah']}',
        style: const TextStyle(fontSize: 20, color: Color(0xFFE5C77D))),
      const SizedBox(height: 14),
      FilledButton.icon(
        onPressed: () => showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Pembelian foto'),
            content: const Text('Pembayaran belum diaktifkan. Tahap berikutnya adalah integrasi pembayaran dan verifikasi server sebelum file asli dapat diunduh.'),
            actions: [TextButton(onPressed: () => Navigator.pop(context),
              child: const Text('Mengerti'))],
          ),
        ),
        icon: const Icon(Icons.lock),
        label: const Text('Beli & Unduh — segera hadir'),
      ),
    ]),
  );
}

class AdminUploadPage extends StatefulWidget {
  const AdminUploadPage({super.key});
  @override
  State<AdminUploadPage> createState() => _AdminUploadPageState();
}

class _AdminUploadPageState extends State<AdminUploadPage> {
  final title = TextEditingController();
  final description = TextEditingController();
  final price = TextEditingController(text: '5000');
  XFile? selected;
  bool saving = false;

  Future<void> chooseImage() async {
    final image = await ImagePicker().pickImage(
      source: ImageSource.gallery, imageQuality: 85, maxWidth: 1800);
    if (image != null) setState(() => selected = image);
  }

  Future<void> upload() async {
    if (title.text.trim().isEmpty || selected == null ||
        int.tryParse(price.text) == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Isi judul, pilih foto, dan masukkan harga yang benar.')));
      return;
    }
    setState(() => saving = true);
    try {
      final user = supabase.auth.currentUser;
      if (user == null) throw Exception('Silakan masuk terlebih dahulu.');
      final role = await supabase.from('profiles').select('role')
        .eq('id', user.id).maybeSingle();
      if (role?['role'] != 'admin') {
        throw Exception('Akun ini bukan administrator.');
      }
      final bytes = await selected!.readAsBytes();
      final ext = selected!.name.split('.').last.toLowerCase();
      final path = '${DateTime.now().millisecondsSinceEpoch}.$ext';
      await supabase.storage.from('photo-previews').uploadBinary(
        path, bytes, fileOptions: const FileOptions(upsert: false));
      final previewUrl = supabase.storage.from('photo-previews').getPublicUrl(path);
      await supabase.from('photos').insert({
        'title': title.text.trim(),
        'description': description.text.trim(),
        'price_rupiah': int.parse(price.text),
        'preview_url': previewUrl,
        'preview_path': path,
        'is_active': true,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Foto berhasil ditambahkan ke galeri.')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengunggah: $e')));
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  void dispose() {
    title.dispose(); description.dispose(); price.dispose(); super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Unggah Foto Admin')),
    body: ListView(padding: const EdgeInsets.all(18), children: [
      TextField(controller: title, decoration: const InputDecoration(
        labelText: 'Judul foto', border: OutlineInputBorder())),
      const SizedBox(height: 12),
      TextField(controller: description, maxLines: 3,
        decoration: const InputDecoration(labelText: 'Deskripsi',
          border: OutlineInputBorder())),
      const SizedBox(height: 12),
      TextField(controller: price, keyboardType: TextInputType.number,
        decoration: const InputDecoration(labelText: 'Harga (rupiah)',
          border: OutlineInputBorder())),
      const SizedBox(height: 14),
      OutlinedButton.icon(onPressed: chooseImage,
        icon: const Icon(Icons.image), label: const Text('Pilih foto dari HP')),
      if (selected != null) Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Image.file(File(selected!.path), height: 210, fit: BoxFit.contain)),
      const SizedBox(height: 14),
      FilledButton(
        onPressed: saving ? null : upload,
        child: Text(saving ? 'Mengunggah...' : 'Simpan ke Galeri'),
      ),
      const SizedBox(height: 10),
      const Text('Akses unggah diperiksa dari peran admin di database. Aturan keamanan database tetap wajib dipasang.',
        style: TextStyle(color: Colors.white60, fontSize: 12)),
    ]),
  );
}

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});
  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  final email = TextEditingController();
  final password = TextEditingController();
  bool busy = false;

  Future<void> auth({required bool register}) async {
    setState(() => busy = true);
    try {
      if (register) {
        await supabase.auth.signUp(email: email.text.trim(), password: password.text);
      } else {
        await supabase.auth.signInWithPassword(
          email: email.text.trim(), password: password.text);
      }
      if (mounted) setState(() {});
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Permintaan akun berhasil diproses.')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal: $e')));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  void dispose() { email.dispose(); password.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final user = supabase.auth.currentUser;
    if (user != null) return Center(child: Column(
      mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.account_circle, size: 64, color: Color(0xFFE5C77D)),
        Text(user.email ?? 'Pengguna'),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: () async { await supabase.auth.signOut(); setState(() {}); },
          child: const Text('Keluar'),
        ),
      ],
    ));
    return ListView(padding: const EdgeInsets.all(22), children: [
      const Text('Akun SHANKARA', style: TextStyle(fontSize: 22,
        color: Color(0xFFE5C77D))),
      const SizedBox(height: 18),
      TextField(controller: email, keyboardType: TextInputType.emailAddress,
        decoration: const InputDecoration(labelText: 'Email',
          border: OutlineInputBorder())),
      const SizedBox(height: 12),
      TextField(controller: password, obscureText: true,
        decoration: const InputDecoration(labelText: 'Kata sandi',
          border: OutlineInputBorder())),
      const SizedBox(height: 14),
      FilledButton(onPressed: busy ? null : () => auth(register: false),
        child: const Text('Masuk')),
      TextButton(onPressed: busy ? null : () => auth(register: true),
        child: const Text('Buat akun baru')),
    ]);
  }
}
