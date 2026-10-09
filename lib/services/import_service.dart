import 'dart:convert';
import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show compute;

class ImportService {
  Future<List<Map<String, dynamic>>?> pickAndParseFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'csv'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return null;

    final file = result.files.single;
    final Uint8List? bytes = file.bytes;
    final extension = file.extension?.toLowerCase();
    if (bytes == null || extension == null) {
      throw const FormatException('Format non reconnu');
    }

    // Le décodage/parsing (surtout Excel) peut être coûteux sur un gros
    // fichier : on l'exécute dans un isolate dédié pour ne pas geler l'UI.
    if (extension == 'xlsx') {
      return compute(_parseExcel, bytes);
    }
    if (extension == 'csv') {
      return compute(_parseCsv, utf8.decode(bytes, allowMalformed: true));
    }
    throw const FormatException('Format non reconnu');
  }
}

List<Map<String, dynamic>> _parseExcel(List<int> bytes) {
  final workbook = Excel.decodeBytes(bytes);
  if (workbook.tables.isEmpty) {
    throw const FormatException('Format non reconnu');
  }
  final rows = workbook.tables.values.first.rows;
  if (rows.isEmpty) {
    throw const FormatException('Format non reconnu');
  }
  final header = rows.first
      .map((cell) => cell?.value?.toString() ?? '')
      .toList();
  final mapping = _buildColumnMapping(header);
  return rows
      .skip(1)
      .map((row) {
        return _guestFromCells(
          mapping,
          row.map((cell) => cell?.value?.toString() ?? '').toList(),
        );
      })
      .where(_hasName)
      .toList();
}

List<Map<String, dynamic>> _parseCsv(String content) {
  final lines = const LineSplitter()
      .convert(content)
      .where((line) => line.trim().isNotEmpty)
      .toList();
  if (lines.isEmpty) {
    throw const FormatException('Format non reconnu');
  }
  final separator = lines.first.contains(';') ? ';' : ',';
  final header = _splitCsvLine(lines.first, separator);
  final mapping = _buildColumnMapping(header);
  return lines
      .skip(1)
      .map((line) {
        return _guestFromCells(mapping, _splitCsvLine(line, separator));
      })
      .where(_hasName)
      .toList();
}

Map<String, int> _buildColumnMapping(List<String> header) {
  final mapping = <String, int>{};
  for (var i = 0; i < header.length; i++) {
    final key = _normalizeHeader(header[i]);
    if (['nom', 'name', 'full_name', 'fullname'].contains(key)) {
      mapping['full_name'] = i;
    } else if (['telephone', 'phone', 'whatsapp'].contains(key)) {
      mapping['phone'] = i;
    } else if (['email', 'mail'].contains(key)) {
      mapping['email'] = i;
    }
  }
  if (!mapping.containsKey('full_name')) {
    throw const FormatException('Format non reconnu');
  }
  return mapping;
}

Map<String, dynamic> _guestFromCells(
  Map<String, int> mapping,
  List<String> cells,
) {
  String value(String key) {
    final index = mapping[key];
    if (index == null || index >= cells.length) return '';
    return cells[index].trim();
  }

  return {
    'full_name': value('full_name'),
    'phone': value('phone'),
    'email': value('email'),
  };
}

/// Découpe une ligne CSV en respectant les champs entre guillemets
/// (séparateur ou guillemet échappé `""` à l'intérieur d'un champ cité),
/// contrairement à un simple `split()` qui décale les colonnes suivantes
/// dès qu'un champ contient le séparateur (ex: export Excel `"Dupont, Jean"`).
List<String> _splitCsvLine(String line, String separator) {
  final fields = <String>[];
  final buffer = StringBuffer();
  var inQuotes = false;

  for (var i = 0; i < line.length; i++) {
    final char = line[i];
    if (inQuotes) {
      if (char == '"') {
        if (i + 1 < line.length && line[i + 1] == '"') {
          buffer.write('"');
          i++;
        } else {
          inQuotes = false;
        }
      } else {
        buffer.write(char);
      }
    } else if (char == '"') {
      inQuotes = true;
    } else if (char == separator) {
      fields.add(buffer.toString().trim());
      buffer.clear();
    } else {
      buffer.write(char);
    }
  }
  fields.add(buffer.toString().trim());
  return fields;
}

String _normalizeHeader(String value) {
  return value
      .toLowerCase()
      .trim()
      .replaceAll('é', 'e')
      .replaceAll('è', 'e')
      .replaceAll('ê', 'e')
      .replaceAll('ë', 'e')
      .replaceAll(' ', '_');
}

bool _hasName(Map<String, dynamic> guest) {
  return (guest['full_name'] as String?)?.trim().isNotEmpty == true;
}
