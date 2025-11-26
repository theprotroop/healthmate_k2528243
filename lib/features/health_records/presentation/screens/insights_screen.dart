import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../data/models/health_record.dart';
import '../../data/models/weekly_summary.dart';
import '../providers/health_record_provider.dart';

class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Insights'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<dynamic>>(
        future: Future.wait([
          Provider.of<HealthRecordProvider>(context, listen: false)
              .getWeeklySummary(),
          Provider.of<HealthRecordProvider>(context, listen: false)
              .getRecentRecords(days: 7),
        ]),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || snapshot.data == null) {
            return const Center(child: Text('Unable to load insights.'));
          }

          final WeeklySummary summary = snapshot.data![0] as WeeklySummary;
          final List<HealthRecord> recentRecords =
              snapshot.data![1] as List<HealthRecord>;

          return RefreshIndicator(
            onRefresh: () async {
              await Provider.of<HealthRecordProvider>(context, listen: false)
                  .loadRecords();
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'Weekly pulse',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                _buildWeeklySummary(context, summary),
                const SizedBox(height: 24),
                Text(
                  '7-day activity trend',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                _buildTrendList(context, recentRecords),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildWeeklySummary(BuildContext context, WeeklySummary summary) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _SummaryChip(
                  label: 'Avg steps',
                  value: summary.averageSteps.toStringAsFixed(0),
                  subtitle: 'per active day',
                  color: Colors.green,
                ),
                _SummaryChip(
                  label: 'Avg calories',
                  value: summary.averageCalories.toStringAsFixed(0),
                  subtitle: 'per active day',
                  color: Colors.red,
                ),
                _SummaryChip(
                  label: 'Avg water',
                  value: '${summary.averageWater.toStringAsFixed(0)} ml',
                  subtitle: 'per active day',
                  color: Colors.blue,
                ),
              ],
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: colorScheme.primaryContainer,
                child: const Icon(Icons.emoji_events, color: Colors.orange),
              ),
              title: const Text('Best steps day'),
              subtitle: Text(
                summary.bestStepsDay != null
                    ? '${summary.bestStepsDay} • ${summary.bestStepsValue} steps'
                    : 'Log at least one day to see highlights',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendList(
      BuildContext context, List<HealthRecord> recentRecords) {
    if (recentRecords.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(Icons.auto_graph, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 12),
              const Text('No data yet. Start logging to see your trends.'),
            ],
          ),
        ),
      );
    }

    final grouped = <String, List<HealthRecord>>{};
    for (final record in recentRecords) {
      grouped.putIfAbsent(record.date, () => []).add(record);
    }

    final formatter = DateFormat('EEE, MMM d');

    return Column(
      children: grouped.entries.map((entry) {
        final dateLabel = entry.key;
        final friendlyDate = formatter.format(DateTime.parse(dateLabel));
        final totals = entry.value.fold<Map<String, int>>(
          {'steps': 0, 'calories': 0, 'water': 0},
          (acc, record) {
            acc['steps'] = (acc['steps'] ?? 0) + record.steps;
            acc['calories'] = (acc['calories'] ?? 0) + record.calories;
            acc['water'] = (acc['water'] ?? 0) + record.water;
            return acc;
          },
        );

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  friendlyDate,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                _TrendBar(
                  icon: Icons.directions_walk,
                  label: 'Steps',
                  value: totals['steps'] ?? 0,
                  color: Colors.green,
                ),
                _TrendBar(
                  icon: Icons.local_fire_department,
                  label: 'Calories',
                  value: totals['calories'] ?? 0,
                  color: Colors.red,
                ),
                _TrendBar(
                  icon: Icons.water_drop,
                  label: 'Water (ml)',
                  value: totals['water'] ?? 0,
                  color: Colors.blue,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final String label;
  final String value;
  final String subtitle;
  final Color color;

  const _SummaryChip({
    required this.label,
    required this.value,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 11, color: Colors.black54),
          ),
        ],
      ),
    );
  }
}

class _TrendBar extends StatelessWidget {
  final IconData icon;
  final String label;
  final int value;
  final Color color;

  const _TrendBar({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final normalized = (value / 12000).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: normalized,
                    minHeight: 6,
                    backgroundColor: color.withValues(alpha: 0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            value.toString(),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

