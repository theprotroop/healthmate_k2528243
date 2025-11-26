import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../data/models/health_record.dart';
import '../providers/health_record_provider.dart';
import 'add_record_screen.dart';

class RecordListScreen extends StatefulWidget {
  const RecordListScreen({super.key});

  @override
  State<RecordListScreen> createState() => _RecordListScreenState();
}

class _RecordListScreenState extends State<RecordListScreen> {
  final TextEditingController _searchController = TextEditingController();
  DateTime? _selectedDate;
  String _activeFilter = 'all';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final provider = Provider.of<HealthRecordProvider>(context, listen: false);
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && mounted) {
      setState(() {
        _selectedDate = picked;
        _searchController.text = DateFormat('yyyy-MM-dd').format(picked);
        _activeFilter = 'custom';
      });
      if (mounted) {
        provider.setSearchDate(_searchController.text);
      }
    }
  }

  void _clearSearch() {
    setState(() {
      _selectedDate = null;
      _searchController.clear();
      _activeFilter = 'all';
    });
    Provider.of<HealthRecordProvider>(context, listen: false).clearSearch();
  }

  void _applyFilter(String filter) {
    final provider = Provider.of<HealthRecordProvider>(context, listen: false);
    setState(() {
      _activeFilter = filter;
    });

    if (filter == 'today') {
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      _searchController.text = today;
      provider.setSearchDate(today);
    } else if (filter == 'all') {
      _clearSearch();
    }
  }

  void _deleteRecord(BuildContext context, HealthRecord record) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Record'),
          content: Text('Are you sure you want to delete the record for ${record.date}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Provider.of<HealthRecordProvider>(context, listen: false)
                    .deleteRecord(record.id!);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Record deleted successfully!')),
                );
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Health Records'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: _clearSearch,
              tooltip: 'Clear search',
            ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search by Date (YYYY-MM-DD)',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: _clearSearch,
                      )
                    : IconButton(
                        icon: const Icon(Icons.calendar_today),
                        onPressed: () => _selectDate(context),
                      ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              onChanged: (value) {
                if (value.isEmpty) {
                  _clearSearch();
                } else {
                  setState(() {
                    _activeFilter = 'custom';
                  });
                  Provider.of<HealthRecordProvider>(context, listen: false)
                      .setSearchDate(value);
                }
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 12,
              children: [
                ChoiceChip(
                  label: const Text('All'),
                  selected: _activeFilter == 'all',
                  onSelected: (_) => _applyFilter('all'),
                ),
                ChoiceChip(
                  label: const Text('Today'),
                  selected: _activeFilter == 'today',
                  onSelected: (_) => _applyFilter('today'),
                ),
                ChoiceChip(
                  label: const Text('Custom'),
                  selected: _activeFilter == 'custom',
                  onSelected: (_) {},
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Records List
          Expanded(
            child: Consumer<HealthRecordProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (provider.records.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inbox,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No records found',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: provider.records.length,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemBuilder: (context, index) {
                    final record = provider.records[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        title: Text(
                          record.date,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.directions_walk,
                                      size: 20, color: Colors.green),
                                  const SizedBox(width: 8),
                                  Text('Steps: ${record.steps}'),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.local_fire_department,
                                      size: 20, color: Colors.red),
                                  const SizedBox(width: 8),
                                  Text('Calories: ${record.calories}'),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.water_drop,
                                      size: 20, color: Colors.blue),
                                  const SizedBox(width: 8),
                                  Text('Water: ${record.water} ml'),
                                ],
                              ),
                            ],
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        AddRecordScreen(record: record),
                                  ),
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteRecord(context, record),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          final provider = Provider.of<HealthRecordProvider>(context, listen: false);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddRecordScreen(),
            ),
          ).then((_) {
            if (mounted) {
              provider.loadRecords();
            }
          });
        },
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

