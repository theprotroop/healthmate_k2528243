import 'package:flutter/foundation.dart';
import '../../data/models/health_record.dart';
import '../../data/models/weekly_summary.dart';
import '../../data/database/database_service.dart';

class HealthRecordProvider with ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService.instance;
  List<HealthRecord> _records = [];
  bool _isLoading = false;
  String? _searchDate;

  List<HealthRecord> get records => _records;
  bool get isLoading => _isLoading;
  String? get searchDate => _searchDate;

  HealthRecordProvider() {
    loadRecords();
  }

  Future<void> loadRecords() async {
    _isLoading = true;
    notifyListeners();

    try {
      if (_searchDate != null && _searchDate!.isNotEmpty) {
        _records = await _databaseService.getRecordsByDate(_searchDate!);
      } else {
        _records = await _databaseService.getRecords();
      }
    } catch (e) {
      debugPrint('Error loading records: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addRecord(HealthRecord record) async {
    try {
      await _databaseService.createRecord(record);
      await loadRecords();
    } catch (e) {
      debugPrint('Error adding record: $e');
      rethrow;
    }
  }

  Future<void> updateRecord(HealthRecord record) async {
    try {
      await _databaseService.updateRecord(record);
      await loadRecords();
    } catch (e) {
      debugPrint('Error updating record: $e');
      rethrow;
    }
  }

  Future<void> deleteRecord(int id) async {
    try {
      await _databaseService.deleteRecord(id);
      await loadRecords();
    } catch (e) {
      debugPrint('Error deleting record: $e');
      rethrow;
    }
  }

  Future<List<HealthRecord>> getTodayRecords() async {
    try {
      return await _databaseService.getTodayRecords();
    } catch (e) {
      debugPrint('Error getting today records: $e');
      return [];
    }
  }

  Future<WeeklySummary> getWeeklySummary() async {
    try {
      final end = DateTime.now();
      final start = end.subtract(const Duration(days: 6));
      final records = await _databaseService.getRecordsBetween(start, end);

      if (records.isEmpty) {
        return const WeeklySummary(
          totalSteps: 0,
          totalCalories: 0,
          totalWater: 0,
          daysTracked: 0,
          bestStepsDay: null,
          bestStepsValue: 0,
        );
      }

      final totals = records.fold<Map<String, int>>(
        {'steps': 0, 'calories': 0, 'water': 0},
        (acc, record) {
          acc['steps'] = (acc['steps'] ?? 0) + record.steps;
          acc['calories'] = (acc['calories'] ?? 0) + record.calories;
          acc['water'] = (acc['water'] ?? 0) + record.water;
          return acc;
        },
      );

      final stepsPerDay = <String, int>{};
      for (final record in records) {
        stepsPerDay.update(
          record.date,
          (value) => value + record.steps,
          ifAbsent: () => record.steps,
        );
      }

      final bestDayEntry = stepsPerDay.entries.reduce(
        (current, next) => current.value >= next.value ? current : next,
      );

      return WeeklySummary(
        totalSteps: totals['steps'] ?? 0,
        totalCalories: totals['calories'] ?? 0,
        totalWater: totals['water'] ?? 0,
        daysTracked: stepsPerDay.length,
        bestStepsDay: bestDayEntry.key,
        bestStepsValue: bestDayEntry.value,
      );
    } catch (e) {
      debugPrint('Error computing weekly summary: $e');
      return const WeeklySummary(
        totalSteps: 0,
        totalCalories: 0,
        totalWater: 0,
        daysTracked: 0,
        bestStepsDay: null,
        bestStepsValue: 0,
      );
    }
  }

  Future<List<HealthRecord>> getRecentRecords({int days = 7}) async {
    try {
      final end = DateTime.now();
      final start = end.subtract(Duration(days: days - 1));
      return await _databaseService.getRecordsBetween(start, end);
    } catch (e) {
      debugPrint('Error getting recent records: $e');
      return [];
    }
  }

  Future<bool> quickAddToday() async {
    try {
      final latest = await _databaseService.getLatestRecord();
      if (latest == null) return false;

      final today = _databaseService.formatDate(DateTime.now());
      final record = latest.copyWith(
        id: null,
        date: today,
      );

      await _databaseService.createRecord(record);
      await loadRecords();
      return true;
    } catch (e) {
      debugPrint('Error during quick add: $e');
      return false;
    }
  }

  void setSearchDate(String? date) {
    _searchDate = date;
    loadRecords();
  }

  void clearSearch() {
    _searchDate = null;
    loadRecords();
  }
}

