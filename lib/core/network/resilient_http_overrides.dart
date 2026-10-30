import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';

/// HttpOverrides global untuk mengatasi kendala DNS lookup (errno = 7)
/// pada Android Emulator maupun jaringan yang memblokir DNS port 53.
/// Mengarahkan koneksi ke IP Anycast resmi secara langsung dan menangani TLS/HTTPS handshake.
class ResilientHttpOverrides extends HttpOverrides {
  static final Map<String, List<String>> _knownIps = {
    'tokengateway.ai.id': ['104.21.26.158', '172.67.137.36'],
  };

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final client = super.createHttpClient(context);
    client.connectionTimeout = const Duration(seconds: 40);

    client.connectionFactory = (Uri uri, String? proxyHost, int? proxyPort) async {
      final host = (proxyHost ?? uri.host).trim();
      final port = proxyPort ?? (uri.scheme == 'https' ? 443 : 80);
      final isHttps = uri.scheme == 'https';

      // 1. Prioritas Pertama: Jika host ada di daftar Anycast terverifikasi (TokenGateway),
      // hubungkan TCP langsung ke IP numerik dan lakukan TLS upgrade jika HTTPS.
      final staticIps = _knownIps[host.toLowerCase()];
      if (staticIps != null && staticIps.isNotEmpty) {
        for (final ip in staticIps) {
          try {
            debugPrint('[ResilientNetwork] Direct IP connect to $ip for $host:$port (HTTPS=$isHttps)');
            final socketFuture = _connectSocket(InternetAddress(ip), port, host, isHttps, context);
            return ConnectionTask.fromSocket(socketFuture, () {});
          } catch (err) {
            debugPrint('[ResilientNetwork] Gagal static IP $ip: $err');
          }
        }
      }

      // 2. Prioritas Kedua: Coba DNS standar sistem dengan batas waktu 1.5 detik
      try {
        final addresses = await InternetAddress.lookup(host).timeout(const Duration(milliseconds: 1500));
        if (addresses.isNotEmpty) {
          final socketFuture = _connectSocket(addresses.first, port, host, isHttps, context);
          return ConnectionTask.fromSocket(socketFuture, () {});
        }
      } catch (dnsErr) {
        debugPrint('[ResilientNetwork] DNS standar gagal untuk $host ($dnsErr). Beralih ke DoH...');
      }

      // 3. Prioritas Ketiga: Query DNS over HTTPS (DoH) ke IP literal Cloudflare 1.1.1.1
      try {
        final resolvedIp = await _resolveViaDoH(host);
        if (resolvedIp != null) {
          debugPrint('[ResilientNetwork] DoH sukses me-resolve $host -> $resolvedIp');
          final socketFuture = _connectSocket(InternetAddress(resolvedIp), port, host, isHttps, context);
          return ConnectionTask.fromSocket(socketFuture, () {});
        }
      } catch (dohErr) {
        debugPrint('[ResilientNetwork] DoH error: $dohErr');
      }

      // 4. Fallback terakhir: startConnect bawaan
      return await Socket.startConnect(host, port);
    };

    return client;
  }

  /// Membuat koneksi TCP dan melakukan handshake TLS/HTTPS jika diperlukan
  static Future<Socket> _connectSocket(
    InternetAddress address,
    int port,
    String host,
    bool isHttps,
    SecurityContext? context,
  ) async {
    final rawSocket = await Socket.connect(address, port, timeout: const Duration(seconds: 12));
    if (isHttps) {
      return await SecureSocket.secure(
        rawSocket,
        host: host, // Mengirimkan SNI asli (misal: 'tokengateway.ai.id') untuk sertifikat TLS
        context: context,
      );
    }
    return rawSocket;
  }

  /// Resolve hostname via DNS-over-HTTPS ke literal IP 1.1.1.1
  static Future<String?> _resolveViaDoH(String hostname) async {
    HttpClient? dohClient;
    try {
      dohClient = HttpClient();
      dohClient.badCertificateCallback = (cert, host, port) => true;
      dohClient.connectionTimeout = const Duration(seconds: 4);
      final req = await dohClient.getUrl(
        Uri.parse('https://1.1.1.1/dns-query?name=$hostname&type=A'),
      );
      req.headers.set('Accept', 'application/dns-json');
      final res = await req.close();
      if (res.statusCode == 200) {
        final body = await res.transform(utf8.decoder).join();
        final json = jsonDecode(body) as Map<String, dynamic>;
        final answers = json['Answer'] as List<dynamic>?;
        if (answers != null && answers.isNotEmpty) {
          for (final ans in answers) {
            if (ans['type'] == 1 && ans['data'] != null) {
              final ip = ans['data'].toString().trim();
              if (ip.isNotEmpty) {
                _knownIps.putIfAbsent(hostname.toLowerCase(), () => []).add(ip);
                return ip;
              }
            }
          }
        }
      }
    } catch (_) {
    } finally {
      dohClient?.close();
    }
    return null;
  }
}
