library mutable_bloc;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';

abstract class Bloc<T> {
  late final Stream<T> stream;
  late T state;
  late final StreamController<T> controller;
  Bloc(T initialState) {
    controller = BehaviorSubject();
    stream = controller.stream.map((T response) {
      return response;
    });

    setState(() {
      this.state = initialState;
    });
  }

  void setState(void Function() fn) {
    fn();
    controller.add(state);
  }

  dispose() {
    controller.close();
  }
}

class BlocProvider<T extends Bloc> extends InheritedWidget {
  BlocProvider({required this.create, this.lazy = true, Key? key, required Widget child})
      : super(key: key, child: child) {
    if (!lazy) {
      _bloc = create();
    }
  }

  final T Function() create;
  final bool lazy;
  late final T _bloc;

  T get bloc {
    if (lazy) {
      _bloc = create();
    }
    return _bloc;
  }

  @override
  bool updateShouldNotify(InheritedWidget oldWidget) => false;
}

extension BlocProviderExtension on BuildContext {
  T getBloc<T extends Bloc>() {
    return this.dependOnInheritedWidgetOfExactType<BlocProvider<T>>()!.bloc;
  }
}

class BlocBuilder<T extends Bloc<S>, S> extends StatelessWidget {
  final Widget Function(BuildContext context, S? state) builder;
  final Widget Function(BuildContext context)? onError;
  final Widget Function(BuildContext context)? onLoad;

  const BlocBuilder({Key? key, required this.builder, required this.onError, required this.onLoad}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    var bloc = context.getBloc<T>();
    return StreamBuilder(
        stream: bloc.stream,
        builder: (context, AsyncSnapshot<S> snapshot) {
          if (snapshot.hasError)
            return onError == null ? Text(snapshot.error.toString()) : onError!(context);
          else if (!snapshot.hasData)
            return onLoad == null ? CircularProgressIndicator() : onLoad!(context);
          else
            return builder(context, snapshot.data);
        });
  }
}
