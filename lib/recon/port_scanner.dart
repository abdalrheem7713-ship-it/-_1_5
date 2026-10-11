// =============================================================================
// نَذْر - فحص المنافذ (TCP Connect Scan)
// =============================================================================
import 'dart:async';
import 'dart:io';

import 'models.dart';

class PortScanner {
  /// المنافذ الشائعة للفحص السريع.
  static const List<int> commonPorts = [
    21, 22, 23, 25, 53, 80, 110, 111, 135, 139, 143, 443, 445,
    993, 995, 1433, 1521, 1723, 3306, 3389, 4443, 5432, 5900,
    5984, 6379, 7001, 8000, 8008, 8080, 8081, 8443, 8888, 9000,
    9090, 9200, 9300, 10000, 11211, 27017, 50000,
  ];

  /// المنافذ الشائعة جدًا (سريعة).
  static const List<int> fastPorts = [
    21, 22, 25, 53, 80, 110, 143, 443, 445, 3306, 3389, 5432, 8080, 8443,
  ];

  /// فحص منفذ واحد.
  Future<PortResult> scanPort(
    String host,
    int port, {
    Duration timeout = const Duration(seconds: 2),
    bool grabBanner = false,
  }) async {
    final sw = Stopwatch()..start();
    Socket? socket;
    try {
      socket = await Socket.connect(host, port, timeout: timeout);
      sw.stop();

      String? banner;
      if (grabBanner) {
        banner = await _tryBanner(socket, port);
      }

      socket.destroy();
      return PortResult(
        port: port,
        isOpen: true,
        latency: sw.elapsed,
        service: serviceName(port),
        banner: banner,
      );
    } catch (_) {
      socket?.destroy();
      return PortResult(port: port, isOpen: false);
    }
  }

  /// فحص قائمة منافذ مع تحكم في التوازي.
  Future<List<PortResult>> scanPorts(
    String host,
    List<int> ports, {
    Duration timeout = const Duration(seconds: 2),
    int concurrency = 20,
    bool grabBanner = false,
    void Function(PortResult result)? onResult,
    void Function(int done, int total)? onProgress,
    bool Function()? shouldStop,
  }) async {
    final all = <PortResult>[];
    var done = 0;

    for (var i = 0; i < ports.length; i += concurrency) {
      if (shouldStop?.call() ?? false) break;
      final batch = ports.skip(i).take(concurrency).toList();
      final results = await Future.wait(batch.map(
        (p) => scanPort(host, p, timeout: timeout, grabBanner: grabBanner),
      ));

      for (final r in results) {
        all.add(r);
        done++;
        onResult?.call(r);
        onProgress?.call(done, ports.length);
      }
    }

    return all;
  }

  /// محاولة قراءة بانر الخدمة (لـ SSH/SMTP/FTP/HTTP).
  Future<String?> _tryBanner(Socket socket, int port) async {
    try {
      // بعض الخدمات تحتاج دفع طلب أولًا
      if (port == 80 || port == 8080 || port == 8000) {
        socket.write('HEAD / HTTP/1.0\r\n\r\n');
      } else if (port == 25 || port == 587) {
        socket.write('EHLO nazr.local\r\n');
      }

      final buffer = StringBuffer();
      final stream = socket
          .cast<List<int>>()
          .transform(const SystemEncoding().decoder)
          .timeout(const Duration(milliseconds: 800));

      await for (final chunk in stream) {
        buffer.write(chunk);
        if (buffer.length > 512) break;
      }

      final text = buffer.toString().trim();
      return text.isEmpty ? null : text;
    } catch (_) {
      return null;
    }
  }

  /// اسم الخدمة المتعارف عليها للمنفذ.
  static String serviceName(int port) {
    const map = {
      20: 'FTP-Data',
      21: 'FTP',
      22: 'SSH',
      23: 'Telnet',
      25: 'SMTP',
      53: 'DNS',
      67: 'DHCP',
      69: 'TFTP',
      80: 'HTTP',
      110: 'POP3',
      111: 'RPC',
      123: 'NTP',
      135: 'MS-RPC',
      137: 'NetBIOS-NS',
      139: 'NetBIOS',
      143: 'IMAP',
      161: 'SNMP',
      389: 'LDAP',
      443: 'HTTPS',
      445: 'SMB',
      465: 'SMTPS',
      514: 'Syslog',
      587: 'SMTP-Sub',
      636: 'LDAPS',
      993: 'IMAPS',
      995: 'POP3S',
      1080: 'SOCKS',
      1433: 'MSSQL',
      1521: 'Oracle',
      1723: 'PPTP',
      2049: 'NFS',
      3306: 'MySQL',
      3389: 'RDP',
      4443: 'HTTPS-Alt',
      5432: 'PostgreSQL',
      5900: 'VNC',
      5984: 'CouchDB',
      6379: 'Redis',
      7001: 'WebLogic',
      8000: 'HTTP-Alt',
      8008: 'HTTP-Alt',
      8080: 'HTTP-Alt',
      8081: 'HTTP-Alt',
      8443: 'HTTPS-Alt',
      8888: 'HTTP-Alt',
      9000: 'HTTP-Alt',
      9090: 'HTTP-Alt',
      9200: 'Elasticsearch',
      9300: 'Elasticsearch',
      10000: 'Webmin',
      11211: 'Memcached',
      27017: 'MongoDB',
      50000: 'SAP',
    };
    return map[port] ?? 'غير معروف';
  }
}