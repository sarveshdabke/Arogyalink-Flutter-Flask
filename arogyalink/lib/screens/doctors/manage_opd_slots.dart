// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:arogyalink/services/api_service.dart';

class ManageOPDSlotsScreen extends StatefulWidget {
  final String token; // logged-in doctor token
  const ManageOPDSlotsScreen({super.key, required this.token});

  @override
  State<ManageOPDSlotsScreen> createState() => _ManageOPDSlotsScreenState();
}

class _ManageOPDSlotsScreenState extends State<ManageOPDSlotsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<String> weekDates = [];
  Map<String, List<dynamic>> slotsByDate = {};
  bool loading = false;

  @override
  void initState() {
    super.initState();
    generateWeekDates();
    _tabController = TabController(length: weekDates.length, vsync: this);
    _tabController.addListener(() {
      fetchSlots(weekDates[_tabController.index]);
    });
    fetchSlots(weekDates[0]);
  }

  void generateWeekDates() {
    final today = DateTime.now();
    for (int i = 0; i < 7; i++) {
      final date = today.add(Duration(days: i));
      weekDates.add(date.toIso8601String().split('T')[0]); // YYYY-MM-DD
    }
  }

  Future<void> fetchSlots(String date) async {
    setState(() {
      loading = true;
    });
    try {
      final api = ApiService();
      final result = await api.getDoctorSlots(widget.token, date);
      setState(() {
        slotsByDate[date] = result;
        loading = false;
      });
    } catch (e) {
      setState(() {
        loading = false;
        slotsByDate[date] = [];
      });
      print("Error fetching slots: $e");
    }
  }

  Future<void> deleteSlot(int slotId) async {
    final api = ApiService();
    try {
      await api.deleteSlot(widget.token, slotId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Slot deleted successfully')),
      );
      fetchSlots(weekDates[_tabController.index]);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete slot: $e')),
      );
    }
  }

  Future<void> editSlot(Map<String, dynamic> slot) async {
    final startController = TextEditingController(text: slot['start_time']);
    final endController = TextEditingController(text: slot['end_time']);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Slot'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: startController,
              decoration:
                  const InputDecoration(labelText: 'Start Time (HH:MM)'),
            ),
            TextField(
              controller: endController,
              decoration:
                  const InputDecoration(labelText: 'End Time (HH:MM)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final api = ApiService();
              try {
                await api.editSlot(
                  widget.token,
                  slot['id'],
                  startController.text,
                  endController.text,
                );
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Slot updated successfully')),
                );
                fetchSlots(weekDates[_tabController.index]);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to update slot: $e')),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> addSlot() async {
    final dateController =
        TextEditingController(text: weekDates[_tabController.index]);
    final startController = TextEditingController();
    final endController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Slot'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: dateController,
              decoration:
                  const InputDecoration(labelText: 'Date (YYYY-MM-DD)'),
            ),
            TextField(
              controller: startController,
              decoration:
                  const InputDecoration(labelText: 'Start Time (HH:MM)'),
            ),
            TextField(
              controller: endController,
              decoration:
                  const InputDecoration(labelText: 'End Time (HH:MM)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final slotData = {
                "appointment_date": dateController.text,
                "start_time": startController.text,
                "end_time": endController.text,
              };
              try {
                await ApiService().createDoctorSlot(widget.token, slotData);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Slot created successfully')),
                );
                fetchSlots(dateController.text);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to create slot: $e')),
                );
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage OPD Slots'),
        backgroundColor: Colors.blueAccent,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: addSlot,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: weekDates
              .map(
                (date) => Tab(
                  text: date.split('-').sublist(1).join('-'),
                ),
              )
              .toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: weekDates.map((date) {
          final slots = slotsByDate[date] ?? [];
          if (loading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (slots.isEmpty) {
            return const Center(child: Text("No slots available"));
          }
          return ListView.builder(
            itemCount: slots.length,
            itemBuilder: (context, index) {
              final slot = slots[index];
              return ListTile(
                title: Text("${slot['start_time']} - ${slot['end_time']}"),
                subtitle: Text(
                  slot['is_booked']
                      ? "Booked"
                      : slot['is_available']
                          ? "Available"
                          : "Unavailable",
                  style: TextStyle(
                    color: slot['is_booked']
                        ? Colors.red
                        : slot['is_available']
                            ? Colors.green
                            : Colors.grey,
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () => editSlot(slot),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => deleteSlot(slot['id']),
                    ),
                  ],
                ),
              );
            },
          );
        }).toList(),
      ),
    );
  }
}
