import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:carousel_slider_plus/carousel_slider_plus.dart';

class PromoBannerSlider extends StatefulWidget {
  const PromoBannerSlider({super.key});

  @override
  State<PromoBannerSlider> createState() => _PromoBannerSliderState();
}

class _PromoBannerSliderState extends State<PromoBannerSlider> {
  final supabase = Supabase.instance.client;
  List<String> bannerImages = [];
  bool isLoading = true;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _fetchBanners();
  }

  Future<void> _fetchBanners() async {
    try {
      final data = await supabase
          .from('banners')
          .select('image_url')
          .eq('is_active', true);

      setState(() {
        bannerImages = List<String>.from(data.map((item) => item['image_url']));
        isLoading = false;
      });
    } catch (e) {
      debugPrint("Banner Fetch Error: $e");
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Container(
        height: 120,
        margin: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(15),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (bannerImages.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        CarouselSlider(
          options: CarouselOptions(
            height: 120.0,
            autoPlay: true, // အလိုအလျောက် ပတ်ပြမည်
            enlargeCenterPage: true, // အလယ်ပုံကို ပိုကြီးပြမည်
            viewportFraction: 0.9,
            aspectRatio: 16 / 9,
            onPageChanged: (index, reason) {
              setState(() => _currentIndex = index);
            },
          ),
          items: bannerImages.map((imageUrl) {
            return Builder(
              builder: (BuildContext context) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        color: Colors.grey[200],
                        child: const Center(child: CircularProgressIndicator()),
                      );
                    },
                  ),
                );
              },
            );
          }).toList(),
        ),

        // Dot Indicator လေးများ
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: bannerImages.asMap().entries.map((entry) {
            return Container(
              width: _currentIndex == entry.key ? 18.0 : 8.0,
              height: 8.0,
              margin: const EdgeInsets.symmetric(horizontal: 4.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color:
                    (Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : const Color(0xFF1B4F72))
                        .withOpacity(_currentIndex == entry.key ? 0.9 : 0.2),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
