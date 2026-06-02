import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../constants.dart';

class FileInfoCard extends StatelessWidget {
  const FileInfoCard({
    Key? key,
    this.svgSrc,
    this.title,
    this.totalStorage,
    this.numOfFiles,
    this.color,
  }) : super(key: key);

  final dynamic svgSrc;
  final dynamic title;
  final dynamic totalStorage;
  final dynamic numOfFiles;
  final dynamic color;

  @override
  Widget build(BuildContext context) {
    // Calculate the percentage dynamically based on the number of files and total storage
    int percentage = (numOfFiles / totalStorage * 100).toInt();
    percentage = percentage > 100 ? 100 : percentage;  // Ensure it doesn't exceed 100%

    return Container(
      padding: EdgeInsets.all(defaultPadding),
      height: 180,
      decoration: BoxDecoration(
        color: secondaryColor,
        borderRadius: const BorderRadius.all(Radius.circular(10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: EdgeInsets.all(defaultPadding * 0.75),
                height: 40,
                width: 40,
                decoration: BoxDecoration(
                  color: color!.withOpacity(0.1),
                  borderRadius: const BorderRadius.all(Radius.circular(10)),
                ),
                child: SvgPicture.asset(
                  svgSrc!,
                  colorFilter: ColorFilter.mode(
                      color ?? Colors.black, BlendMode.srcIn),
                ),
              ),
            ],
          ),

 
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
          Text(
            title!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
                        Text(
                numOfFiles.toString(),
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium!
                    .copyWith(color: Colors.white70),
              ),
            ],

          ),
                   ProgressLine(
            color: color,
            percentage: percentage,
          ),
        ],
      ),
    );
  }
}

class ProgressLine extends StatelessWidget {
  const ProgressLine({
    Key? key,
    this.color = Colors.blue,
    required this.percentage,
  }) : super(key: key);

  final Color? color;
  final int percentage;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: double.infinity,
          height: 5,
          decoration: BoxDecoration(
            color: color!.withOpacity(0.1),
            borderRadius: BorderRadius.all(Radius.circular(10)),
          ),
        ),
        LayoutBuilder(
          builder: (context, constraints) => Container(
            width: constraints.maxWidth * (percentage / 100),
            height: 5,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.all(Radius.circular(10)),
            ),
          ),
        ),
      ],
    );
  }
}
