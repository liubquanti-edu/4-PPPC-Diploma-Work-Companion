import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class RegionAlertMapScreen extends StatelessWidget {
  final String region;
  
  const RegionAlertMapScreen({
    Key? key, 
    required this.region,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Тривога'),
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
                      'Полтавська область',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SvgPicture.asset(
                          'assets/svg/PoltavaRegion.svg',
                          colorFilter: ColorFilter.mode(
                            Theme.of(context).colorScheme.primary.withOpacity(0.3),
                            BlendMode.srcIn,
                          ),
                          height: MediaQuery.of(context).size.height * 0.5,
                        ),
                        SvgPicture.asset(
                          'assets/svg/PoltavaRegionLogo.svg',
                          colorFilter: ColorFilter.mode(
                            Theme.of(context).colorScheme.primary.withOpacity(0.7),
                            BlendMode.srcIn,
                          ),
                          height: MediaQuery.of(context).size.height * 0.5,
                        ),
                        SvgPicture.asset(
                          'assets/svg/PoltavaRegionBorder.svg',
                          colorFilter: ColorFilter.mode(
                            Theme.of(context).colorScheme.primary,
                            BlendMode.srcIn,
                          ),
                          height: MediaQuery.of(context).size.height * 0.5,
                        ),
                      ],
                    ),
                    Text(
                      'Тривога відсутня',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Небезпека: Відсутня',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
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
}