import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E12),
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            backgroundColor: const Color(0xFF0A0E12),
            elevation: 0,
            pinned: true,
            expandedHeight: 80,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0xFF0A0E12),
                      const Color(0xFF0A0E12).withOpacity(0.8),
                    ],
                  ),
                ),
              ),
            ),
            title: Row(
              children: [
                Icon(
                  Icons.shield,
                  color: const Color(0xFFD13639),
                  size: 32,
                ),
                const SizedBox(width: 12),
                const Text(
                  'RIOT',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {},
                child: const Text(
                  'GAMES',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {},
                child: const Text(
                  'NEWS',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {},
                child: const Text(
                  'CAREERS',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.person_outline, color: Colors.white),
                onPressed: () {},
              ),
              const SizedBox(width: 8),
            ],
          ),

          // Hero Section
          SliverToBoxAdapter(
            child: Container(
              height: 600,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF1A1F2E),
                    const Color(0xFF0A0E12),
                  ],
                ),
              ),
              child: Stack(
                children: [
                  // Background pattern
                  Positioned.fill(
                    child: Opacity(
                      opacity: 0.1,
                      child: CustomPaint(
                        painter: GridPainter(),
                      ),
                    ),
                  ),
                  // Content
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Large hero icon
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              color: const Color(0xFFD13639).withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.sports_esports,
                              size: 60,
                              color: Color(0xFFD13639),
                            ),
                          ),
                          const SizedBox(height: 40),
                          const Text(
                            'WE ARE RIOT GAMES',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 56,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                              height: 1.2,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'Creating the most player-focused games in the world',
                            style: TextStyle(
                              color: Color(0xFF9CA3AF),
                              fontSize: 20,
                              letterSpacing: 0.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 48),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ElevatedButton(
                                onPressed: () {},
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFD13639),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 40,
                                    vertical: 20,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                                child: const Text(
                                  'EXPLORE GAMES',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              OutlinedButton(
                                onPressed: () {},
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  side: const BorderSide(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 40,
                                    vertical: 20,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                                child: const Text(
                                  'LEARN MORE',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Games Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'OUR GAMES',
                    style: TextStyle(
                      color: Color(0xFFD13639),
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Built for Players',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 40),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 3,
                    mainAxisSpacing: 24,
                    crossAxisSpacing: 24,
                    childAspectRatio: 1.2,
                    children: [
                      _buildGameCard(
                        'VALORANT',
                        'Tactical Shooter',
                        Icons.gps_fixed,
                        const Color(0xFFFF4655),
                      ),
                      _buildGameCard(
                        'LEAGUE OF LEGENDS',
                        'MOBA',
                        Icons.flash_on,
                        const Color(0xFF0AC8B9),
                      ),
                      _buildGameCard(
                        'TEAMFIGHT TACTICS',
                        'Strategy',
                        Icons.extension,
                        const Color(0xFFD13639),
                      ),
                      _buildGameCard(
                        'LEGENDS OF RUNETERRA',
                        'Card Game',
                        Icons.style,
                        const Color(0xFF1F8EFA),
                      ),
                      _buildGameCard(
                        'WILD RIFT',
                        'Mobile MOBA',
                        Icons.phone_android,
                        const Color(0xFF32C8FF),
                      ),
                      _buildGameCard(
                        'COMING SOON',
                        'New Experience',
                        Icons.rocket_launch,
                        const Color(0xFF9CA3AF),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // News Section
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
              padding: const EdgeInsets.all(60),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF1A1F2E),
                    const Color(0xFF0F1419),
                  ],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'LATEST NEWS',
                    style: TextStyle(
                      color: Color(0xFFD13639),
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Stay Updated',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 40),
                  Row(
                    children: [
                      Expanded(
                        child: _buildNewsCard(
                          'New Season Launch',
                          'Experience the latest updates and features',
                          'May 13, 2026',
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: _buildNewsCard(
                          'Championship Finals',
                          'Watch the best teams compete for glory',
                          'May 10, 2026',
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: _buildNewsCard(
                          'Developer Update',
                          'Behind the scenes with our team',
                          'May 8, 2026',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Footer
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.all(40),
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: Color(0xFF1C1C1F),
                    width: 1,
                  ),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.shield,
                        color: const Color(0xFFD13639),
                        size: 32,
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'RIOT GAMES',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 32,
                    runSpacing: 16,
                    children: [
                      _buildFooterLink('Press'),
                      _buildFooterLink('Security'),
                      _buildFooterLink('Legal'),
                      _buildFooterLink('Leadership'),
                      _buildFooterLink('Candidate Privacy'),
                      _buildFooterLink('Terms of Service'),
                      _buildFooterLink('Privacy Notice'),
                      _buildFooterLink('Player Support'),
                    ],
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    '© 2026 Riot Games, Inc. All Rights Reserved.',
                    style: TextStyle(
                      color: Color(0xFF6B7280),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameCard(String title, String subtitle, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1F),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFF2C2C2F),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    size: 40,
                    color: color,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFF9CA3AF),
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNewsCard(String title, String description, String date) {
    return Container(
      height: 280,
      decoration: BoxDecoration(
        color: const Color(0xFF0A0E12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFF2C2C2F),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD13639).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Icon(
                    Icons.article_outlined,
                    color: Color(0xFFD13639),
                    size: 24,
                  ),
                ),
                const Spacer(),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  description,
                  style: const TextStyle(
                    color: Color(0xFF9CA3AF),
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
                const Spacer(),
                Text(
                  date,
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFooterLink(String text) {
    return InkWell(
      onTap: () {},
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF9CA3AF),
          fontSize: 14,
        ),
      ),
    );
  }
}

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..strokeWidth = 1;

    const spacing = 40.0;

    // Draw vertical lines
    for (double i = 0; i < size.width; i += spacing) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i, size.height),
        paint,
      );
    }

    // Draw horizontal lines
    for (double i = 0; i < size.height; i += spacing) {
      canvas.drawLine(
        Offset(0, i),
        Offset(size.width, i),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
