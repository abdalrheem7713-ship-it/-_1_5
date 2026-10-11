// =============================================================================
// نَذْر - القائمة البيضاء (طبقة الامتثال القانوني)
// =============================================================================
// لا يمكن فحص أي نطاق أو عنوان IP خارج هذه القائمة.
// هذه ليست ميزة UX — بل حماية قانونية إلزامية.

class Whitelist {
  final List<String> _domains = [];
  final List<String> _cidrs = [];

  // ---------- نطاقات ----------
  void addDomain(String d) {
    final t = _normalizeDomain(d);
    if (t.isEmpty || _domains.contains(t)) return;
    _domains.add(t);
  }

  void removeDomain(String d) {
    _domains.remove(_normalizeDomain(d));
  }

  // ---------- نطاقات IP ----------
  void addCidr(String c) {
    final t = c.trim();
    if (t.isEmpty || _cidrs.contains(t)) return;
    if (!_isValidCidr(t)) return;
    _cidrs.add(t);
  }

  void removeCidr(String c) {
    _cidrs.remove(c.trim());
  }

  // ---------- قراءة ----------
  List<String> get domains => List.unmodifiable(_domains);
  List<String> get cidrs => List.unmodifiable(_cidrs);
  bool get isEmpty => _domains.isEmpty && _cidrs.isEmpty;

  // ---------- التحقق ----------
  /// هل النطاق مسموح؟ يُقبل النطاق نفسه أو أي نطاق فرعي منه.
  /// مثال: whitelist = "example.com" -> "mail.example.com" مسموح.
  bool isDomainAllowed(String target) {
    final t = _normalizeDomain(target);
    if (t.isEmpty) return false;

    for (final d in _domains) {
      if (t == d) return true;
      if (t.endsWith('.$d')) return true;
    }
    return false;
  }

  /// هل عنوان IP مسموح ضمن إحدى النطاقات؟
  bool isIpAllowed(String ip) {
    for (final cidr in _cidrs) {
      if (_matchesCidr(ip, cidr)) return true;
    }
    return false;
  }

  /// التحقق العام - يستخدم في الكود.
  bool allows(String target) {
    final t = target.trim();
    if (t.isEmpty) return false;

    // إذا كان عنوان IP -> افحص الـ CIDRs
    if (_isIpv4(t)) return isIpAllowed(t);

    // إذا كان نطاق -> افحص النطاقات
    return isDomainAllowed(t);
  }

  // ---------- أدوات داخلية ----------
  static bool _matchesCidr(String ip, String cidr) {
    try {
      final parts = cidr.split('/');
      if (parts.length != 2) return false;
      final prefix = int.parse(parts[1]);
      if (prefix < 0 || prefix > 32) return false;

      final netOctets = parts[0].split('.').map(int.parse).toList();
      final hostOctets = ip.split('.').map(int.parse).toList();
      if (netOctets.length != 4 || hostOctets.length != 4) return false;

      final netBase = (netOctets[0] << 24) |
          (netOctets[1] << 16) |
          (netOctets[2] << 8) |
          netOctets[3];
      final hostBase = (hostOctets[0] << 24) |
          (hostOctets[1] << 16) |
          (hostOctets[2] << 8) |
          hostOctets[3];
      final mask = prefix == 0 ? 0 : ~((1 << (32 - prefix)) - 1);
      return (netBase & mask) == (hostBase & mask);
    } catch (_) {
      return false;
    }
  }

  static bool _isValidCidr(String cidr) {
    try {
      final parts = cidr.split('/');
      if (parts.length != 2) return false;
      final prefix = int.parse(parts[1]);
      if (prefix < 0 || prefix > 32) return false;
      final octets = parts[0].split('.').map(int.parse).toList();
      if (octets.length != 4) return false;
      for (final o in octets) {
        if (o < 0 || o > 255) return false;
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  static bool _isIpv4(String s) {
    final parts = s.split('.');
    if (parts.length != 4) return false;
    for (final p in parts) {
      final v = int.tryParse(p);
      if (v == null || v < 0 || v > 255) return false;
    }
    return true;
  }

  /// تطبيع النطاق: إزالة البروتوكول، المسار، والمنفذ.
  static String _normalizeDomain(String d) {
    var t = d.trim().toLowerCase();
    if (t.startsWith('http://')) t = t.substring(7);
    if (t.startsWith('https://')) t = t.substring(8);
    final slash = t.indexOf('/');
    if (slash >= 0) t = t.substring(0, slash);
    final colon = t.indexOf(':');
    if (colon >= 0) t = t.substring(0, colon);
    // إزالة النقطة الأخيرة
    if (t.endsWith('.')) t = t.substring(0, t.length - 1);
    return t;
  }

  // ---------- حفظ / تحميل ----------
  Map<String, dynamic> toJson() => {
        'domains': _domains,
        'cidrs': _cidrs,
      };

  void loadFrom(Map<String, dynamic> j) {
    _domains.clear();
    _cidrs.clear();
    (j['domains'] as List?)?.forEach((e) => addDomain(e.toString()));
    (j['cidrs'] as List?)?.forEach((e) => addCidr(e.toString()));
  }
}