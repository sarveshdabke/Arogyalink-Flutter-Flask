// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:arogyalink/services/api_service.dart';

class HospitalizePayBillScreen extends StatefulWidget {
  const HospitalizePayBillScreen({super.key});

  @override
  State<HospitalizePayBillScreen> createState() =>
      _HospitalizePayBillScreenState();
}

class _HospitalizePayBillScreenState extends State<HospitalizePayBillScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  List<dynamic> _bills = [];
  late TabController _tabController;
  int _unseenHospitalBills = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchHospitalizationBills();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchHospitalizationBills() async {
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');

    if (token == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final result = await ApiService().fetchHospitalizationBills(token);
      _bills = result['data'] ?? [];

      // Count unseen bills for badge
int unseenCount = _bills.where((b) =>
    b['status'] == 'Unpaid' || b['is_seen_by_patient'] == false
).length;
      prefs.setInt('unseen_hospital_bills', unseenCount);
      setState(() => _unseenHospitalBills = unseenCount);
    } catch (e) {
      // Optional: show error
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _markBillAsSeen(int billId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    if (token == null) return;

    bool success = await ApiService().markBillAsSeen(billId, token);
    if (success) {
      _fetchHospitalizationBills(); // refresh list & badge
    }
  }

  void _showPaymentDialog(Map<String, dynamic> bill) {
    String? paymentMode;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: StatefulBuilder(
          builder: (context, setModalState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Select Payment Method",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 20),
                DropdownButtonFormField<String>(
                  initialValue: paymentMode,
                  hint: const Text("Choose Payment Mode"),
                  items: const [
                    DropdownMenuItem(value: "cash", child: Text("Cash")),
                    DropdownMenuItem(value: "upi", child: Text("UPI")),
                  ],
                  onChanged: (value) {
                    setModalState(() => paymentMode = value);
                  },
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  icon: const Icon(Icons.check_circle_outline),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0A8F13),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 45),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: paymentMode == null
                      ? null
                      : () async {
                          Navigator.pop(context);
                          await _handlePayment(bill['id'], paymentMode!);
                        },
                  label: const Text("Confirm Payment"),
                ),
                const SizedBox(height: 20),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _handlePayment(int billId, String paymentMode) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    if (token == null) return;

    try {
      final result =
          await ApiService().payHospitalizationBill(token, billId, paymentMode);

      if (result['success'] == true) {
        // Mark bill as seen after payment
        await _markBillAsSeen(billId);

        if (paymentMode == 'cash') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    result['message'] ?? "Please visit hospital for payment.")),
          );
        } else if (paymentMode == 'upi' && result['upi_info'] != null) {
          final upiInfo = result['upi_info'];
          final upiUrl =
              "upi://pay?pa=${upiInfo['upi_id']}&pn=${Uri.encodeComponent(upiInfo['note'])}&am=${upiInfo['amount']}&cu=INR";
          await launchUrl(Uri.parse(upiUrl),
              mode: LaunchMode.externalApplication);
        }

        _fetchHospitalizationBills();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? "Payment failed")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  Widget _buildBillCard(Map<String, dynamic> bill) {
    bool isPaid = bill['status'] == 'Paid';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Bill No: ${bill['bill_number']}",
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(
              "Admission Date: ${bill['admission_date']?.split('T').first ?? 'N/A'}",
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            Text("Discharge: ${bill['discharge_date']}"),
            Text("Total Days: ${bill['total_days']}"),
            const Divider(),
            Text("Room Charges: ₹${bill['room_charges']}"),
            Text("Treatment Charges: ₹${bill['treatment_charges']}"),
            Text("Doctor Fees: ₹${bill['doctor_fees']}"),
            Text("Medicine Charges: ₹${bill['medicine_charges']}"),
            Text("Misc Charges: ₹${bill['misc_charges']}"),
            const Divider(),
            Text(
              "Net Payable: ₹${bill['net_payable']}",
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Status: ${bill['status']}",
                  style: TextStyle(
                    color: isPaid ? Colors.green : Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (!isPaid)
                  ElevatedButton(
                    onPressed: () {
                      _markBillAsSeen(bill['id']);
                      _showPaymentDialog(bill);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0A8F13),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text("Pay Bill"),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    List<dynamic> unpaidBills =
        _bills.where((b) => b['status'] == 'Unpaid').toList();
    List<dynamic> paidBills = _bills.where((b) => b['status'] == 'Paid').toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Hospitalization Bills",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF0A8F13),
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: "Unpaid"),
            Tab(text: "Paid"),
          ],
        ),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(
                  Icons.bed_outlined,
                  color: Colors.white,
                ),
                tooltip: "Hospitalization Bills",
                onPressed: () {
                  _fetchHospitalizationBills();
                },
              ),
              if (_unseenHospitalBills > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$_unseenHospitalBills',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildBillList(unpaidBills, "No unpaid bills found"),
                _buildBillList(paidBills, "No paid bills found"),
              ],
            ),
    );
  }

  Widget _buildBillList(List<dynamic> bills, String emptyMessage) {
    if (bills.isEmpty) return Center(child: Text(emptyMessage));
    return RefreshIndicator(
      onRefresh: _fetchHospitalizationBills,
      child: ListView.builder(
        itemCount: bills.length,
        itemBuilder: (context, index) => _buildBillCard(bills[index]),
      ),
    );
  }
}
