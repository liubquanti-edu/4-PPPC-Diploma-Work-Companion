import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '/providers/alert_provider.dart';

class FadedWidget extends StatelessWidget {
  final Widget child;
  final List<double> stops;
  final List<Color> colorsForStops;

  FadedWidget({
    super.key,
    required this.child,
    this.stops = const [0.9, 0.95, 1.0],
    List<double> opacities = const [1, 0.5, 0],
  }) : colorsForStops = opacities
            .map((double opacity) => Colors.black.withOpacity(opacity))
            .toList();

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (rect) {
        return LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          stops: stops,
          colors: colorsForStops,
        ).createShader(Rect.fromLTRB(0, 0, rect.width, rect.height));
      },
      blendMode: BlendMode.dstIn,
      child: ShaderMask(
        shaderCallback: (rect) {
          return LinearGradient(
            begin: Alignment.centerRight,
            end: Alignment.centerLeft,
            stops: stops,
            colors: colorsForStops,
          ).createShader(Rect.fromLTRB(0, 0, rect.width, rect.height));
        },
        blendMode: BlendMode.dstIn,
        child: ShaderMask(
          shaderCallback: (rect) {
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              stops: stops,
              colors: colorsForStops,
            ).createShader(Rect.fromLTRB(0, 0, rect.width, rect.height));
          },
          blendMode: BlendMode.dstIn,
          child: ShaderMask(
            shaderCallback: (rect) {
              return LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: stops,
                colors: colorsForStops,
              ).createShader(Rect.fromLTRB(0, 0, rect.width, rect.height));
            },
            blendMode: BlendMode.dstIn,
            child: child,
          ),
        ),
      ),
    );
  }
}

class RegionAlertMapScreen extends StatelessWidget {
  final String region;
  
  const RegionAlertMapScreen({
    Key? key, 
    required this.region,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<AlertProvider>(
      builder: (context, alertProvider, _) {
        final bool isAlert = alertProvider.alertInfo.status == 'A';
        final Color mapColor = isAlert 
            ? Colors.red.shade400
            : Theme.of(context).colorScheme.primary;
        
        return Scaffold(
          appBar: AppBar(
            title: const Text('Статус тривоги'),
            centerTitle: true,
          ),
          body: Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Text(
                          isAlert ? 'Повітряна тривога!' : 'Тривога відсутня',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: mapColor,
                            fontWeight: isAlert ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Container(
                          width: double.infinity,
                          constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.9,
                          ),
                          child: AspectRatio(
                          aspectRatio: 1.2,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                            FadedWidget(
                              stops: const [0.85, 0.95, 1.0],
                              child: SvgPicture.asset(
                              'assets/svg/PoltavaRegionBordersOther.svg',
                              colorFilter: ColorFilter.mode(
                                mapColor.withOpacity(0.7),
                                BlendMode.srcIn,
                              ),
                              fit: BoxFit.contain,
                              ),
                            ),
                            SvgPicture.asset(
                              'assets/svg/PoltavaRegion.svg',
                              colorFilter: ColorFilter.mode(
                              mapColor.withOpacity(0.3),
                              BlendMode.srcIn,
                              ),
                              fit: BoxFit.contain,
                            ),
                            if (!isAlert)
                              SvgPicture.asset(
                              'assets/svg/PoltavaRegionLogo.svg',
                              colorFilter: ColorFilter.mode(
                                mapColor.withOpacity(0.7),
                                BlendMode.srcIn,
                              ),
                              fit: BoxFit.contain,
                              width: MediaQuery.of(context).size.width * 0.7,
                              ),
                            if (isAlert)
                              SvgPicture.asset(
                              'assets/svg/PoltavaRegionCities.svg',
                              colorFilter: ColorFilter.mode(
                                mapColor.withOpacity(0.7),
                                BlendMode.srcIn,
                              ),
                              fit: BoxFit.contain,
                              ),
                            SvgPicture.asset(
                              'assets/svg/PoltavaRegionBorder.svg',
                              colorFilter: ColorFilter.mode(
                              mapColor,
                              BlendMode.srcIn,
                              ),
                              fit: BoxFit.contain,
                            ),
                            ],
                          ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        if (isAlert && alertProvider.alertInfo.startTime != null)
                          Column(
                            children: [
                              Text(
                                'Початок: ${DateFormat('HH:mm').format(alertProvider.alertInfo.startTime!.toLocal())}',
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: mapColor,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                'Тривалість: ${_formatDuration(DateTime.now().difference(alertProvider.alertInfo.startTime!))}',
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: mapColor,
                                ),
                              ),
                            ],
                          )
                        else
                          Text(
                            'Небезпека: Відсутня',
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: mapColor,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }
    );
  }
  
  String _formatDuration(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays}д ${duration.inHours.remainder(24)}г ${duration.inMinutes.remainder(60)}хв';
    } else if (duration.inHours > 0) {
      return '${duration.inHours}г ${duration.inMinutes.remainder(60)}хв';
    } else {
      return '${duration.inMinutes}хв';
    }
  }
}