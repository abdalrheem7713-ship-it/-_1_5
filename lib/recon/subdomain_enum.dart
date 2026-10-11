// =============================================================================
// نَذْر - اكتشاف النطاقات الفرعية
// =============================================================================
import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;

import 'dns_resolver.dart';
import 'models.dart';

class SubdomainEnumerator {
  final DnsResolver dns;
  List<String>? _wordlist;

  SubdomainEnumerator({DnsResolver? dns}) : dns = dns ?? DnsResolver();

  Future<List<String>> _loadWordlist() async {
    if (_wordlist != null) return _wordlist!;
    try {
      final content = await rootBundle.loadString('assets/subdomains.txt');
      _wordlist = content
          .split('\n')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty && !s.startsWith('#'))
          .toList();
      return _wordlist!;
    } catch (_) {
      return const [];
    }
  }

  Future<Set<String>> passiveLookup(String domain) async {
    final result = <String>{};
    try {
      final uri = Uri.parse('https://crt.sh/?q=%25.$domain&output=json');
      final response = await http
          .get(uri)
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        for (final entry in data) {
          final nameValue = entry['name_value']?.toString() ?? '';
          final names = nameValue.split('\n');
          for (final n in names) {
            final clean = n.trim().toLowerCase();
            if (clean.isEmpty) continue;
            if (clean.startsWith('*.')) continue;
            if (!clean.endsWith(domain)) continue;
            if (clean == domain) continue;
            result.add(clean);
          }
        }
      }
    } catch (_) {}
    return result;
  }

  Future<Set<String>> activeLookup(
    String domain, {
    int concurrency = 30,
    void Function(int done, int total)? onProgress,
  }) async {
    final words = await _loadWordlist();
    if (words.isEmpty) return {};

    final found = <String>{};
    var done = 0;

    for (var i = 0; i < words.length; i += concurrency) {
      final batch = words.skip(i).take(concurrency).toList();
      await Future.wait(batch.map((word) async {
        final candidate = '$word.$domain';
        final exists = await dns.exists(candidate);
        if (exists) found.add(candidate);
        done++;
        onProgress?.call(done, words.length);
      }));
    }

    return found;
  }

  Future<List<Subdomain>> enumerate(
    String domain, {
    bool doPassive = true,
    bool doActive = true,
    void Function(String phase, int done, int total)? onProgress,
    void Function(String found)? onFound,
  }) async {
    final names = <String>{};

    if (doPassive) {
      onProgress?.call('سلبي', 0, 1);
      final passiveNames = await passiveLookup(domain);
      names.addAll(passiveNames);
      for (final n in passiveNames) {
        onFound?.call(n);
      }
      onProgress?.call('سلبي', 1, 1);
    }

    if (doActive) {
      final activeNames = await activeLookup(
        domain,
        onProgress: (done, total) {
          onProgress?.call('نشط', done, total);
        },
      );
      for (final n in activeNames) {
        if (!names.contains(n)) {
          names.add(n);
          onFound?.call(n);
        }
      }
    }

    final results = <Subdomain>[];
    for (final name in names) {
      final ips = await dns.resolve(name);
      if (ips.isNotEmpty) {
        results.add(Subdomain(name: name, ips: ips, isAlive: true));
      }
    }

    results.sort((a, b) => a.name.compareTo(b.name));
    return results;
  }
}