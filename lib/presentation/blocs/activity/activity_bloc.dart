import 'package:cron/data/entities/activity.dart';
import 'package:cron/domain/activities_transformer.dart';
import 'package:cron/presentation/blocs/activity/activity_event.dart';
import 'package:cron/presentation/blocs/activity/activity_state.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';

class ActivityBloc extends Bloc<ActivityEvent, ActivityState>
    with HydratedMixin {
  ActivityBloc() : super(ActivityState(latestTimeUpdated: DateTime.now())) {
    hydrate();
    on<ActivityAdded>(_onActivityAdded);
    on<ActivityDeleted>(_onActivityDeleted);

    on<RefreshActivities>(_onRefreshActivities);
    on<ToggleActivity>(_onToggleActivity);
    on<StopActivity>(_onStopActivity);

    Stream.periodic(const Duration(seconds: 1), (_) {}).listen((event) {
      add(RefreshActivities(
        currentTime: DateTime.now(),
      ));
    });
  }

  // HydratedBloc part
  @override
  ActivityState fromJson(Map<String, dynamic> json) =>
      ActivityState.fromJson(json);

  @override
  Map<String, dynamic> toJson(ActivityState state) => state.toJson();

  // Events
  void _onActivityAdded(
    ActivityAdded event,
    Emitter<ActivityState> emit,
  ) {
    DateTime latestActivityEndTime = DateTime.now();
    if (state.futureActivities.isNotEmpty) {
      latestActivityEndTime = state.futureActivities
          .map((activity) => activity.endTime)
          .reduce((value, element) => value.isAfter(element) ? value : element);
    }

    final newActivity = event.activity.to(
      id: DateTime.now().millisecondsSinceEpoch,
      startTime: latestActivityEndTime,
      endTime: latestActivityEndTime.add(event.activity.duration),
      currentTime: latestActivityEndTime,
      status: ActivityStatus.enqueued,
    );

    final activityState = addActivity(newActivity);
    emit(activityState);

    if (event.isPrioritized) {
      final lastPlayingActivity = state.futureActivities
          .where((activity) => activity.status == ActivityStatus.inProgress)
          .lastOrNull;
      if (lastPlayingActivity != null) {
        final activityState = pauseActivity(lastPlayingActivity);
        emit(activityState);
      }
      final activityState = playActivity(newActivity);
      emit(activityState);
    }
  }

  void _onRefreshActivities(
    RefreshActivities event,
    Emitter<ActivityState> emit,
  ) {
    Duration timeElapsed =
        event.currentTime.difference(state.latestTimeUpdated);
    emit(state.to(latestTimeUpdated: event.currentTime));

    final activityState1 = incrementPlayingActivities(timeElapsed);
    emit(activityState1);

    final activityState2 = incrementNotPlayingActivities(timeElapsed);
    emit(activityState2);

    final activityState3 = removeExpiredActivities(event.currentTime);
    emit(activityState3);

    final activityState4 = startNextOnQueueIfNecessary();
    emit(activityState4);
  }

  void _onToggleActivity(ToggleActivity event, Emitter<ActivityState> emit) {
    final activity = event.activity;
    if (activity.status == ActivityStatus.inProgress) {
      final activityState = pauseActivity(activity);
      emit(activityState);
    } else {
      final activityState = playActivity(activity);
      emit(activityState);
    }
  }

  void _onStopActivity(StopActivity event, Emitter<ActivityState> emit) {
    final activity = event.activity;
    final activityState = stopActivity(activity);
    emit(activityState);
  }

  // void _onActivityEdited(ActivityEdited event, Emitter<ActivityState> emit) {
  //   final editedActivities = state.activities.map((note) {
  //     if (note.id == event.id) {
  //       return note.copyWith(content: event.content);
  //     }
  //     return note;
  //   }).toList();
  //   emit(ActivityState(activities: editedActivities));
  // }

  // void _onActivityDeleted(ActivityDeleted event, Emitter<ActivityState> emit) {
  //   final deletedActivities =
  //       state.activities.where((note) => note.id != event.timestamp).toList();
  //   emit(ActivityState(activities: deletedActivities));
  // }

  _onActivityDeleted(ActivityDeleted event, Emitter<ActivityState> emit) {
    final activityState = stopActivity(event.activity);
    emit(activityState);
  }
}