HYDRAE CORRECTED SOURCE - SAFE VIVA BRANCH

Source ini sengaja diletakkan dalam folder source/ supaya fail website yang
sedang deploy di root repository tidak disentuh.

Untuk ujian manual, jalankan arahan berikut dari folder source/:

   flutter pub get
   dart format lib/main.dart
   flutter analyze
   flutter build web --release

Fail utama yang dibetulkan:
- lib/main.dart
- pubspec.yaml

Pengesahan matematik:
- Senario 1: 20.7% (Stable), R1=0.85, R13=0.15
- Senario 2: 38.3% (Stable), R1=0.30, R3=0.30, R32=0.70
- Senario 3: 88.2% (Critical), R19=0.40, R31=0.80

Nota: Flutter SDK tidak tersedia dalam persekitaran penyediaan fail ini, jadi
empat arahan di atas masih perlu dijalankan pada komputer atau CI projek.
