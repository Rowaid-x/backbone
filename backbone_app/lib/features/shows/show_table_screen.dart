import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/models/show_model.dart';
import '../../shared/widgets/status_badge.dart';
import 'shows_providers.dart';

class ShowTableScreen extends ConsumerWidget {
  const ShowTableScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showsAsync = ref.watch(allShowsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Show Table')),
      body: showsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) =>
            Center(child: Text('Error: $e', style: const TextStyle(color: AppColors.error))),
        data: (shows) => _ShowDataTable(shows: shows),
      ),
    );
  }
}

class _ShowDataTable extends StatefulWidget {
  final List<ShowModel> shows;
  const _ShowDataTable({required this.shows});

  @override
  State<_ShowDataTable> createState() => _ShowDataTableState();
}

class _ShowDataTableState extends State<_ShowDataTable> {
  int _sortCol = 0;
  bool _sortAsc = true;

  List<ShowModel> get _sorted {
    final list = [...widget.shows];
    list.sort((a, b) {
      int cmp;
      switch (_sortCol) {
        case 0:
          cmp = (a.startDate ?? DateTime(2099))
              .compareTo(b.startDate ?? DateTime(2099));
        case 1:
          cmp = a.name.compareTo(b.name);
        case 2:
          cmp = a.status.compareTo(b.status);
        case 3:
          cmp = a.category.compareTo(b.category);
        case 4:
          cmp = a.droneCount.compareTo(b.droneCount);
        default:
          cmp = 0;
      }
      return _sortAsc ? cmp : -cmp;
    });
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('yyyy-MM-dd');
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: DataTable(
          headingRowColor:
              WidgetStateProperty.all(AppColors.surfaceVariant),
          dataRowColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.hovered)) return AppColors.border;
            return AppColors.surface;
          }),
          sortColumnIndex: _sortCol,
          sortAscending: _sortAsc,
          columnSpacing: 16,
          horizontalMargin: 16,
          columns: [
            _col('Start Date', 0),
            _col('Show Name', 1),
            _col('Status', 2),
            _col('Category', 3),
            _col('Drones', 4),
            const DataColumn(label: Text('Location', style: _headerStyle)),
            const DataColumn(label: Text('Health', style: _headerStyle)),
            const DataColumn(label: Text('Permit', style: _headerStyle)),
            const DataColumn(label: Text('Design', style: _headerStyle)),
          ],
          rows: _sorted
              .map((s) => DataRow(cells: [
                    DataCell(Text(
                      s.startDate != null ? fmt.format(s.startDate!) : '—',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary),
                    )),
                    DataCell(Text(s.name,
                        style: const TextStyle(
                            fontSize: 13, color: AppColors.textPrimary,
                            fontWeight: FontWeight.w500))),
                    DataCell(StatusBadge(status: s.status)),
                    DataCell(Text(s.category,
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.textSecondary))),
                    DataCell(Text('${s.droneCount}',
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textPrimary))),
                    DataCell(Text(s.location,
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.textSecondary))),
                    DataCell(HealthDot(status: s.health)),
                    DataCell(HealthDot(status: s.permitStatus)),
                    DataCell(HealthDot(status: s.designStatus)),
                  ]))
              .toList(),
        ),
      ),
    );
  }

  DataColumn _col(String label, int index) => DataColumn(
        label: Text(label, style: _headerStyle),
        onSort: (i, asc) => setState(() {
          _sortCol = i;
          _sortAsc = asc;
        }),
      );
}

const _headerStyle = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: AppColors.textSecondary,
    letterSpacing: 0.5);
