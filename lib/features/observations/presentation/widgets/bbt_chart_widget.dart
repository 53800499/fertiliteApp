import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/observation_models.dart';

class BbtChartWidget extends StatefulWidget {
  final BbtAnalysisModel analysis;
  final VoidCallback? onAddTemperature;

  const BbtChartWidget({
    super.key,
    required this.analysis,
    this.onAddTemperature,
  });

  @override
  State<BbtChartWidget> createState() => _BbtChartWidgetState();
}

class _BbtChartWidgetState extends State<BbtChartWidget> {
  int? _selectedIndex;

  @override
  Widget build(BuildContext context) {
    final analysis = widget.analysis;
    final points = analysis.points;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // En-tête : Titre & Badge de confirmation biphasique
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: analysis.shiftDetected
                      ? Colors.teal.withValues(alpha: 0.12)
                      : AppTheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  analysis.shiftDetected
                      ? Icons.auto_graph_rounded
                      : Icons.show_chart_rounded,
                  color: analysis.shiftDetected ? Colors.teal : AppTheme.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        const Text(
                          'Courbe Thermique',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textDark,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: analysis.shiftDetected
                                ? Colors.teal.withValues(alpha: 0.12)
                                : AppTheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Symptothermie',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: analysis.shiftDetected
                                  ? Colors.teal.shade800
                                  : AppTheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      analysis.shiftDetected
                          ? 'Décalage post-ovulatoire confirmé (+${analysis.shiftDeltaCelsius ?? 0.3} °C)'
                          : analysis.statusBadgeLabel,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: analysis.shiftDetected
                            ? Colors.teal.shade700
                            : AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Cartes de métriques cliniques clés
          Row(
            children: [
              Expanded(
                child: _buildMetricMiniCard(
                  label: 'Plateau Bas',
                  value: analysis.follicularAvgCelsius != null
                      ? '${analysis.follicularAvgCelsius!.toStringAsFixed(2)} °C'
                      : '--',
                  subtitle: 'Phase folliculaire',
                  color: AppTheme.primary,
                  icon: Icons.waves_rounded,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildMetricMiniCard(
                  label: 'Plateau Haut',
                  value: analysis.lutealAvgCelsius != null
                      ? '${analysis.lutealAvgCelsius!.toStringAsFixed(2)} °C'
                      : '--',
                  subtitle: 'Phase lutéale',
                  color: Colors.teal,
                  icon: Icons.trending_up_rounded,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildMetricMiniCard(
                  label: 'Coverline',
                  value: analysis.coverlineCelsius != null
                      ? '${analysis.coverlineCelsius!.toStringAsFixed(2)} °C'
                      : '--',
                  subtitle: 'Ligne de base',
                  color: Colors.amber.shade800,
                  icon: Icons.horizontal_rule_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Zone Graphique CustomPaint Interactive
          if (points.isEmpty)
            _buildEmptyChartState()
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Légende interactive
                Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _buildLegendItem(
                      color: AppTheme.primary,
                      label: 'T°C Basale',
                      isCircle: true,
                    ),
                    if (analysis.coverlineCelsius != null)
                      _buildLegendItem(
                        color: Colors.amber.shade700,
                        label: 'Coverline (Roetzer)',
                        isDashed: true,
                      ),
                    if (analysis.shiftDetected)
                      _buildLegendItem(
                        color: Colors.teal,
                        label: 'Plateau haut (+0.2°C)',
                        isCircle: true,
                      ),
                    _buildLegendItem(
                      color: Colors.orange,
                      label: 'Mesure perturbée',
                      isWarning: true,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Tooltip interactif au survol/toucher
                if (_selectedIndex != null &&
                    _selectedIndex! >= 0 &&
                    _selectedIndex! < points.length)
                  _buildInteractiveTooltip(points[_selectedIndex!]),

                const SizedBox(height: 10),

                // Canvas Graphique
                SizedBox(
                  height: 220,
                  child: GestureDetector(
                    onHorizontalDragUpdate: (details) {
                      _handleTouch(details.localPosition, points);
                    },
                    onTapDown: (details) {
                      _handleTouch(details.localPosition, points);
                    },
                    child: CustomPaint(
                      painter: _BbtPainter(
                        points: points,
                        coverline: analysis.coverlineCelsius,
                        selectedIndex: _selectedIndex,
                      ),
                      size: const Size(double.infinity, 220),
                    ),
                  ),
                ),
              ],
            ),

          const SizedBox(height: 18),

          // Message pédagogique & médical
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: analysis.shiftDetected
                  ? Colors.teal.withValues(alpha: 0.08)
                  : AppTheme.background,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: analysis.shiftDetected
                    ? Colors.teal.withValues(alpha: 0.25)
                    : AppTheme.borderLight,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  analysis.shiftDetected
                      ? Icons.check_circle_outline_rounded
                      : Icons.info_outline_rounded,
                  color: analysis.shiftDetected ? Colors.teal : AppTheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    analysis.message,
                    style: const TextStyle(
                      fontSize: 12.5,
                      height: 1.4,
                      color: AppTheme.textDark,
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

  void _handleTouch(Offset localPosition, List<BbtPointModel> points) {
    if (points.isEmpty) return;
    final availableWidth = context.size?.width ?? 320;
    const paddingLeft = 46.0;
    const paddingRight = 16.0;
    final chartWidth = availableWidth - paddingLeft - paddingRight;

    if (localPosition.dx < paddingLeft ||
        localPosition.dx > availableWidth - paddingRight) {
      return;
    }

    final step = chartWidth / math.max(1, points.length - 1);
    final relativeX = localPosition.dx - paddingLeft;
    final index = (relativeX / step).round().clamp(0, points.length - 1);

    if (index != _selectedIndex) {
      HapticFeedback.selectionClick();
      setState(() => _selectedIndex = index);
    }
  }

  Widget _buildMetricMiniCard({
    required String label,
    required String value,
    required String subtitle,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 10,
              color: AppTheme.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInteractiveTooltip(BbtPointModel point) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.textDark,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: point.phase == 'luteal' ? Colors.teal : AppTheme.primary,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.thermostat_rounded,
              color: Colors.white,
              size: 14,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 6,
                  runSpacing: 2,
                  children: [
                    Text(
                      'Jour ${point.cycleDay} (${point.date})',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (point.heurePrise != null)
                      Text(
                        'à ${point.heurePrise}',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 11,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 3),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    Text(
                      '${point.temperatureCelsius.toStringAsFixed(2)} °C',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      point.phase == 'luteal'
                          ? 'Plateau haut (Lutéal)'
                          : 'Plateau bas (Folliculaire)',
                      style: TextStyle(
                        color: point.phase == 'luteal'
                            ? Colors.tealAccent
                            : Colors.purple.shade100,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (point.estPerturbee)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Perturbée',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem({
    required Color color,
    required String label,
    bool isCircle = false,
    bool isDashed = false,
    bool isWarning = false,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isWarning)
          Icon(Icons.warning_amber_rounded, size: 14, color: color)
        else if (isDashed)
          Container(
            width: 16,
            height: 2,
            color: color,
          )
        else if (isCircle)
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppTheme.textMuted,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyChartState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.thermostat_auto_rounded,
              size: 32,
              color: AppTheme.primary,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Aucune mesure thermique enregistrée',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Prenez votre température le matin au réveil avant de vous lever pour tracer votre courbe biphasique.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textMuted,
              height: 1.3,
            ),
          ),
          if (widget.onAddTemperature != null) ...[
            const SizedBox(height: 16),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: widget.onAddTemperature,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Noter ma température'),
            ),
          ],
        ],
      ),
    );
  }
}

/// CustomPainter traçant la courbe continue, les phases et la coverline
class _BbtPainter extends CustomPainter {
  final List<BbtPointModel> points;
  final double? coverline;
  final int? selectedIndex;

  _BbtPainter({
    required this.points,
    this.coverline,
    this.selectedIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    const paddingLeft = 44.0;
    const paddingBottom = 28.0;
    const paddingTop = 16.0;
    const paddingRight = 16.0;

    final width = size.width - paddingLeft - paddingRight;
    final height = size.height - paddingTop - paddingBottom;

    // Plage d'échelle de température fixe et physiologique (36.00 °C à 37.40 °C)
    double minTemp = 36.00;
    double maxTemp = 37.30;

    for (final p in points) {
      if (p.temperatureCelsius < minTemp) minTemp = math.max(35.5, p.temperatureCelsius - 0.1);
      if (p.temperatureCelsius > maxTemp) maxTemp = math.min(38.5, p.temperatureCelsius + 0.1);
    }
    if (coverline != null) {
      if (coverline! < minTemp) minTemp = coverline! - 0.1;
      if (coverline! > maxTemp) maxTemp = coverline! + 0.1;
    }

    double getY(double temp) {
      final ratio = (temp - minTemp) / (maxTemp - minTemp);
      return paddingTop + height - (ratio * height);
    }

    double getX(int index) {
      if (points.length <= 1) return paddingLeft + (width / 2);
      return paddingLeft + (index * (width / (points.length - 1)));
    }

    // 1. Grille horizontale & labels d'échelle (°C)
    final gridPaint = Paint()
      ..color = AppTheme.borderLight
      ..strokeWidth = 1.0;

    final textStyle = const TextStyle(
      fontSize: 10,
      color: AppTheme.textMuted,
      fontWeight: FontWeight.w600,
    );

    const stepCelsius = 0.20;
    final startGrid = (minTemp * 5).ceil() / 5.0;
    for (double t = startGrid; t <= maxTemp; t += stepCelsius) {
      final y = getY(t);
      canvas.drawLine(
        Offset(paddingLeft, y),
        Offset(size.width - paddingRight, y),
        gridPaint,
      );

      final tp = TextPainter(
        text: TextSpan(
          text: '${t.toStringAsFixed(1)}°',
          style: textStyle,
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(paddingLeft - tp.width - 6, y - (tp.height / 2)));
    }

    // 2. Coverline (Ligne horizontale dorée pointillée)
    if (coverline != null) {
      final coverlineY = getY(coverline!);
      final coverlinePaint = Paint()
        ..color = Colors.amber.shade700
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke;

      // Dessin en tirets
      const dashWidth = 5.0;
      const dashSpace = 4.0;
      double currentX = paddingLeft;
      while (currentX < size.width - paddingRight) {
        canvas.drawLine(
          Offset(currentX, coverlineY),
          Offset(math.min(currentX + dashWidth, size.width - paddingRight), coverlineY),
          coverlinePaint,
        );
        currentX += dashWidth + dashSpace;
      }

      // Badge texte Coverline
      final coverlineTp = TextPainter(
        text: TextSpan(
          text: 'Coverline ${coverline!.toStringAsFixed(2)}°C',
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.bold,
            color: Colors.amber.shade900,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      coverlineTp.paint(canvas, Offset(size.width - paddingRight - coverlineTp.width, coverlineY - coverlineTp.height - 2));
    }

    // 3. Remplissage dégradé sous la courbe
    final fillPath = Path();
    fillPath.moveTo(getX(0), paddingTop + height);
    for (int i = 0; i < points.length; i++) {
      fillPath.lineTo(getX(i), getY(points[i].temperatureCelsius));
    }
    fillPath.lineTo(getX(points.length - 1), paddingTop + height);
    fillPath.close();

    final fillGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        AppTheme.primary.withValues(alpha: 0.18),
        AppTheme.primary.withValues(alpha: 0.01),
      ],
    );
    final fillPaint = Paint()
      ..shader = fillGradient.createShader(
        Rect.fromLTWH(paddingLeft, paddingTop, width, height),
      );
    canvas.drawPath(fillPath, fillPaint);

    // 4. Tracé continu de la ligne de température
    final linePath = Path();
    for (int i = 0; i < points.length; i++) {
      final x = getX(i);
      final y = getY(points[i].temperatureCelsius);
      if (i == 0) {
        linePath.moveTo(x, y);
      } else {
        // Courbe lissée naturelle
        final prevX = getX(i - 1);
        final prevY = getY(points[i - 1].temperatureCelsius);
        final controlX1 = prevX + (x - prevX) / 2;
        final controlX2 = prevX + (x - prevX) / 2;
        linePath.cubicTo(controlX1, prevY, controlX2, y, x, y);
      }
    }

    final linePaint = Paint()
      ..shader = const LinearGradient(
        colors: [AppTheme.primary, AppTheme.accentRose, Colors.teal],
      ).createShader(Rect.fromLTWH(paddingLeft, paddingTop, width, height))
      ..strokeWidth = 2.8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(linePath, linePaint);

    // 5. Points et marqueurs journaliers
    for (int i = 0; i < points.length; i++) {
      final p = points[i];
      final x = getX(i);
      final y = getY(p.temperatureCelsius);
      final isSelected = selectedIndex == i;

      Color pointColor = p.phase == 'luteal' ? Colors.teal : AppTheme.primary;
      if (p.estPerturbee) pointColor = Colors.orange;

      // Halo pour le point sélectionné
      if (isSelected) {
        final selectPaint = Paint()
          ..color = pointColor.withValues(alpha: 0.25)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(Offset(x, y), 10, selectPaint);

        // Ligne verticale de repère
        final crosshairPaint = Paint()
          ..color = pointColor.withValues(alpha: 0.5)
          ..strokeWidth = 1.2
          ..style = PaintingStyle.stroke;
        canvas.drawLine(
          Offset(x, paddingTop),
          Offset(x, paddingTop + height),
          crosshairPaint,
        );
      }

      // Point central
      final dotPaint = Paint()
        ..color = pointColor
        ..style = PaintingStyle.fill;
      final borderPaint = Paint()
        ..color = Colors.white
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke;

      canvas.drawCircle(Offset(x, y), isSelected ? 5.5 : 4.0, dotPaint);
      canvas.drawCircle(Offset(x, y), isSelected ? 5.5 : 4.0, borderPaint);

      // Label X (Jour de cycle J1, J2...)
      final dayLabel = 'J${p.cycleDay}';
      final dayTp = TextPainter(
        text: TextSpan(
          text: dayLabel,
          style: TextStyle(
            fontSize: 9,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? AppTheme.primary : AppTheme.textMuted,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      dayTp.paint(canvas, Offset(x - (dayTp.width / 2), paddingTop + height + 6));
    }
  }

  @override
  bool shouldRepaint(covariant _BbtPainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.coverline != coverline ||
        oldDelegate.selectedIndex != selectedIndex;
  }
}
