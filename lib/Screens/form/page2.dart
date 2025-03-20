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
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header - reduced flex and added explicit padding
              Padding(
                padding: const EdgeInsets.only(top: 20.0, bottom: 10.0),
                child: RichText(
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
              ),

              // Mileage Display
              SizedBox(
                height: 120, // Fixed height
                child: Center(
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
              ),

              const SizedBox(height: 50), // Add spacing

              // Camera Button - fixed height container
              SizedBox(
                height: 80, // Fixed height
                child: GestureDetector(
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
                          width: 40,
                          height: 40,
                        ),
                        const SizedBox(width: 15),
                        Column(
                          mainAxisSize: MainAxisSize.min,
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
              ),

              const SizedBox(height: 50), // Add spacing

              // Fuel Status Header
              Padding(
                padding: const EdgeInsets.only(bottom: 20.0),
                child: RichText(
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
              ),

              // Fuel Status Selection - increased fixed height
              SizedBox(
                height: 80, // Increased height from 60 to 80
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

              // Spacer to push button to bottom
              const Spacer(),

              // Next Button
              Container(
                height: 100, // Fixed height
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
        // Wrap in Flexible to handle potential overflow
        children: [
          Flexible(
            child: _buildFuelStatusButton("Full tank", true),
          ),
          const SizedBox(width: 12), // Reduced spacing to prevent overflow
          Flexible(
            child: _buildFuelStatusButton("Refuel needed", false),
          ),
        ],
      );
    } else {
      return _buildFuelStatusButton(
          isFullTank! ? "Full tank" : "Refuel needed", isFullTank!);
    }
  }

  Widget _buildFuelStatusButton(String text, bool value) {
    final isSelected = isFullTank == value;

    // Define colors based on selection and button type
    final Color iconColor = value
        ? const Color(0xFF20b24d) // Green for full tank
        : Colors.amber; // Amber for refuel needed

    final Color borderColor = value
        ? const Color(0xFF20b24d) // Green border for full tank
        : Colors.amber; // Amber border for refuel needed

    final Color bgColor = isSelected
        ? Colors.black
            .withOpacity(0.7) // Slightly transparent black when selected
        : Colors.grey.shade900; // Default background

    // Button icon based on type
    final IconData buttonIcon = value
        ? Icons.local_gas_station_rounded // Gas station icon for full tank
        : Icons.warning_amber_rounded; // Warning icon for refuel needed

    return GestureDetector(
      onTap: () => _handleFuelStatusTap(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        // Adjust padding to be slightly smaller to fix overflow
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
        decoration: BoxDecoration(
          color: bgColor,
          gradient: isSelected
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    value
                        ? const Color(0xFF1a8538).withOpacity(0.3)
                        : Colors.amber.shade700.withOpacity(0.3),
                    bgColor,
                  ],
                )
              : null,
          borderRadius: BorderRadius.circular(25), // Increased border radius
          border: Border.all(
            color: isSelected ? borderColor : Colors.transparent,
            width: isSelected ? 2.5 : 0, // Slightly thicker border
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: borderColor.withOpacity(0.5),
                blurRadius: 10, // Increased blur
                spreadRadius: 2, // Increased spread
              ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              buttonIcon,
              color: iconColor,
              size: 22, // Slightly reduced icon size
            ),
            const SizedBox(width: 8), // Reduced spacing
            // Add constraints to text to handle overflow
            Flexible(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 15, // Slightly reduced font size
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: Colors.white,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
