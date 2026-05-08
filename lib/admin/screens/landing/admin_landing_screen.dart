import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';

class AdminLandingScreen extends StatelessWidget {
  const AdminLandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isWide = size.width > 800;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(color: Color(0xFFFAF4E8)),
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildNav(context),
              isWide
                  ? _buildHeroWide(context, size)
                  : _buildHeroNarrow(context),
              _buildMarquee(),
              _buildAbout(context, isWide),
              _buildFeatures(context, isWide),
              _buildStats(context, isWide),
              _buildFooter(context, isWide),
            ],
          ),
        ),
      ),
    );
  }

  // ── Navigation ────────────────────────────────────────────────────────────
  Widget _buildNav(BuildContext context) {
    return Container(
      color: const Color(0xFFFAF4E8),
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('RESTAURANT',
                  style: GoogleFonts.playfairDisplaySc(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 4,
                    color: const Color(0xFF5C1020),
                  )),
              Text('Staff & Admin Portal',
                  style: GoogleFonts.jost(
                    fontSize: 9,
                    letterSpacing: 5,
                    color: const Color(0xFFC09020),
                    fontWeight: FontWeight.w300,
                  )),
            ],
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => context.go('/admin/login'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
              color: const Color(0xFF5C1020),
              child: Text('ACCESS DASHBOARD',
                  style: GoogleFonts.jost(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 3,
                    color: const Color(0xFFFAF4E8),
                  )),
            ),
          ),
        ],
      ),
    );
  }

  // ── Hero Wide ──────────────────────────────────────────────────────────────
  Widget _buildHeroWide(BuildContext context, Size size) {
    return SizedBox(
      height: size.height,
      child: Row(
        children: [
          Expanded(
            child: Container(
              color: const Color(0xFFFAF4E8),
              padding: const EdgeInsets.fromLTRB(64, 0, 56, 64),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Container(
                        width: 36, height: 1, color: const Color(0xFF7B1D2A)),
                    const SizedBox(width: 10),
                    Text('STAFF & ADMIN PORTAL',
                        style: GoogleFonts.jost(
                            fontSize: 9,
                            letterSpacing: 5,
                            color: const Color(0xFF7B1D2A),
                            fontWeight: FontWeight.w500)),
                  ]),
                  const SizedBox(height: 16),
                  Text('RESTAURANT',
                      style: GoogleFonts.playfairDisplaySc(
                        fontSize: 72,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF5C1020),
                        letterSpacing: 4,
                        height: 0.9,
                      )).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2),
                  Text('MANAGEMENT',
                      style: GoogleFonts.playfairDisplaySc(
                        fontSize: 72,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF5C1020),
                        letterSpacing: 4,
                        height: 0.9,
                      )).animate().fadeIn(delay: 450.ms).slideY(begin: 0.2),
                  const SizedBox(height: 12),
                  Text('Fine Dining',
                      style: GoogleFonts.dmSerifDisplay(
                        fontSize: 32,
                        fontStyle: FontStyle.italic,
                        color: const Color(0xFFC09020),
                      )).animate().fadeIn(delay: 550.ms),
                  const SizedBox(height: 24),
                  _buildDividerRule(),
                  const SizedBox(height: 24),
                  Text('Operations Management System',
                      style: GoogleFonts.jost(
                        fontSize: 12,
                        letterSpacing: 4,
                        color: const Color(0xFF1A0A06).withValues(alpha: 0.5),
                        fontWeight: FontWeight.w300,
                      )).animate().fadeIn(delay: 700.ms),
                  const SizedBox(height: 36),
                  GestureDetector(
                    onTap: () => context.go('/admin/login'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 48, vertical: 18),
                      color: const Color(0xFF5C1020),
                      child: Text('ACCESS DASHBOARD',
                          style: GoogleFonts.jost(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 4,
                            color: const Color(0xFFFAF4E8),
                          )),
                    ).animate().fadeIn(delay: 900.ms),
                  ),
                  const SizedBox(height: 12),
                  Text('Authorised personnel only',
                      style: GoogleFonts.jost(
                        fontSize: 9,
                        letterSpacing: 4,
                        color: const Color(0xFF1A0A06).withValues(alpha: 0.3),
                        fontWeight: FontWeight.w300,
                      )),
                ],
              ),
            ),
          ),
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  'https://images.unsplash.com/photo-1414235077428-338989a2e8c0?w=1400&q=85',
                  fit: BoxFit.cover,
                ),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF5C1020).withValues(alpha: 0.2),
                        Colors.transparent,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 40,
                  right: 40,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 16),
                    color: const Color(0xFFFAF4E8),
                    child: Column(
                      children: [
                        Text('16',
                            style: GoogleFonts.playfairDisplaySc(
                              fontSize: 48,
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFF5C1020),
                            )),
                        Text('Years of\nExcellence',
                            style: GoogleFonts.jost(
                              fontSize: 10,
                              letterSpacing: 2,
                              color: const Color(0xFFC09020),
                            ),
                            textAlign: TextAlign.center),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Hero Narrow (mobile) ───────────────────────────────────────────────────
  Widget _buildHeroNarrow(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.92,
      color: const Color(0xFFFAF4E8),
      child: Stack(
        children: [
          Positioned.fill(
            child: Image.network(
              'https://images.unsplash.com/photo-1414235077428-338989a2e8c0?w=1400&q=85',
              fit: BoxFit.cover,
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  const Color(0xFF5C1020).withValues(alpha: 0.95),
                  const Color(0xFF5C1020).withValues(alpha: 0.3),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 60,
            left: 32,
            right: 32,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('RESTAURANT',
                    style: GoogleFonts.playfairDisplaySc(
                      fontSize: 40,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 2,
                      height: 1,
                    )),
                Text('MANAGEMENT',
                    style: GoogleFonts.playfairDisplaySc(
                      fontSize: 40,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 2,
                      height: 1,
                    )),
                const SizedBox(height: 8),
                Text('Fine Dining',
                    style: GoogleFonts.dmSerifDisplay(
                      fontSize: 22,
                      fontStyle: FontStyle.italic,
                      color: const Color(0xFFE0B840),
                    )),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => context.go('/admin/login'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFC09020),
                      foregroundColor: const Color(0xFF5C1020),
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.zero),
                    ),
                    child: Text('ACCESS DASHBOARD',
                        style: GoogleFonts.jost(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 3,
                        )),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Marquee ────────────────────────────────────────────────────────────────
  Widget _buildMarquee() {
    const items = [
      'Admin Panel',
      'Staff Portal',
      'Live Dashboard',
      'Table Control',
      'Order Management',
      'Analytics'
    ];
    return Container(
      color: const Color(0xFF5C1020),
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: items
              .expand((t) => [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(t,
                          style: GoogleFonts.jost(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 3,
                            color: const Color(0xFFFAF4E8),
                          )),
                    ),
                    const Text('✦',
                        style: TextStyle(
                            color: Color(0xFFC09020), fontSize: 10)),
                  ])
              .toList(),
        ),
      ),
    );
  }

  // ── About ──────────────────────────────────────────────────────────────────
  Widget _buildAbout(BuildContext context, bool isWide) {
    final stats = [
      ['50K+', 'Guests Served'],
      ['120+', 'Heritage Recipes'],
      ['14', 'Awards Won'],
      ['4.9★', 'Rating'],
    ];
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isWide ? 80 : 24, vertical: 80),
      child: isWide
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildAboutText(stats)),
                const SizedBox(width: 80),
                Expanded(child: _buildAboutImage()),
              ],
            )
          : Column(
              children: [
                _buildAboutText(stats),
                const SizedBox(height: 40),
                _buildAboutImage(),
              ],
            ),
    );
  }

  Widget _buildAboutText(List<List<String>> stats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('OUR RESTAURANT',
            style: GoogleFonts.jost(
              fontSize: 10,
              letterSpacing: 4,
              color: const Color(0xFF5C1020),
              fontWeight: FontWeight.w500,
            )),
        const SizedBox(height: 12),
        _buildDividerRule(),
        const SizedBox(height: 20),
        Text('Where Every Plate\nTells a Story',
            style: GoogleFonts.playfairDisplay(
              fontSize: 36,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1A0A06),
              height: 1.2,
            )),
        const SizedBox(height: 20),
        Text(
            'This portal puts every aspect of operations at your fingertips — '
            'live orders, staff, tables, and reports.',
            style: GoogleFonts.jost(
              fontSize: 14,
              color: const Color(0xFF1A0A06).withValues(alpha: 0.6),
              height: 1.7,
            )),
        const SizedBox(height: 32),
        Wrap(
          spacing: 24,
          runSpacing: 16,
          children: stats
              .map((s) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s[0],
                          style: GoogleFonts.playfairDisplaySc(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF5C1020),
                          )),
                      Text(s[1],
                          style: GoogleFonts.jost(
                            fontSize: 11,
                            letterSpacing: 2,
                            color: const Color(0xFF1A0A06).withValues(alpha: 0.5),
                          )),
                    ],
                  ))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildAboutImage() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: Image.network(
        'https://images.unsplash.com/photo-1552566626-52f8b828add9?w=800&q=80',
        height: 340,
        fit: BoxFit.cover,
        width: double.infinity,
      ),
    );
  }

  // ── Features ───────────────────────────────────────────────────────────────
  Widget _buildFeatures(BuildContext context, bool isWide) {
    const features = [
      ['📋', 'Order Management', 'Track every order live from one dashboard.'],
      ['🪑', 'Table Control', 'Visual floor plan with real-time availability.'],
      [
        '👨‍🍳',
        'Staff Scheduling',
        'Build rosters, manage shifts, track attendance.'
      ],
      [
        '📦',
        'Inventory Tracker',
        'Monitor stock levels, set alerts, reduce wastage.'
      ],
      [
        '📊',
        'Revenue Analytics',
        'Daily covers, revenue, top dishes, peak hours.'
      ],
      [
        '🔔',
        'Live Notifications',
        'Instant alerts for orders, stock and staff.'
      ],
    ];
    return Container(
      color: const Color(0xFF5C1020).withValues(alpha: 0.03),
      padding: EdgeInsets.symmetric(horizontal: isWide ? 80 : 24, vertical: 80),
      child: Column(
        children: [
          Text('DASHBOARD FEATURES',
              style: GoogleFonts.jost(
                fontSize: 10,
                letterSpacing: 4,
                color: const Color(0xFF5C1020),
              )),
          const SizedBox(height: 12),
          _buildDividerRule(),
          const SizedBox(height: 16),
          Text('Everything You Need\nto Run the Show',
              style: GoogleFonts.playfairDisplay(
                fontSize: 32,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1A0A06),
                height: 1.2,
              ),
              textAlign: TextAlign.center),
          const SizedBox(height: 48),
          LayoutBuilder(builder: (ctx, c) {
            final cols = c.maxWidth > 700
                ? 3
                : c.maxWidth > 480
                    ? 2
                    : 1;
            return Wrap(
              spacing: 24,
              runSpacing: 24,
              children: features.asMap().entries.map((e) {
                final idx = e.key;
                final f = e.value;
                final w = (c.maxWidth - (cols - 1) * 24) / cols;
                return SizedBox(
                  width: w,
                  child: Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(
                          color: const Color(0xFF5C1020).withValues(alpha: 0.08)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('0${idx + 1}',
                            style: GoogleFonts.playfairDisplaySc(
                              fontSize: 48,
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFF5C1020).withValues(alpha: 0.06),
                              height: 1,
                            )),
                        Text(f[0], style: const TextStyle(fontSize: 36)),
                        const SizedBox(height: 12),
                        Text(f[1],
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1A0A06),
                            )),
                        const SizedBox(height: 8),
                        Text(f[2],
                            style: GoogleFonts.jost(
                              fontSize: 13,
                              color: const Color(0xFF1A0A06).withValues(alpha: 0.55),
                              height: 1.6,
                            )),
                      ],
                    ),
                  ).animate().fadeIn(delay: (idx * 100).ms),
                );
              }).toList(),
            );
          }),
        ],
      ),
    );
  }

  // ── Stats ──────────────────────────────────────────────────────────────────
  Widget _buildStats(BuildContext context, bool isWide) {
    const stats = [
      ['📋', '1,240+', 'Orders Managed'],
      ['🪑', '48', 'Tables Tracked'],
      ['👨‍🍳', '36', 'Staff Members'],
      ['⭐', '4.9', 'Guest Rating'],
    ];
    return Container(
      color: const Color(0xFF5C1020),
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 32),
      child: LayoutBuilder(builder: (ctx, c) {
        final cols = c.maxWidth > 700 ? 4 : 2;
        return Wrap(
          spacing: 0,
          runSpacing: 0,
          children: stats.map((s) {
            final w = c.maxWidth / cols;
            return SizedBox(
              width: w,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Text(s[0], style: const TextStyle(fontSize: 32)),
                    const SizedBox(height: 12),
                    Text(s[1],
                        style: GoogleFonts.playfairDisplaySc(
                          fontSize: 36,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFFE0B840),
                        )),
                    const SizedBox(height: 4),
                    Text(s[2],
                        style: GoogleFonts.jost(
                          fontSize: 11,
                          letterSpacing: 2,
                          color: const Color(0xFFFAF4E8).withValues(alpha: 0.6),
                        ),
                        textAlign: TextAlign.center),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      }),
    );
  }

  // ── Footer ─────────────────────────────────────────────────────────────────
  Widget _buildFooter(BuildContext context, bool isWide) {
    return Container(
      color: const Color(0xFF1A0A06),
      padding: EdgeInsets.symmetric(horizontal: isWide ? 80 : 24, vertical: 60),
      child: Column(
        children: [
          if (isWide)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildFooterBrand()),
                const SizedBox(width: 60),
                _buildFooterLinks(context),
              ],
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildFooterBrand(),
                const SizedBox(height: 40),
                _buildFooterLinks(context),
              ],
            ),
          const SizedBox(height: 40),
          Divider(color: Colors.white.withValues(alpha: 0.1)),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('© ${DateTime.now().year} Restaurant. All rights reserved.',
                  style: GoogleFonts.jost(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.3),
                  )),
              Text('Admin Portal',
                  style: GoogleFonts.jost(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.3),
                  )),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFooterBrand() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('RESTAURANT',
            style: GoogleFonts.playfairDisplaySc(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: const Color(0xFFC09020),
              letterSpacing: 3,
            )),
        const SizedBox(height: 12),
        Text(
            'Internal management portal.\nFor access issues contact your system administrator.',
            style: GoogleFonts.jost(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.4),
              height: 1.7,
            )),
      ],
    );
  }

  Widget _buildFooterLinks(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('NAVIGATE',
            style: GoogleFonts.jost(
              fontSize: 10,
              letterSpacing: 3,
              fontWeight: FontWeight.w600,
              color: const Color(0xFFC09020),
            )),
        const SizedBox(height: 16),
        ...['Dashboard Login'].map((l) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GestureDetector(
                onTap: () => context.go('/admin/login'),
                child: Text(l,
                    style: GoogleFonts.jost(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.5),
                    )),
              ),
            )),
      ],
    );
  }

  // ── Shared ─────────────────────────────────────────────────────────────────
  Widget _buildDividerRule() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 40, height: 1, color: const Color(0xFFC09020)),
        const SizedBox(width: 10),
        Container(
            width: 6,
            height: 6,
            color: const Color(0xFFC09020),
            transform: Matrix4.rotationZ(0.785)),
        const SizedBox(width: 10),
        Container(width: 40, height: 1, color: const Color(0xFFC09020)),
      ],
    );
  }
}


