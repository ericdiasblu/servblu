import 'package:flutter/material.dart';

class BuildHeaderWithTabs extends StatefulWidget {
  final String title;
  final bool backPage;
  final GestureTapCallback? onTap;
  final List<String> tabs;
  final Function(int) onTabChanged;
  final int currentTabIndex;

  const BuildHeaderWithTabs({
    super.key,
    required this.title,
    required this.backPage,
    this.onTap,
    required this.tabs,
    required this.onTabChanged,
    required this.currentTabIndex,
  });

  @override
  State<BuildHeaderWithTabs> createState() => _BuildHeaderWithTabsState();
}

class _BuildHeaderWithTabsState extends State<BuildHeaderWithTabs> {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).padding.top + 120, // Aumente um pouco para acomodar as tabs
      width: double.infinity,
      decoration: BoxDecoration(
        color: Color(0xFF017DFE),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                if (widget.backPage)
                  Positioned(
                    left: 16,
                    child: GestureDetector(
                      onTap: widget.onTap,
                      child: Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                      ),
                    ),
                  ),
                Text(
                  widget.title,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Tabs para alternar entre "Minhas Solicitações" e "Minhas Ofertas"
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 50),
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: List.generate(
                  widget.tabs.length,
                      (index) => Expanded(
                    child: GestureDetector(
                      onTap: () => widget.onTabChanged(index),
                      child: Container(
                        decoration: BoxDecoration(
                          color: widget.currentTabIndex == index
                              ? Colors.white
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Center(
                          child: Text(
                            widget.tabs[index],
                            style: TextStyle(
                              color: widget.currentTabIndex == index
                                  ? Color(0xFF017DFE)
                                  : Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}