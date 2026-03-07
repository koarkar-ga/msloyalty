import 'package:flutter/material.dart';
import 'package:msloyalty/Screens/FiFoPointScreen.dart';
import 'package:msloyalty/Screens/RewardScreen.dart';
import 'package:msloyalty/Screens/home_screen.dart';
import 'package:msloyalty/Screens/notification_screen.dart';
import 'package:msloyalty/Screens/profile_screen.dart';

void main() {
  runApp(const LoyaltyApp());
}

class LoyaltyApp extends StatelessWidget {
  const LoyaltyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.purple,
        useMaterial3: true,
      ),
      home: const MainNavigationScreen(),
    );
  }
}

// MARK: - Main Navigation Controller
class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  // ပြသချင်တဲ့ Screen စာရင်းများ
  final List<Widget> _screens = [
    const HomeScreen(),
    const RewardScreen(),
    const FifoPointsPage(),
    const NotificationScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: _screens[_currentIndex], // ရွေးချယ်ထားတဲ့ index အလိုက် screen ပြပေးမယ်
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Colors.white10, width: 0.5)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index; // နှိပ်လိုက်တဲ့ index ကို state မှာ သိမ်းမယ်
            });
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: const Color(0xFF1E1E1E),
          selectedItemColor: Colors.red,
          unselectedItemColor: Colors.grey,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
            BottomNavigationBarItem(icon: Icon(Icons.card_giftcard), label: "Reward"),
            BottomNavigationBarItem(icon: Icon(Icons.data_array), label: "Points"),
            BottomNavigationBarItem(icon: Icon(Icons.notifications_none), label: "Notification"),
            BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: "Profile"),
          ],
        ),
      ),
    );
  }
}

// MARK: - Home Screen
// class HomeScreen extends StatelessWidget {
//   const HomeScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return SafeArea(
//       child: SingleChildScrollView(
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // Header Section
//             Padding(
//               padding: const EdgeInsets.all(20.0),
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: const [
//                       Text("Hi! Welcome Back", style: TextStyle(color: Colors.grey, fontSize: 14)),
//                       SizedBox(height: 4),
//                       Text(
//                         "Aung Htet Win",
//                         style: TextStyle(
//                           color: Colors.white,
//                           fontSize: 24,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                       Text(
//                         "3,370 Shopping Points",
//                         style: TextStyle(color: Colors.grey, fontSize: 14),
//                       ),
//                     ],
//                   ),
//                   _buildNotificationBadge(),
//                 ],
//               ),
//             ),

//             // Membership Card
//             _buildMembershipCard(),

//             // Action Buttons Row
//             Padding(
//               padding: const EdgeInsets.all(20),
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   _buildActionItem(Icons.add_circle_outline, "Top-up"),
//                   _buildActionItem(Icons.qr_code_scanner, "QR"),
//                   _buildActionItem(Icons.send, "Transfer"),
//                   _buildActionItem(Icons.receipt_long, "Invoices"),
//                 ],
//               ),
//             ),

//             // Featured Rewards Section
//             const Padding(
//               padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
//               child: Text(
//                 "Featured Reward",
//                 style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
//               ),
//             ),

//             SizedBox(
//               height: 200,
//               child: ListView(
//                 scrollDirection: Axis.horizontal,
//                 padding: const EdgeInsets.only(left: 20),
//                 children: [
//                   _buildRewardCard(
//                     context,
//                     "Victoria Hospital",
//                     "31 Dec 2026",
//                     "https://via.placeholder.com/300x150/4CAF50/FFFFFF?text=Victoria",
//                   ),
//                   _buildRewardCard(
//                     context,
//                     "Power House Gym",
//                     "31 Dec 2026",
//                     "https://via.placeholder.com/300x150/FFC107/000000?text=Gym",
//                   ),
//                 ],
//               ),
//             ),
//             const SizedBox(height: 20),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildNotificationBadge() {
//     return Container(
//       padding: const EdgeInsets.all(10),
//       decoration: BoxDecoration(
//         color: Colors.white.withOpacity(0.1),
//         borderRadius: BorderRadius.circular(15),
//       ),
//       child: const Stack(
//         children: [
//           Icon(Icons.notifications_none, color: Colors.white, size: 28),
//           Positioned(right: 0, top: 0, child: CircleAvatar(radius: 5, backgroundColor: Colors.red)),
//         ],
//       ),
//     );
//   }

//   Widget _buildMembershipCard() {
//     return Container(
//       margin: const EdgeInsets.symmetric(horizontal: 20),
//       height: 180,
//       width: double.infinity,
//       decoration: BoxDecoration(
//         gradient: const LinearGradient(colors: [Color(0xFF9C27B0), Color(0xFFE91E63)]),
//         borderRadius: BorderRadius.circular(25),
//       ),
//       child: Padding(
//         padding: const EdgeInsets.all(25.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//           children: const [
//             Text(
//               "CLASSIC",
//               style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900),
//             ),
//             Text(
//               "3,370 CLUB SCORES",
//               style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold),
//             ),
//             Text(
//               "Keep shopping to earn more points!",
//               style: TextStyle(color: Colors.white, fontSize: 12),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildActionItem(IconData icon, String label) {
//     return Column(
//       children: [
//         Container(
//           padding: const EdgeInsets.all(15),
//           decoration: BoxDecoration(
//             color: const Color(0xFF1E1E1E),
//             borderRadius: BorderRadius.circular(15),
//           ),
//           child: Icon(icon, color: Colors.purpleAccent, size: 28),
//         ),
//         const SizedBox(height: 8),
//         Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
//       ],
//     );
//   }

//   Widget _buildRewardCard(BuildContext context, String title, String date, String imgUrl) {
//     return GestureDetector(
//       onTap: () => Navigator.push(
//         context,
//         MaterialPageRoute(builder: (_) => RewardDetailScreen(title: title)),
//       ),
//       child: Container(
//         width: 250,
//         margin: const EdgeInsets.only(right: 15),
//         decoration: BoxDecoration(
//           color: const Color(0xFF1E1E1E),
//           borderRadius: BorderRadius.circular(20),
//         ),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             ClipRRect(
//               borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
//               child: Image.network(imgUrl, height: 120, width: double.infinity, fit: BoxFit.cover),
//             ),
//             Padding(
//               padding: const EdgeInsets.all(12.0),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     title,
//                     style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
//                   ),
//                   Text("Expire: $date", style: const TextStyle(color: Colors.grey, fontSize: 12)),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// MARK: - Reward List Screen (စာရင်းကြည့်ရန် Screen အသစ်)
class RewardListScreen extends StatelessWidget {
  const RewardListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text("All Rewards", style: TextStyle(color: Colors.white)),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: 5,
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.only(bottom: 15),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(15),
            ),
            child: ListTile(
              leading: const Icon(Icons.card_giftcard, color: Colors.purpleAccent, size: 40),
              title: Text(
                "Special Offer ${index + 1}",
                style: const TextStyle(color: Colors.white),
              ),
              subtitle: const Text("Valid until Dec 2026", style: TextStyle(color: Colors.grey)),
              trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white24, size: 16),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RewardDetailScreen(title: "Special Offer")),
              ),
            ),
          );
        },
      ),
    );
  }
}

// MARK: - Reward Detail Screen
class RewardDetailScreen extends StatelessWidget {
  final String title;
  const RewardDetailScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Detail", style: TextStyle(color: Colors.black)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            const Text("Description goes here...", style: TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
