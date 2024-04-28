import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:smart_activities/data/entities/activity.dart';
import 'package:smart_activities/presentation/blocs/activity_bloc.dart';
import 'package:smart_activities/presentation/blocs/activity_event.dart';
import 'package:smart_activities/presentation/formatters/activity_formatter.dart';

class PlayingActivityCard extends StatefulWidget {
  final Activity activity;
  const PlayingActivityCard({super.key, required this.activity});

  @override
  State<PlayingActivityCard> createState() => _PlayingActivityCardState();
}

class _PlayingActivityCardState extends State<PlayingActivityCard> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.activity.content,
                    style: theme.textTheme.titleMedium,
                  ),
                ],
              ),
              PlayPauseButton(
                isPlaying: widget.activity.status == ActivityStatus.inProgress,
                activity: widget.activity,
              ),
            ]),
            const SizedBox(
              height: 24,
            ),
            ProgressBar(progress: widget.activity.getProgress()),
            const SizedBox(
              height: 8,
            ),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(widget.activity.getTimeElapsedFormatted()),
              Text(widget.activity.getTargetTimeFormatted())
            ]),
            const SizedBox(
              height: 4,
            ),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(
                widget.activity.getInitialTimeFormatted(),
                style: theme.textTheme.bodySmall,
              ),
              Text(
                widget.activity.getFinalTimeFormatted(),
                style: theme.textTheme.bodySmall,
              )
            ]),
          ],
        ),
      ),
    );
  }
}

class ProgressBar extends StatelessWidget {
  final double progress;
  const ProgressBar({super.key, required this.progress});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LinearProgressIndicator(
      backgroundColor: theme.progressIndicatorTheme.refreshBackgroundColor,
      value: progress,
    );
  }
}

class PlayPauseButton extends StatelessWidget {
  final bool isPlaying;
  final Activity activity;
  const PlayPauseButton({
    super.key,
    required this.isPlaying,
    required this.activity,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Stack(children: [
        if (isPlaying)
          LoadingAnimationWidget.hexagonDots(
              color: theme.progressIndicatorTheme.color ?? Colors.black,
              size: 50),
        IconButton(
          icon: Icon(
            isPlaying ? Icons.pause : Icons.play_arrow,
          ),
          onPressed: () => context
              .read<ActivityBloc>()
              .add(ToggleActivity(activity: activity)),
        ),
      ]),
    );
  }
}
