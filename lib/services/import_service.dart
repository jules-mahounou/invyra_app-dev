import 'dart:convert';
import 'dart:typed_data'; 

import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';

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

    if (extension == 'xlsx') {
      return _parseExcel(bytes);
    }
    if (extension == 'csv') {
      return _parseCsv(utf8.decode(bytes, allowMalformed: true));
    }
    throw const FormatException('Format non reconnu');
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

  List<String> _splitCsvLine(String line, String separator) {
    return line
        .split(separator)
        .map((value) => value.trim().replaceAll(RegExp('^"|"\$'), ''))
        .toList();
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
}
