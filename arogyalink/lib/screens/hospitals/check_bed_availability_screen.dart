// ignore_for_file: use_build_context_synchronously, unnecessary_null_comparison, unnecessary_type_check, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:arogyalink/services/api_service.dart';
import 'package:percent_indicator/percent_indicator.dart';

// You will need to add the percent_indicator package to your pubspec.yaml:
// dependencies:
//   percent_indicator: ^4.2.3

class CheckBedAvailabilityScreen extends StatefulWidget {
  const CheckBedAvailabilityScreen({super.key});

  @override
  State<CheckBedAvailabilityScreen> createState() =>
      _CheckBedAvailabilityScreenState();
}

class _CheckBedAvailabilityScreenState
    extends State<CheckBedAvailabilityScreen> {
  List<dynamic> _bedPartitions = [];
  bool _isLoading = true;
  final ApiService _apiService = ApiService();
  int? _selectedIndex;

  @override
  void initState() {
    super.initState();
    _fetchBedPartitions();
  }

  Future<void> _fetchBedPartitions() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _apiService.getBedPartitions();

      if (response['success'] && response['data'] is List) {
        final partitions = response['data'];
        setState(() {
          _bedPartitions = partitions;
          if (_bedPartitions.isNotEmpty) {
            _selectedIndex = 0;
          } else {
            _selectedIndex = null;
          }
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              response['message'] ?? 'Failed to fetch bed partitions.',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Error fetching bed partitions: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('An error occurred. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

   void _showPartitionDialog({dynamic partition}) {
    final TextEditingController nameController = TextEditingController(
      text: partition?['partition_name'] ?? '',
    );
    final TextEditingController totalBedsController = TextEditingController(
      text: partition?['total_beds']?.toString() ?? '',
    );

    // Keep the original available beds for the edit case
    final int originalAvailableBeds =
        int.tryParse(partition?['available_beds']?.toString() ?? '0') ?? 0;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            partition == null ? 'Add Bed Partition' : 'Edit Bed Partition',
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Partition Name (e.g., ICU, General Ward)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: totalBedsController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Total Beds Allocated',
                    border: const OutlineInputBorder(),
                    // Add a helper text for editing mode to clarify the available bed logic
                    helperText: partition != null
                        ? 'Available beds will be automatically adjusted if total beds is reduced.'
                        : null,
                  ),
                ),
                // Removed the 'Available Beds' TextField completely
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final String name = nameController.text.trim();
                final int? totalBeds = int.tryParse(totalBedsController.text);
                int? calculatedAvailableBeds;

                if (totalBeds == null || name.isEmpty || totalBeds < 0) {
                  // Basic validation
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Please enter a valid Partition Name and Total Beds (must be 0 or greater).',
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                if (partition == null) {
                  // ✅ New Partition: Available beds = Total beds
                  calculatedAvailableBeds = totalBeds;
                } else {
                  // ✅ Edit Partition:
                  // 1. If new total beds > current available beds, keep current available beds.
                  // 2. If new total beds <= current available beds, available beds must be reduced.
                  //    If the new total beds are less than the occupied beds (total - original available),
                  //    the available beds must be 0, otherwise it's (new total beds - occupied beds).
                  
                  final int occupiedBeds = totalBedsController.text ==
                          partition['total_beds'].toString()
                      ? (partition['total_beds'] - partition['available_beds'])
                      : (int.tryParse(partition['total_beds'].toString()) ?? 0) -
                          (int.tryParse(
                                  partition['available_beds'].toString()) ??
                              0);
                  
                  if (totalBeds >= originalAvailableBeds) {
                    // New total beds are greater than or equal to current available.
                    // This means the number of occupied beds hasn't changed, so available beds are recalculated:
                    calculatedAvailableBeds = totalBeds - occupiedBeds;
                  } else {
                    // New total beds are less than current available.
                    // We must ensure available beds is not negative.
                    // The minimum available beds is 0 if total beds <= occupied beds.
                    calculatedAvailableBeds = totalBeds > occupiedBeds
                        ? totalBeds - occupiedBeds
                        : 0;
                  }

                  // FINAL CHECK: Ensure available beds isn't greater than the new total beds.
                  calculatedAvailableBeds =
                      calculatedAvailableBeds > totalBeds ? totalBeds : calculatedAvailableBeds;
                }
                
                // Final safety check (shouldn't be needed with the logic above, but good practice)
                if (calculatedAvailableBeds <= totalBeds) {
                  final data = {
                    'partition_name': name,
                    'total_beds': totalBeds,
                    'available_beds': calculatedAvailableBeds,
                  };
                  if (partition == null) {
                    _addBedPartition(data);
                  } else {
                    _updateBedPartition(partition['id'], data);
                  }
                  Navigator.of(context).pop();
                } else {
                  // This block should ideally not be hit with the new logic, but serves as a failsafe.
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'An unexpected error occurred: calculated available beds exceeded total beds.',
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: Text(partition == null ? 'Add' : 'Save'),
            ),
          ],
        );
      },
    );
  }

  void _confirmDelete(int id, String partitionName) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirm Deletion'),
          content: Text(
            'Are you sure you want to delete the partition "$partitionName"? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteBedPartition(id);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _addBedPartition(Map<String, dynamic> data) async {
    final response = await _apiService.addBedPartition(data);
    if (response['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response['message'] ?? 'Partition added successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      _fetchBedPartitions();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response['message'] ?? 'Failed to add partition.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _updateBedPartition(int id, Map<String, dynamic> data) async {
    final response = await _apiService.updateBedPartition(id, data);
    if (response['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            response['message'] ?? 'Partition updated successfully!',
          ),
          backgroundColor: Colors.green,
        ),
      );
      _fetchBedPartitions();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response['message'] ?? 'Failed to update partition.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteBedPartition(int id) async {
    final response = await _apiService.deleteBedPartition(id);
    if (response['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            response['message'] ?? 'Partition deleted successfully!',
          ),
          backgroundColor: Colors.green,
        ),
      );
      _fetchBedPartitions();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response['message'] ?? 'Failed to delete partition.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Color _getAvailabilityColor(int available, int total) {
    if (total == 0) return Colors.grey;
    final percentage = available / total;
    if (percentage > 0.5) {
      return Colors.green;
    } else if (percentage > 0.2) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

   Widget _buildDetailsView(Map<String, dynamic> partition) {
    final int totalBeds = int.tryParse(partition['total_beds'].toString()) ?? 0;
    final int availableBeds =
        int.tryParse(partition['available_beds'].toString()) ?? 0;
    final int occupiedBeds = totalBeds - availableBeds;
    final double availabilityPercentage =
        totalBeds > 0 ? (availableBeds / totalBeds) : 0.0;
    final Color availabilityColor = _getAvailabilityColor(
      availableBeds,
      totalBeds,
    );

    return Scaffold(
      backgroundColor: const Color(
        0xFFFAFADD,
      ), // The background color you wanted
      appBar: AppBar(
        title: Text(partition['partition_name']),
        backgroundColor: const Color(
          0xFFFAFADD,
        ), // Added background color to the app bar
        elevation: 0, // Removes the shadow under the app bar
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            onPressed: () => _showPartitionDialog(partition: partition),
            icon: const Icon(Icons.edit),
            tooltip: 'Edit Bed Partition',
          ),
          IconButton(
            onPressed: () =>
                _confirmDelete(partition['id'], partition['partition_name']),
            icon: const Icon(Icons.delete),
            tooltip: 'Delete Bed Partition',
            color: Colors.red,
          ),
        ],
      ),
      body: SingleChildScrollView(
        // Keep this at 16.0
        padding: const EdgeInsets.all(16.0), 
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              color: const Color(
                0xFFBFD7FF,
              ), // Added background color to the container
              child: Padding(
                // Keep this at 16.0
                padding: const EdgeInsets.all(16.0), 
                child: Row(
                  children: [
                    // Percentage Indicator
                    CircularPercentIndicator(
                      // 1️⃣ Further reduced radius to 45.0
                      radius: 45.0, 
                      lineWidth: 7.0, // Slight reduction to line width
                      animation: true,
                      percent: availabilityPercentage,
                      center: Text(
                        '${(availabilityPercentage * 100).toInt()}%',
                        style: TextStyle(
                          // Reduced font size further
                          fontSize: 18, 
                          fontWeight: FontWeight.bold,
                          color: availabilityColor,
                        ),
                      ),
                      circularStrokeCap: CircularStrokeCap.round,
                      progressColor: availabilityColor,
                      backgroundColor: Colors.grey.shade200,
                    ),
                    // Keep this at 16.0
                    const SizedBox(width: 16), 
                    // Hospital Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildStatRow(
                            Icons.local_hospital,
                            'Total Beds',
                            totalBeds,
                            Colors.blue,
                          ),
                          _buildStatRow(
                            Icons.check_circle_outline,
                            'Available Beds',
                            availableBeds,
                            Colors.grey,
                          ),
                          _buildStatRow(
                            Icons.remove_circle_outline,
                            'Occupied Beds',
                            occupiedBeds,
                            Colors.red,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Bed Map',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: List.generate(totalBeds, (index) {
                Color bedColor = index < occupiedBeds
                    ? Colors.red
                    : Theme.of(context).primaryColor;
                return Tooltip(
                  message: index < occupiedBeds ? 'Occupied' : 'Available',
                  child: Icon(Icons.bed, color: bedColor, size: 40),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(IconData icon, String label, int value, Color color) {
    return Padding(
      // 2️⃣ Reduced vertical padding and removed horizontal padding
      padding: const EdgeInsets.symmetric(vertical: 4.0), 
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, size: 24, color: color),
              // Reduced horizontal space
              const SizedBox(width: 8), 
              Text(
                label,
                style: TextStyle(fontSize: 15, color: Colors.grey.shade800), // Slightly reduced font size
              ),
            ],
          ),
          Text(
            '$value',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold), // Reduced font size
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Check screen width to determine layout
    bool isWideScreen = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      backgroundColor: const Color(0xFFFAFADD), // Added background color
     appBar: AppBar(
  title: const Text('Bed and Wards Available'),
  elevation: 0,
  backgroundColor: const Color.fromARGB(255, 242, 184, 184), // Added background color here
  actions: [
    IconButton(
      onPressed: () => _showPartitionDialog(),
      icon: const Icon(Icons.add_box_outlined),
      tooltip: 'Add Bed Partition',
    ),
  ],
),

      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _bedPartitions.isEmpty
          ? _buildEmptyState()
          : isWideScreen
          ? _buildWideScreenLayout()
          : _buildNarrowScreenLayout(),
      floatingActionButton: !isWideScreen
          ? FloatingActionButton(
              onPressed: () => _showPartitionDialog(),
              backgroundColor: Theme.of(context).primaryColor,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.layers_clear, size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            const Text(
              'No Bed Partitions Found',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black54,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Press the plus icon to create your first bed partition.',
              style: TextStyle(fontSize: 16, color: Colors.black45),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWideScreenLayout() {
    return Row(
      children: [
        // Left-side list of wards
        Expanded(
          flex: 2,
          child: Container(
            color: const Color(
              0xFFBFD7FF,
            ), // Added background color to the left pane
            child: ListView.builder(
              itemCount: _bedPartitions.length,
              itemBuilder: (context, index) {
                final partition = _bedPartitions[index];
                final isSelected = _selectedIndex == index;
                final int totalBeds =
                    int.tryParse(partition['total_beds'].toString()) ?? 0;
                final int availableBeds =
                    int.tryParse(partition['available_beds'].toString()) ?? 0;
                final Color availabilityColor = _getAvailabilityColor(
                  availableBeds,
                  totalBeds,
                );

                return Container(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFFBFD7FF).withOpacity(
                            0.5,
                          ) // Applied BFD7FF color
                        : null,
                    border: isSelected
                        ? Border(
                            left: BorderSide(
                              color: Theme.of(context).primaryColor,
                              width: 4,
                            ),
                          )
                        : null,
                  ),
                  child: ListTile(
                    leading: Icon(
                      Icons.bed,
                      color: availabilityColor,
                    ), // Changed icon color
                    title: Text(
                      partition['partition_name'],
                      style: TextStyle(
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    subtitle: Text(
                      '$availableBeds / $totalBeds Beds Available',
                    ),
                    onTap: () {
                      setState(() {
                        _selectedIndex = index;
                      });
                    },
                  ),
                );
              },
            ),
          ),
        ),
        const VerticalDivider(width: 1, color: Colors.grey),
        // Right-side details and actions
        Expanded(
          flex: 3,
          child: _selectedIndex != null
              ? _buildDetailsView(_bedPartitions[_selectedIndex!])
              : const Center(child: Text('Select a partition to view details')),
        ),
      ],
    );
  }

  Widget _buildNarrowScreenLayout() {
    return ListView.builder(
      itemCount: _bedPartitions.length,
      itemBuilder: (context, index) {
        final partition = _bedPartitions[index];
        final int totalBeds =
            int.tryParse(partition['total_beds'].toString()) ?? 0;
        final int availableBeds =
            int.tryParse(partition['available_beds'].toString()) ?? 0;
        final Color availabilityColor = _getAvailabilityColor(
          availableBeds,
          totalBeds,
        );

        return Card(
          color: const Color(0xFFBFD7FF), // Applied BFD7FF color to the card
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          elevation: 2,
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            leading: Icon(
              Icons.bed,
              size: 40,
              color: availabilityColor,
            ), // Changed icon color
            title: Text(
              partition['partition_name'],
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              '$availableBeds available of $totalBeds beds',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => _buildDetailsView(partition),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
