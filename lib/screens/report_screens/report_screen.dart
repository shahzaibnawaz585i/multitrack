import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _IgnitionReportState();
}

class _IgnitionReportState extends State<ReportScreen> {
  final TextEditingController searchController = TextEditingController();

  int selectedIndex = 0;

  DateTime fromDate = DateTime.now();
  Future<void> _pickFromDate() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: fromDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2050),
    );

    if (pickedDate == null) return;

    TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(fromDate),
    );

    if (pickedTime == null) return;

    setState(() {
      fromDate = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
    });
  }

  Future<void> _pickEndDate() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: endDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2050),
    );

    if (pickedDate == null) return;

    TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(endDate),
    );

    if (pickedTime == null) return;

    setState(() {
      endDate = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
    });
  }
  void _changeFilter(int index) {
    setState(() {
      selectedIndex = index;

      DateTime now = DateTime.now();

      switch (index) {
        case 0:
          fromDate = DateTime(now.year, now.month, now.day);
          endDate = now;
          break;

        case 1:
          DateTime yesterday = now.subtract(const Duration(days: 1));

          fromDate = DateTime(
            yesterday.year,
            yesterday.month,
            yesterday.day,
          );

          endDate = DateTime(
            yesterday.year,
            yesterday.month,
            yesterday.day,
            23,
            59,
          );

          break;

        case 2:
          fromDate = now.subtract(const Duration(days: 7));
          endDate = now;
          break;

        case 3:
          fromDate = DateTime(now.year, now.month, 1);
          endDate = now;
          break;
      }
    });
  }
  DateTime endDate = DateTime.now();

  final List<String> filters = [
    "Today",
    "Yesterday",
    "Week",
    "Month",
  ];

  String formatDate(DateTime date) {
    return DateFormat("dd MMM yyyy  hh:mm a").format(date);
  }
  @override
  void initState() {
    super.initState();
    _changeFilter(0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff7f7f7),

      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        centerTitle: true,

        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Color(0xfff53d6b),
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),

        title: const Text(
          "Ignition Report",
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 28,
          ),
        ),

        actions: [
          PopupMenuButton(
            icon: const Icon(
              Icons.more_vert,
              color: Color(0xfff53d6b),
            ),
            itemBuilder: (context) => [],
          )
        ],
      ),

      body: Column(
        children: [

          const SizedBox(height: 15),

          /// Search Box
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              height: 55,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(35),
                border: Border.all(
                  color: Colors.black54,
                  width: 1,
                ),
              ),
              child: TextField(
                controller: searchController,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  prefixIcon: Icon(
                    Icons.search,
                    color: Color(0xfff53d6b),
                    size: 30,
                  ),
                  hintText: "Search Vehicle",
                ),
              ),
            ),
          ),

          const SizedBox(height: 18),

          /// Filters
          SizedBox(
            height: 45,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: filters.length,
              itemBuilder: (context, index) {
                bool selected = selectedIndex == index;

                return GestureDetector(
                  onTap: () {
                    _changeFilter(index);
                  },                  child: Container(
                  margin: const EdgeInsets.only(right: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  decoration: BoxDecoration(
                    color: selected
                        ? const Color(0xfff53d6b)
                        : const Color(0xffffd8df),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        blurRadius: 8,
                        color: Colors.black.withOpacity(.08),
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: Center(
                    child: Text(
                      filters[index],
                      style: TextStyle(
                        fontSize: 20,
                        color: selected
                            ? Colors.white
                            : Colors.red,
                      ),
                    ),
                  ),
                ),
                );
              },
            ),
          ),

          const SizedBox(height: 25),

          /// Dates
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Row(
              children: [

                Expanded(
                  child:
                  InkWell(
                    onTap: () {
                      _pickFromDate();
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),

                      child: Row(
                        children: [

                          const Icon(
                            Icons.calendar_month,
                            color: Color(0xfff53d6b),
                            size: 38,
                          ),

                          const SizedBox(width: 10),

                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [

                                const Text(
                                  "From Date",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),

                                const SizedBox(height: 3),

                                Text(
                                  formatDate(fromDate),
                                  style: const TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.w600,
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

                const SizedBox(width: 12),

                Expanded(
                  child: InkWell(
                    onTap: () {
                      _pickEndDate();
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(12),

                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),

                      child: Row(
                        children: [

                          const Icon(
                            Icons.calendar_month,
                            color: Color(0xfff53d6b),
                            size: 38,
                          ),

                          const SizedBox(width: 10),

                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [

                                const Text(
                                  "End Date",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),

                                const SizedBox(height: 3),

                                Text(
                                  formatDate(endDate),
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.w600,
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
          ),

          const Spacer(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Generate Report Clicked"),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xfff53d6b),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(
                  Icons.description,
                  color: Colors.white,
                ),
                label: const Text(
                  "Generate Report",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 25),

          const Icon(
            Icons.car_repair_outlined,
            size: 70,
            color: Colors.grey,
          ),

          const SizedBox(height: 15),

          const Text(
            "Ignition Report is not available",
            style: TextStyle(
              color: Color(0xfff53d6b),
              fontSize: 24,
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 120),
        ],
      ),
    );
  }
}