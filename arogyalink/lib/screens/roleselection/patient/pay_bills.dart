// pay_bills.dart

// ignore_for_file: prefer_const_constructors, use_build_context_synchronously

import 'package:arogyalink/screens/roleselection/patient/hospitalize_paybill.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:arogyalink/services/api_service.dart';
import 'package:url_launcher/url_launcher.dart';

class PayBillsScreen extends StatefulWidget {
  const PayBillsScreen({super.key});

  @override
  State<PayBillsScreen> createState() => _PayBillsScreenState();
}

class _PayBillsScreenState extends State<PayBillsScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  List<dynamic> _bills = [];
  String? _message;

  List<dynamic> unpaidBills = [];
  List<dynamic> paidBills = [];

  int _unseenHospitalBills = 0;

  @override
  void initState() {
    super.initState();
    _fetchBills();
    _loadUnseenHospitalBills();
  }

  Future<void> _loadUnseenHospitalBills() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _unseenHospitalBills = prefs.getInt('unseen_hospital_bills') ?? 0;
    });
  }

  Future<void> _fetchBills() async {
    setState(() {
      _isLoading = true;
      unpaidBills = [];
      paidBills = [];
      _bills = [];
      _message = null;
    });

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');

    if (token == null) {
      setState(() {
        _message = "User not logged in.";
        _isLoading = false;
      });
      return;
    }

    try {
      final result = await ApiService().fetchBillReport(token);
      final List<dynamic> fetchedBills = result['data'] ?? [];
      _bills = fetchedBills;

      if (result.containsKey("message") && fetchedBills.isEmpty) {
        _message = result["message"];
      }

      // Filter unpaid / paid bills
      unpaidBills = fetchedBills.where((b) =>
          b['bill_paid'] == 0 || b['bill_paid'] == false || b['bill_paid'] == null).toList();

      paidBills = fetchedBills.where((b) =>
          b['bill_paid'] == 1 || b['bill_paid'] == true).toList();

      // Calculate unseen hospitalization bills
      int unseenCount = unpaidBills.where((b) => b['is_seen_by_patient'] == false).length;
      prefs.setInt('unseen_hospital_bills', unseenCount);

      setState(() {
        _unseenHospitalBills = unseenCount;
      });

    } catch (e) {
      setState(() {
        _message = "Error fetching bills: $e";
        _bills = [];
      });
    } finally {
      setState(() {
        _isLoading = false;
        if (_bills.isEmpty && _message == null) {
          _message = "No bills to show";
        }
      });
    }
  }

  Future<void> _payBill(dynamic bill, String paymentMode) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    if (token == null) return;

    try {
      final result = await ApiService().payBill(token, bill['id'], paymentMode);

      if (result['success'] == true) {
        if (paymentMode == "upi" && result.containsKey("upi_info")) {
          final upiId = result['upi_info']['upi_id'];
          final amount = result['upi_info']['amount'];
          final note = Uri.encodeComponent(result['upi_info']['note'] ?? "Hospital Payment");

          final url = Uri.parse(
              "upi://pay?pa=$upiId&pn=$note&tn=$note&am=$amount&cu=INR");

          if (await canLaunchUrl(url)) {
            await launchUrl(url, mode: LaunchMode.externalApplication);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text(
                      "No UPI app found. Please install Google Pay, PhonePe, or Paytm.")),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Payment successful!")),
          );
          _fetchBills();
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Payment failed: ${result['message']}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Payment error: $e")),
      );
    }
  }

  Future<void> _markBillAsSeen(int billId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    if (token == null) return;

    bool success = await ApiService().markBillAsSeen(billId, token);
    if (success) {
      // Refresh unseen count
      _fetchBills();
    }
  }

  Widget _buildBillCard(Map<String, dynamic> bill) {
    bool isPaid = bill['bill_paid'] == 1 || bill['bill_paid'] == true;

    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Hospital: ${bill['hospital_name'] ?? 'N/A'}",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text("Doctor: ${bill['doctor_name'] ?? 'N/A'}"),
            const SizedBox(height: 4),
            Text("Appointment Date: ${bill['appointment_date']}"),
            const SizedBox(height: 4),
            Text("Visiting Fee: ₹${bill['visiting_fee'] ?? 0}"),
            Text("Checkup Fee: ₹${bill['checkup_fee'] ?? 0}"),
            Text("Tax Percent: ${bill['tax_percent'] ?? 0}%"),
            const Divider(),
            Text(
              "Total Amount: ₹${bill['total_amount'] ?? 0}",
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green),
            ),
            const SizedBox(height: 8),

            // Mark bill as seen when user opens it
            if (!isPaid && bill['is_seen_by_patient'] == false)
              ElevatedButton(
                onPressed: () async {
                  await _markBillAsSeen(bill['id']);
                },
                child: const Text("Mark as Seen"),
              ),

            if (!isPaid)
              ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text("Select Payment Mode"),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ListTile(
                            leading: Icon(Icons.money),
                            title: Text("Cash"),
                            onTap: () {
                              Navigator.pop(context);
                              _payBill(bill, "cash");
                            },
                          ),
                          ListTile(
                            leading: Icon(Icons.account_balance_wallet),
                            title: Text("UPI"),
                            onTap: () {
                              Navigator.pop(context);
                              _payBill(bill, "upi");
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
                child: const Text("Pay Now"),
              )
            else
              ElevatedButton(
                onPressed: null,
                child: const Text("Paid"),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            "Pay Bills",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: const Color.fromARGB(255, 50, 91, 143),
          actions: [
            Stack(
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.bed_outlined,
                    color: Colors.white,
                  ),
                  tooltip: "Hospitalization Bills",
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const HospitalizePayBillScreen(),
                      ),
                    );
                    _loadUnseenHospitalBills(); // Refresh badge after returning
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
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: "Unpaid"),
              Tab(text: "Paid"),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : (_bills.isEmpty && _message != null)
                ? Center(
                    child: Text(
                      _message!,
                      style: const TextStyle(fontSize: 16),
                    ),
                  )
                : TabBarView(
                    children: [
                      RefreshIndicator(
                        onRefresh: _fetchBills,
                        child: ListView.builder(
                          itemCount: unpaidBills.length,
                          itemBuilder: (context, index) {
                            return _buildBillCard(unpaidBills[index]);
                          },
                        ),
                      ),
                      RefreshIndicator(
                        onRefresh: _fetchBills,
                        child: ListView.builder(
                          itemCount: paidBills.length,
                          itemBuilder: (context, index) {
                            return _buildBillCard(paidBills[index]);
                          },
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }
}
