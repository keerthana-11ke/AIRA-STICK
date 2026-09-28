import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/navigation_data.dart';

class AlertHistoryScreen extends StatefulWidget {
  const AlertHistoryScreen({super.key});

  @override
  State<AlertHistoryScreen> createState() => _AlertHistoryScreenState();
}

class _AlertHistoryScreenState extends State<AlertHistoryScreen> {
  String _searchQuery = "";
  String _selectedPriority = "ALL"; // ALL, CRITICAL, HIGH, MEDIUM, LOW
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<NavigationProvider>(context);
    final alerts = provider.alerts;

    // Filtering logic
    final filteredAlerts = alerts.where((alert) {
      final matchesSearch = alert.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          alert.description.toLowerCase().contains(_searchQuery.toLowerCase());
      
      final matchesPriority = _selectedPriority == "ALL" || alert.priority == _selectedPriority;
      
      return matchesSearch && matchesPriority;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("ALERT TIMELINE"),
        actions: [
          if (alerts.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined),
              tooltip: "Clear Logs",
              onPressed: () => _showClearConfirmation(context, provider),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search Input Section
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: TextField(
                controller: _searchController,
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val;
                  });
                },
                decoration: InputDecoration(
                  hintText: "Search alert logs...",
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = "";
                            });
                          },
                        )
                      : null,
                ),
              ),
            ),

            // Horizontal Priority Filter Chips
            SizedBox(
              height: 50,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  _buildFilterChip("ALL", "All Logs"),
                  _buildFilterChip("CRITICAL", "Critical 🚨"),
                  _buildFilterChip("HIGH", "High ⚠️"),
                  _buildFilterChip("MEDIUM", "Medium ℹ️"),
                  _buildFilterChip("LOW", "Low ✅"),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Timeline List View
            Expanded(
              child: filteredAlerts.isEmpty
                  ? _buildEmptyState(context)
                  : ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.only(top: 8, bottom: 80),
                      itemCount: filteredAlerts.length,
                      itemBuilder: (context, index) {
                        final alert = filteredAlerts[index];
                        final isLast = index == filteredAlerts.length - 1;
                        return _buildTimelineItem(context, alert, isLast);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // Double Confirmation dialog for clearing logs
  void _showClearConfirmation(BuildContext context, NavigationProvider provider) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text("Clear Logs?"),
          content: const Text("Are you sure you want to permanently clear the alert history? This cannot be undone."),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD90429),
                minimumSize: const Size(80, 40),
              ),
              onPressed: () {
                provider.clearHistory();
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Alert history cleared."),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: const Text("Clear All"),
            ),
          ],
        );
      },
    );
  }

  // Empty state visualizer
  Widget _buildEmptyState(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history_toggle_off,
            size: 64,
            color: isDark ? Colors.white24 : Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            "No alerts found",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _searchQuery.isNotEmpty || _selectedPriority != "ALL"
                ? "Try adjusting your filters or search terms."
                : "The stick telemetry reports a safe state.",
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.grey[500] : Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  // Filter Chip Generator Widget
  Widget _buildFilterChip(String priorityValue, String label) {
    final isSelected = _selectedPriority == priorityValue;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (val) {
          if (val) {
            setState(() {
              _selectedPriority = priorityValue;
            });
          }
        },
        selectedColor: const Color(0xFF5C2219).withOpacity(0.15),
        checkmarkColor: const Color(0xFF5C2219),
        labelStyle: TextStyle(
          color: isSelected ? const Color(0xFF5C2219) : null,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isSelected ? const Color(0xFF5C2219) : Colors.transparent,
            width: 1,
          ),
        ),
      ),
    );
  }

  // Timeline list tile
  Widget _buildTimelineItem(BuildContext context, AlertHistoryItem alert, bool isLast) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Formatting the date
    final timeStr = "${alert.timestamp.hour.toString().padLeft(2, '0')}:${alert.timestamp.minute.toString().padLeft(2, '0')}";

    Color priorityColor;
    switch (alert.priority) {
      case "CRITICAL":
        priorityColor = const Color(0xFFD90429);
        break;
      case "HIGH":
        priorityColor = Colors.orange;
        break;
      case "MEDIUM":
        priorityColor = const Color(0xFFE58554);
        break;
      case "LOW":
      default:
        priorityColor = const Color(0xFF5C2219);
        break;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline timestamp on Left
          SizedBox(
            width: 50,
            child: Padding(
              padding: const EdgeInsets.only(top: 14.0),
              child: Text(
                timeStr,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: isDark ? Colors.grey[400] : Colors.grey[700],
                ),
                textAlign: TextAlign.right,
              ),
            ),
          ),
          
          const SizedBox(width: 12),

          // Timeline Node Line (drawn dynamically via layout structures)
          Column(
            children: [
              const SizedBox(height: 12),
              // Timeline Node circle
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: priorityColor,
                  border: Border.all(
                    color: isDark ? const Color(0xFF0F172A) : Colors.white,
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: priorityColor.withOpacity(0.4),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
              // Timeline Line
              if (!isLast)
                Container(
                  width: 2,
                  height: 74, // fixed height segment
                  color: isDark ? Colors.white12 : Colors.grey[300],
                ),
            ],
          ),

          const SizedBox(width: 12),

          // Timeline content Card on Right
          Expanded(
            child: Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(14.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Icon inside Card
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: priorityColor.withOpacity(0.08),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        alert.icon,
                        color: priorityColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Message texts
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                alert.title,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: priorityColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  alert.priority,
                                  style: TextStyle(
                                    color: priorityColor,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            alert.description,
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? Colors.grey[400] : Colors.grey[600],
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
