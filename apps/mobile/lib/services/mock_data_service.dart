import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../models/book.dart';
import '../models/school.dart';
import '../models/holding.dart';

/// Service for loading and parsing mock data from bundled JSON assets.
class MockDataService {
  /// Parses a JSON string into a list of [Book] objects.
  static List<Book> parseBooks(String jsonString) {
    final List<dynamic> jsonList = json.decode(jsonString) as List<dynamic>;
    return jsonList
        .map((item) => Book.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  /// Parses a JSON string into a list of [School] objects.
  static List<School> parseSchools(String jsonString) {
    final List<dynamic> jsonList = json.decode(jsonString) as List<dynamic>;
    return jsonList
        .map((item) => School.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  /// Parses a JSON string into a list of [Holding] objects.
  static List<Holding> parseHoldings(String jsonString) {
    final List<dynamic> jsonList = json.decode(jsonString) as List<dynamic>;
    return jsonList
        .map((item) => Holding.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  /// Loads books from the bundled assets.
  static Future<List<Book>> loadBooks() async {
    final jsonString = await rootBundle.loadString('assets/mock-data/books.json');
    return parseBooks(jsonString);
  }

  /// Loads schools from the bundled assets.
  static Future<List<School>> loadSchools() async {
    final jsonString = await rootBundle.loadString('assets/mock-data/schools.json');
    return parseSchools(jsonString);
  }

  /// Loads holdings from the bundled assets.
  static Future<List<Holding>> loadHoldings() async {
    final jsonString = await rootBundle.loadString('assets/mock-data/holdings.json');
    return parseHoldings(jsonString);
  }
}
