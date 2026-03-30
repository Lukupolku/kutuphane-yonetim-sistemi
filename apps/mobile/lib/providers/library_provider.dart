import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../database/database_helper.dart';
import '../models/room.dart';
import '../models/bookshelf.dart';
import '../models/shelf.dart';

class LibraryProvider extends ChangeNotifier {
  final _db = DatabaseHelper.instance;
  static const _uuid = Uuid();

  List<Room> _rooms = [];
  List<Bookshelf> _bookshelves = [];
  List<Shelf> _shelves = [];

  List<Room> get rooms => _rooms;
  List<Bookshelf> get bookshelves => _bookshelves;
  List<Shelf> get shelves => _shelves;

  List<Bookshelf> bookshelvesForRoom(String roomId) =>
      _bookshelves.where((b) => b.roomId == roomId).toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

  List<Shelf> shelvesForBookshelf(String bookshelfId) =>
      _shelves.where((s) => s.bookshelfId == bookshelfId).toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

  int bookshelfCountForRoom(String roomId) =>
      _bookshelves.where((b) => b.roomId == roomId).length;

  int shelfCountForBookshelf(String bookshelfId) =>
      _shelves.where((s) => s.bookshelfId == bookshelfId).length;

  Future<void> loadAll() async {
    final db = await _db.database;
    final roomMaps = await db.query('rooms', orderBy: 'sort_order');
    _rooms = roomMaps.map(Room.fromMap).toList();

    final bsMaps = await db.query('bookshelves', orderBy: 'sort_order');
    _bookshelves = bsMaps.map(Bookshelf.fromMap).toList();

    final shelfMaps = await db.query('shelves', orderBy: 'sort_order');
    _shelves = shelfMaps.map(Shelf.fromMap).toList();

    notifyListeners();
  }

  // ─── Rooms ───────────────────────────────────────────────

  Future<Room> addRoom(String name, {String? icon}) async {
    final room = Room(
      id: _uuid.v4(),
      name: name,
      icon: icon,
      sortOrder: _rooms.length,
      createdAt: DateTime.now(),
    );
    final db = await _db.database;
    await db.insert('rooms', room.toMap());
    _rooms.add(room);
    notifyListeners();
    return room;
  }

  Future<void> updateRoom(Room room) async {
    final db = await _db.database;
    await db.update('rooms', room.toMap(), where: 'id = ?', whereArgs: [room.id]);
    final i = _rooms.indexWhere((r) => r.id == room.id);
    if (i >= 0) _rooms[i] = room;
    notifyListeners();
  }

  Future<void> deleteRoom(String id) async {
    final db = await _db.database;
    await db.delete('rooms', where: 'id = ?', whereArgs: [id]);
    _rooms.removeWhere((r) => r.id == id);
    _bookshelves.removeWhere((b) => b.roomId == id);
    notifyListeners();
  }

  // ─── Bookshelves ─────────────────────────────────────────

  Future<Bookshelf> addBookshelf(String roomId, String name) async {
    final bs = Bookshelf(
      id: _uuid.v4(),
      roomId: roomId,
      name: name,
      sortOrder: bookshelvesForRoom(roomId).length,
      createdAt: DateTime.now(),
    );
    final db = await _db.database;
    await db.insert('bookshelves', bs.toMap());
    _bookshelves.add(bs);
    notifyListeners();
    return bs;
  }

  Future<void> updateBookshelf(Bookshelf bs) async {
    final db = await _db.database;
    await db.update('bookshelves', bs.toMap(), where: 'id = ?', whereArgs: [bs.id]);
    final i = _bookshelves.indexWhere((b) => b.id == bs.id);
    if (i >= 0) _bookshelves[i] = bs;
    notifyListeners();
  }

  Future<void> deleteBookshelf(String id) async {
    final db = await _db.database;
    await db.delete('bookshelves', where: 'id = ?', whereArgs: [id]);
    _bookshelves.removeWhere((b) => b.id == id);
    _shelves.removeWhere((s) => s.bookshelfId == id);
    notifyListeners();
  }

  // ─── Shelves ─────────────────────────────────────────────

  Future<Shelf> addShelf(String bookshelfId, String name) async {
    final shelf = Shelf(
      id: _uuid.v4(),
      bookshelfId: bookshelfId,
      name: name,
      sortOrder: shelvesForBookshelf(bookshelfId).length,
      createdAt: DateTime.now(),
    );
    final db = await _db.database;
    await db.insert('shelves', shelf.toMap());
    _shelves.add(shelf);
    notifyListeners();
    return shelf;
  }

  Future<void> updateShelf(Shelf shelf) async {
    final db = await _db.database;
    await db.update('shelves', shelf.toMap(), where: 'id = ?', whereArgs: [shelf.id]);
    final i = _shelves.indexWhere((s) => s.id == shelf.id);
    if (i >= 0) _shelves[i] = shelf;
    notifyListeners();
  }

  Future<void> deleteShelf(String id) async {
    final db = await _db.database;
    await db.delete('shelves', where: 'id = ?', whereArgs: [id]);
    _shelves.removeWhere((s) => s.id == id);
    notifyListeners();
  }

  /// Path label for a shelf: "Room > Bookshelf > Shelf"
  String shelfPath(String shelfId) {
    final shelf = _shelves.firstWhere((s) => s.id == shelfId,
        orElse: () => Shelf(id: '', bookshelfId: '', name: '?', createdAt: DateTime.now()));
    final bs = _bookshelves.firstWhere((b) => b.id == shelf.bookshelfId,
        orElse: () => Bookshelf(id: '', roomId: '', name: '?', createdAt: DateTime.now()));
    final room = _rooms.firstWhere((r) => r.id == bs.roomId,
        orElse: () => Room(id: '', name: '?', createdAt: DateTime.now()));
    return '${room.name} > ${bs.name} > ${shelf.name}';
  }
}
