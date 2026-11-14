import 'scanned_document.dart';
import 'text_layout.dart';

/// Recognises a UAE property document from OCR rows and pulls out its fields.
///
/// Works on the English half of bilingual documents (ML Kit's on-device
/// recogniser reads Latin script only). Rows are printed lines, with pieces
/// that sat side by side separated by [segmentGap] (see [rowsFromLines]).
class DocumentReader {
  const DocumentReader();

  ScannedDocument read(List<String> rows) {
    final kind = classify(rows);
    final r = _Rows(rows);
    final fields = switch (kind) {
      ScannedKind.dewaBill => _dewaBill(r),
      ScannedKind.ejari => _ejari(r),
      ScannedKind.tenancyContract => _tenancyContract(r),
      ScannedKind.titleDeed => _titleDeed(r),
      ScannedKind.emiratesId => _emiratesId(r),
      ScannedKind.passport => _passport(r),
      ScannedKind.unknown => _unknown(r),
    };
    fields.removeWhere((_, v) => v.trim().isEmpty);
    return ScannedDocument(kind, fields);
  }

  ScannedKind classify(List<String> rows) {
    final t = rows.join('\n').toLowerCase();
    bool has(String s) => t.contains(s);
    if (_mrz(rows).passport != null) return ScannedKind.passport;
    if (has('registration certificate') || (has('ejari') && has('registration date'))) return ScannedKind.ejari;
    if (has('tenancy contract') && (has('lessor') || has('tenant information') || has('owner / lessor'))) {
      return ScannedKind.tenancyContract;
    }
    if (has('title deed') || (has('owners numbers') && has('plot no'))) return ScannedKind.titleDeed;
    if ((has('dewa') || has('dubai electricity')) &&
        (has('premise number') || has('green bill') || has('account number') || has('kilowatt'))) {
      return ScannedKind.dewaBill;
    }
    if (has('identity card') || has('resident identity') || RegExp(r'i[l1]are', caseSensitive: false).hasMatch(t.replaceAll(' ', ''))) {
      if (_eid(t) != null) return ScannedKind.emiratesId;
    }
    return ScannedKind.unknown;
  }

  // ---------------------------------------------------------------- DEWA bill

  Map<ScanField, String> _dewaBill(_Rows r) {
    final f = <ScanField, String>{};
    final premise = r.value(RegExp(r'premise\s*(number|no\.?)', caseSensitive: false), _premisePattern);
    if (premise != null) f[ScanField.dewaPremiseNo] = premise;
    // The account number is printed large next to (usually just above) its label.
    final i = r.indexOf(RegExp(r'account\s*number', caseSensitive: false));
    if (i >= 0) {
      for (final j in [i, i - 1, i + 1, i - 2, i + 2]) {
        if (j < 0 || j >= r.rows.length) continue;
        final m = RegExp(r'(?<!\d)(\d{10})(?!\d)').firstMatch(r.rows[j]);
        if (m != null) {
          f[ScanField.dewaAccountNo] = m.group(1)!;
          break;
        }
      }
    }
    final type = r.value(RegExp(r'premise\s*type', caseSensitive: false), RegExp(r'[A-Za-z][A-Za-z -]+'));
    if (type != null) f[ScanField.propertyType] = type;
    return f;
  }

  // ------------------------------------------------- Ejari registration certificate

  Map<ScanField, String> _ejari(_Rows r) {
    final f = <ScanField, String>{};
    f.putIfNotNull(ScanField.ejariNo, r.value(RegExp(r'contract\s*no', caseSensitive: false), RegExp(r'\d{10,20}')));

    final owner = r.section(RegExp(r'^owner\b', caseSensitive: false), RegExp(r'property\s*management|tenancy\s*contract\s*details', caseSensitive: false));
    f.putIfNotNull(ScanField.ownerName, owner.value(RegExp(r'owner\s*name', caseSensitive: false), _namePattern));

    final contract = r.section(RegExp(r'tenancy\s*contract\s*details', caseSensitive: false), RegExp(r'^tenant\b', caseSensitive: false));
    f.putIfNotNull(ScanField.startDate, _date(contract.value(RegExp(r'(?<!grace\s)start\s*date', caseSensitive: false), _datePattern)));
    f.putIfNotNull(ScanField.endDate, _date(contract.value(RegExp(r'(?<!grace\s)end\s*date', caseSensitive: false), _datePattern)));
    f.putIfNotNull(ScanField.annualRent,
        _amount(contract.value(RegExp(r'(?<!actual\s)annual\s*amount', caseSensitive: false), _amountPattern) ??
            contract.value(RegExp(r'(?<!actual\s)contract\s*amount', caseSensitive: false), _amountPattern)));
    f.putIfNotNull(ScanField.securityDeposit, _amount(contract.value(RegExp(r'security\s*deposit', caseSensitive: false), _amountPattern)));

    final tenant = r.section(RegExp(r'^tenant\b(?!\s*(name|no))', caseSensitive: false), RegExp(r'leased\s*unit', caseSensitive: false));
    f.putIfNotNull(ScanField.tenantName, tenant.value(RegExp(r'tenant\s*name', caseSensitive: false), _namePattern));
    f.putIfNotNull(ScanField.tenantEmiratesId, _eid(tenant.value(RegExp(r'emirates\s*id', caseSensitive: false), _eidPattern) ?? ''));
    f.putIfNotNull(ScanField.tenantPassport, tenant.value(RegExp(r'passport', caseSensitive: false), _passportPattern));
    f.putIfNotNull(ScanField.tenantPhone, _phone(tenant.value(RegExp(r'mobile\s*no', caseSensitive: false), _phonePattern)));

    final unit = r.section(RegExp(r'leased\s*unit', caseSensitive: false), null);
    f.putIfNotNull(ScanField.buildingName, unit.value(RegExp(r'building\s*name(\s*/\s*no\.?)?', caseSensitive: false), _wordsPattern));
    f.putIfNotNull(ScanField.community, unit.value(RegExp(r'land\s*area', caseSensitive: false), _wordsPattern));
    f.putIfNotNull(ScanField.plotNo, unit.value(RegExp(r'plot\s*number', caseSensitive: false), RegExp(r'\d[\d-]*')));
    // Table: "Property No.(s) | Type | SubType | Usage | Size | DEWA Premise No." then one value row.
    final header = unit.indexOf(RegExp(r'dewa\s*premise', caseSensitive: false));
    if (header >= 0 && header + 1 < unit.rows.length) {
      final row = unit.rows[header + 1];
      f.putIfNotNull(ScanField.dewaPremiseNo, _premisePattern.allMatches(row).lastOrNull?.group(0));
      f.putIfNotNull(ScanField.unitNo, RegExp(r'^\s*([A-Za-z]?\d+[A-Za-z]?)').firstMatch(row)?.group(1));
      f.putIfNotNull(ScanField.propertyType, RegExp(r'\b(studio|flat|apartment|villa|townhouse|office|shop)\b', caseSensitive: false).allMatches(row).map((m) => m.group(1)!).fold<String?>(null, (best, t) => t.toLowerCase() == 'studio' ? t : best ?? t));
    }
    return f;
  }

  // ------------------------------------------------ DLD tenancy contract (form)

  Map<ScanField, String> _tenancyContract(_Rows r) {
    final f = <ScanField, String>{};
    final owner = r.section(RegExp(r'owner\s*/\s*lessor', caseSensitive: false), RegExp(r'tenant\s*information', caseSensitive: false));
    f.putIfNotNull(ScanField.ownerName,
        owner.value(RegExp(r"owner.?s\s*name", caseSensitive: false), _namePattern) ?? owner.value(RegExp(r"lessor.?s\s*name", caseSensitive: false), _namePattern));
    f.putIfNotNull(ScanField.ownerEmiratesId, _eid(owner.value(RegExp(r"emirates\s*id", caseSensitive: false), _eidPattern) ?? ''));
    f.putIfNotNull(ScanField.ownerEmail, owner.value(RegExp(r"email", caseSensitive: false), _emailPattern)?.toLowerCase());
    f.putIfNotNull(ScanField.ownerPhone, _phone(owner.value(RegExp(r"phone", caseSensitive: false), _phonePattern)));

    final tenant = r.section(RegExp(r'tenant\s*information', caseSensitive: false), RegExp(r'property\s*information', caseSensitive: false));
    f.putIfNotNull(ScanField.tenantName, tenant.value(RegExp(r"tenant.?s\s*name", caseSensitive: false), _namePattern));
    f.putIfNotNull(ScanField.tenantEmiratesId, _eid(tenant.value(RegExp(r"emirates\s*id", caseSensitive: false), _eidPattern) ?? ''));
    f.putIfNotNull(ScanField.tenantEmail, tenant.value(RegExp(r"email", caseSensitive: false), _emailPattern)?.toLowerCase());
    f.putIfNotNull(ScanField.tenantPhone, _phone(tenant.value(RegExp(r"phone", caseSensitive: false), _phonePattern)));

    final prop = r.section(RegExp(r'property\s*information', caseSensitive: false), RegExp(r'contract\s*information', caseSensitive: false));
    f.putIfNotNull(ScanField.plotNo, prop.value(RegExp(r'plot\s*no', caseSensitive: false), RegExp(r'\d[\d-]*')));
    f.putIfNotNull(ScanField.buildingName, prop.value(RegExp(r'building\s*name', caseSensitive: false), _wordsPattern));
    f.putIfNotNull(ScanField.unitNo, prop.value(RegExp(r'property\s*no', caseSensitive: false), RegExp(r'[A-Za-z]?\d+[A-Za-z]?')));
    f.putIfNotNull(ScanField.propertyType, prop.value(RegExp(r'property\s*type', caseSensitive: false), _wordsPattern));
    f.putIfNotNull(ScanField.community, prop.value(RegExp(r'^location|\blocation\b', caseSensitive: false), _wordsPattern));
    f.putIfNotNull(ScanField.dewaPremiseNo, prop.value(RegExp(r'premises?\s*no', caseSensitive: false), _premisePattern));

    final c = r.section(RegExp(r'contract\s*information', caseSensitive: false), RegExp(r'terms\s*(and|&)\s*conditions', caseSensitive: false));
    final period = c.indexOf(RegExp(r'contract\s*period', caseSensitive: false));
    if (period >= 0) {
      // Dates sit on the label row or the row just above it ("from ... to ...").
      final near = [for (final j in [period - 1, period, period + 1]) if (j >= 0 && j < c.rows.length) c.rows[j]].join(' ');
      final dates = _datePattern.allMatches(near).map((m) => _date(m.group(0))).whereType<String>().toList();
      if (dates.isNotEmpty) f[ScanField.startDate] = dates.first;
      if (dates.length > 1) f[ScanField.endDate] = dates[1];
    }
    f.putIfNotNull(ScanField.annualRent, _amount(c.value(RegExp(r'annual\s*rent', caseSensitive: false), _amountPattern)) ??
        _amount(c.value(RegExp(r'contract\s*value', caseSensitive: false), _amountPattern)));
    f.putIfNotNull(ScanField.securityDeposit, _amount(c.value(RegExp(r'security\s*deposit', caseSensitive: false), _amountPattern)));
    final mode = c.value(RegExp(r'mode\s*of\s*payment', caseSensitive: false), RegExp(r'\d+\s*(post[- ]?dated\s*)?cheques?', caseSensitive: false));
    f.putIfNotNull(ScanField.numberOfCheques, mode == null ? null : RegExp(r'\d+').firstMatch(mode)?.group(0));
    return f;
  }

  // --------------------------------------------------------------- Title deed

  Map<ScanField, String> _titleDeed(_Rows r) {
    final f = <ScanField, String>{};
    f.putIfNotNull(ScanField.propertyType, r.value(RegExp(r'property\s*type', caseSensitive: false), _wordsPattern));
    f.putIfNotNull(ScanField.community, r.value(RegExp(r'community', caseSensitive: false), _wordsPattern));
    f.putIfNotNull(ScanField.plotNo, r.value(RegExp(r'plot\s*no', caseSensitive: false), RegExp(r'\d[\d-]*')));
    f.putIfNotNull(ScanField.buildingName, r.value(RegExp(r'building\s*name', caseSensitive: false), RegExp(r'[A-Za-z0-9][A-Za-z0-9 .-]*')));
    f.putIfNotNull(ScanField.unitNo, r.value(RegExp(r'property\s*no', caseSensitive: false), RegExp(r'[A-Za-z]?\d+[A-Za-z]?')));
    final deed = r.value(RegExp(r'(title\s*deed|certificate|deed)\s*(no|number)', caseSensitive: false), RegExp(r'\d[\d/-]{3,}'));
    // New DLD deeds print the certificate number (e.g. 1234/2026) under the QR code.
    f.putIfNotNull(ScanField.titleDeedNo,
        deed ?? r.rows.map((x) => RegExp(r'^\s*(\d{3,7}/\d{4})\s*$').firstMatch(x)?.group(1)).whereType<String>().firstOrNull);
    // "(1234567) OWNER NAME   82" — owner number in brackets, then name, then area.
    final i = r.indexOf(RegExp(r'owners?\s*numbers?', caseSensitive: false));
    if (i >= 0) {
      for (var j = i + 1; j < r.rows.length && j <= i + 3; j++) {
        final m = RegExp(r'\(\s*\d+\s*\)\s*([A-Za-z][A-Za-z .\x27-]*[A-Za-z])').firstMatch(r.rows[j]);
        if (m == null) continue;
        var name = m.group(1)!.trim();
        // A long name can wrap onto the next row on its own.
        if (j + 1 < r.rows.length) {
          final next = r.rows[j + 1].split(segmentGap).first.trim();
          if (RegExp(r'^[A-Z]{2,}( [A-Z]{2,}){0,2}$').hasMatch(next)) name = '$name $next';
        }
        f[ScanField.ownerName] = name;
        break;
      }
    }
    return f;
  }

  // ------------------------------------------------------- ID card / passport

  Map<ScanField, String> _emiratesId(_Rows r) {
    final f = <ScanField, String>{};
    final text = r.rows.join('\n');
    f.putIfNotNull(ScanField.personEmiratesId, _eid(text));
    f.putIfNotNull(ScanField.personName, r.value(RegExp(r'^name\b|\bname\s*:', caseSensitive: false), _namePattern) ?? _mrz(r.rows).idName);
    f.putIfNotNull(
      ScanField.personEmiratesIdExpiry,
      _date(r.value(RegExp(r'expiry|expiration', caseSensitive: false), _datePattern)) ?? _mrz(r.rows).idExpiry,
    );
    return f;
  }

  Map<ScanField, String> _passport(_Rows r) {
    final m = _mrz(r.rows);
    return {
      if (m.passport != null) ScanField.personPassport: m.passport!,
      if (m.passportName != null) ScanField.personName: m.passportName!,
      if (m.passportExpiry != null) ScanField.personPassportExpiry: m.passportExpiry!,
    };
  }

  Map<ScanField, String> _unknown(_Rows r) {
    final f = <ScanField, String>{};
    f.putIfNotNull(ScanField.personEmiratesId, _eid(r.rows.join('\n')));
    return f;
  }
}

// ------------------------------------------------------------------ helpers

final _datePattern = RegExp(r'\b(\d{1,2})[-/.](\d{1,2})[-/.](\d{4})\b');
final _amountPattern = RegExp(r'\d{1,3}(?:,\d{3})+(?:\.\d+)?|\d+(?:\.\d+)?');
final _eidPattern = RegExp(r'784[-\s]?\d{4}[-\s]?\d{7}[-\s]?\d');
final _passportPattern = RegExp(r'\b[A-Z]{1,2}\d{6,8}\b');
final _phonePattern = RegExp(r'(\+?971[-\s]?|0)\d{1,2}[-\s]?\d{3}[-\s]?\d{4}');
final _emailPattern = RegExp(r'[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}');
final _premisePattern = RegExp(r'(?<!\d)\d{9}(?!\d)');
final _namePattern = RegExp(r"[A-Za-z][A-Za-z.\x27 -]*[A-Za-z.]");
final _wordsPattern = RegExp(r"[A-Za-z0-9][A-Za-z0-9.,\x27 /-]*[A-Za-z0-9]");

String? _date(String? s) {
  if (s == null) return null;
  final m = _datePattern.firstMatch(s);
  if (m == null) return null;
  final d = int.parse(m.group(1)!), mo = int.parse(m.group(2)!), y = int.parse(m.group(3)!);
  if (d < 1 || d > 31 || mo < 1 || mo > 12) return null;
  return '${y.toString().padLeft(4, '0')}-${mo.toString().padLeft(2, '0')}-${d.toString().padLeft(2, '0')}';
}

String? _amount(String? s) {
  if (s == null) return null;
  final m = _amountPattern.firstMatch(s);
  if (m == null) return null;
  final v = double.tryParse(m.group(0)!.replaceAll(',', ''));
  if (v == null || v <= 0) return null;
  return v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(2);
}

String? _phone(String? s) => s?.replaceAll(RegExp(r'[\s-]'), '');

/// Emirates ID as 784-YYYY-NNNNNNN-C, from any spacing/dash style.
String? _eid(String s) {
  final m = RegExp(r'784[-\s]?\d{4}[-\s]?\d{7}[-\s]?\d').firstMatch(s);
  if (m == null) return null;
  final d = m.group(0)!.replaceAll(RegExp(r'\D'), '');
  return '${d.substring(0, 3)}-${d.substring(3, 7)}-${d.substring(7, 14)}-${d.substring(14)}';
}

class _Mrz {
  const _Mrz({this.passport, this.passportName, this.passportExpiry, this.idName, this.idExpiry});
  final String? passport, passportName, idName;

  /// Expiry dates as yyyy-MM-dd.
  final String? passportExpiry, idExpiry;
}

/// MRZ date YYMMDD as yyyy-MM-dd. Expiry dates are always 20xx.
String? _mrzDate(String s) {
  if (!RegExp(r'^\d{6}$').hasMatch(s)) return null;
  final mo = int.parse(s.substring(2, 4)), d = int.parse(s.substring(4, 6));
  if (mo < 1 || mo > 12 || d < 1 || d > 31) return null;
  return '20${s.substring(0, 2)}-${s.substring(2, 4)}-${s.substring(4, 6)}';
}

/// Reads machine-readable zones: passports (2 × 44) and Emirates ID backs (3 × 30).
_Mrz _mrz(List<String> rows) {
  final lines = [
    for (final row in rows)
      for (final seg in row.split(segmentGap))
        seg.toUpperCase().replaceAll(' ', '').replaceAll('«', '<').replaceAll('‹', '<'),
  ].where((l) => l.length >= 28 && RegExp(r'^[A-Z0-9<]+$').hasMatch(l) && l.contains('<')).toList();
  String? name(String l) {
    final parts = l.split('<<');
    final surname = parts.first.replaceAll('<', ' ').trim();
    final given = parts.length > 1 ? parts.sublist(1).join(' ').replaceAll('<', ' ').trim() : '';
    final full = [given, surname].where((s) => s.isNotEmpty).join(' ').replaceAll(RegExp(r'\s+'), ' ');
    return full.isEmpty ? null : full;
  }

  for (var i = 0; i < lines.length; i++) {
    final l = lines[i];
    if (RegExp(r'^P[A-Z<][A-Z<]{3}').hasMatch(l) && i + 1 < lines.length) {
      final no = lines[i + 1].substring(0, 9).replaceAll('<', '');
      if (RegExp(r'^[A-Z0-9]{6,9}$').hasMatch(no)) {
        // Line 2: number(9) check(1) nationality(3) birth(6) check(1) sex(1) expiry(6) ...
        final l2 = lines[i + 1];
        final expiry = l2.length >= 27 ? _mrzDate(l2.substring(21, 27)) : null;
        return _Mrz(passport: no, passportName: name(l.substring(5)), passportExpiry: expiry);
      }
    }
    if (l.startsWith('I') && l.contains('ARE') && i + 2 < lines.length && !RegExp(r'\d').hasMatch(lines[i + 2])) {
      // ID card line 2: birth(6) check(1) sex(1) expiry(6) ...
      final l2 = lines[i + 1];
      final expiry = l2.length >= 14 ? _mrzDate(l2.substring(8, 14)) : null;
      return _Mrz(idName: name(lines[i + 2]), idExpiry: expiry);
    }
  }
  return const _Mrz();
}

extension on Map<ScanField, String> {
  void putIfNotNull(ScanField k, String? v) {
    if (v != null && v.trim().isNotEmpty) this[k] = v.trim();
  }
}

/// Row lookups: a value is the text right after its label in the same
/// segment, else the next segment on the row, else the next row.
class _Rows {
  _Rows(this.rows);
  final List<String> rows;

  int indexOf(RegExp re) => rows.indexWhere(re.hasMatch);

  /// Rows from the first one matching [start] up to (not including) [end].
  _Rows section(RegExp start, RegExp? end) {
    final s = rows.indexWhere((r) => start.hasMatch(r.split(segmentGap).first.trim()));
    if (s < 0) return this; // fall back to the whole document
    var e = end == null ? -1 : rows.indexWhere(end.hasMatch, s + 1);
    if (e < 0) e = rows.length;
    return _Rows(rows.sublist(s, e));
  }

  String? value(RegExp label, RegExp pattern) {
    for (var i = 0; i < rows.length; i++) {
      final segs = rows[i].split(segmentGap);
      for (var k = 0; k < segs.length; k++) {
        final m = label.firstMatch(segs[k]);
        if (m == null) continue;
        final candidates = [
          segs[k].substring(m.end).replaceFirst(RegExp(r'^[\s:.#)]+'), ''),
          ...segs.skip(k + 1),
          if (i + 1 < rows.length) rows[i + 1].split(segmentGap).first,
        ];
        for (final c in candidates) {
          final v = pattern.firstMatch(c.trim());
          if (v != null && v.group(0)!.trim().isNotEmpty && !_looksLikeLabel(v.group(0)!)) return v.group(0)!.trim();
        }
        return null;
      }
    }
    return null;
  }
}

/// Printed labels that must never be taken as a value.
bool _looksLikeLabel(String s) => RegExp(
      r"^(owner|lessor|tenant|licen[cs]e|nationality|passport|emirates|mobile|email|e-mail|tel|phone|start|end|grace|discount|security|contract|annual|actual|building|land|plot|property|location|premises?|usage|type|size|makani|mode|community|municipality|floor|parkings?|area|suite|balcony|common|mortgage|issue|date|visa|subtype)\b(?![@.])",
      caseSensitive: false,
    ).hasMatch(s.trim());
