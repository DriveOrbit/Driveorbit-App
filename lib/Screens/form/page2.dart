import 'package:flutter/material.dart';
import 'package:driveorbit_app/screens/vehicle_dasboard/map_page.dart'; // Import map page

class MileageForm extends StatefulWidget {
  const MileageForm({super.key});

  @override
  _MileageFormState createState() => _MileageFormState();
}

class _MileageFormState extends State<MileageForm>
    with SingleTickerProviderStateMixin {
  TextEditingController mileageController = TextEditingController();
  bool? isFullTank;
  bool get isFormValid =>
      mileageController.text.trim().isNotEmpty && isFullTank != null;
  late AnimationController _animationController;
  late Animation<Alignment> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _animation = AlignmentTween(
      begin: Alignment.center,
      end: Alignment.center,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleFuelStatusTap(bool value) {
    setState(() {
      if (isFullTank == value) {
        isFullTank = null;
        _animationController.reverse();
      } else {
        isFullTank = value;
        final startAlignment =
            value ? Alignment.centerLeft : Alignment.centerRight;
        _animation = AlignmentTween(
          begin: startAlignment,
          end: Alignment.center,
        ).animate(CurvedAnimation(
          parent: _animationController,
          curve: Curves.easeInOut,
        ));
        _animationController.forward(from: 0);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 70.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              RichText(
                text: const TextSpan(
                  children: [
                    TextSpan(
                      text: "Enter your ",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF6D6BF8),
                      ),
                    ),
                    TextSpan(
                      text: "current\nmileage",
                      style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF54C1D5)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // Mileage Display
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: mileageController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        hintText: "190 868",
                        hintStyle: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade600,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                      onChanged: (value) => setState(() {}),
                    ),
                    const Align(
                      alignment: Alignment.center,
                      child: Text(
                        "KM",
                        style: TextStyle(
                          fontSize: 24,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 90),

              // Camera Button
              GestureDetector(
                onTap: () {/* Add camera logic */},
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/icons/Camera.png',
                        width: 60,
                      ),
                      const SizedBox(width: 15),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Take a photo of dashboard",
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black),
                          ),
                          Text(
                            "Please take a clear photo",
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 80),

              // Fuel Status Header
              RichText(
                text: const TextSpan(
                  children: [
                    TextSpan(
                      text: "What is your ",
                      style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF6D6BF8)),
                    ),
                    TextSpan(
                      text: "current fuel\nstatus",
                      style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF54C1D5)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Fuel Status Selection
              SizedBox(
                height: 80, // Fixed height for fuel status area
                child: AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return Align(
                      alignment: _animation.value,
                      child: _buildFuelStatusOptions(),
                    );
                  },
                ),
              ),

              const SizedBox(height: 100),

              // Next Button
              Align(
                alignment: Alignment.center,
                child: SizedBox(
                  width: 80,
                  height: 80,
                  child: IconButton(
                    onPressed: isFormValid
                        ? () {
                            // Navigate to Map page when form is complete
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const MapPage(),
                              ),
                            );
                          }
                        : null,
                    icon: Image.asset(
                      'assets/icons/Back.png',
                      width: 60,
                      color: isFormValid
                          ? Colors.white // Active icon color
                          : Colors.grey, // Disabled icon color
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFuelStatusOptions() {
    if (isFullTank == null) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildFuelStatusButton("Full tank", true),
          const SizedBox(width: 15),
          _buildFuelStatusButton("Refuel needed", false),
        ],
      );
    } else {
      return _buildFuelStatusButton(
          isFullTank! ? "Full tank" : "Refuel needed", isFullTank!);
    }
  }

  Widget _buildFuelStatusButton(String text, bool value) {
    final isSelected = isFullTank == value;
    return GestureDetector(
      onTap: () => _handleFuelStatusTap(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 24),
        decoration: BoxDecoration(
          color: Colors.grey.shade900,
          borderRadius: BorderRadius.circular(20),
          border: isSelected
              ? Border.all(color: const Color(0xFF6D6BF8), width: 2)
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.water_drop,
              color:
                  isSelected ? const Color(0xFF20b24d) : Colors.yellow.shade600,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
