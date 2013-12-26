/**
 * Objective D'Art fretboard trainer.
 */

import 'dart:async' show StreamController, Timer;
import 'dart:html' show Element, NumberInputElement, querySelector;
import 'dart:math' show Random;

/**
 * Manages a set of elements, only one of which is active at once.
 */
class Activator {
  final List<Element> _children;
  int activeIndex = null;

  Activator(Element parent)
      : _children = parent.getElementsByClassName('highlander');

  void activate(int index) {
    if (activeIndex != null) {
      _children[activeIndex].classes.remove('active');
    }
    activeIndex = index;
    _children[activeIndex].classes.add('active');
  }
}

class View {
  final Element _note = querySelector('#note');
  final Activator _strings = new Activator(querySelector('#strings'));
  final Activator _beats = new Activator(querySelector('#metronomedisplay'));

  View(Metronome m) {
    m.listen((beat) => this.beat = beat % 4);
  }

  set note(String note) {
    _note.text = note;
  }

  set string(int string) {
    _strings.activate(string);
  }

  set beat(int beat) {
    _beats.activate(beat);
  }
}

/**
 * A simple listenable timer.
 * Uses a broadcast stream underneath, but doesn't currently
 * expose the full stream API.
 */
class Metronome {
  // This should maybe stop and start the metronome via
  // onListen and onCancel, but currently there's always at least
  // one listener (the beat display), so the broadcast stream
  // is always active.
  final StreamController _controller = new StreamController<int>.broadcast();
  Timer _t;
  int beat = 0;

  void _tick() {
    _controller.add(beat++);
  }

  set delay(Duration delay) {
    if (_t != null) _t.cancel();
    _t = new Timer.periodic(delay, (_) => _tick());
  }

  set tempo(num tempo) {
    delay = new Duration(milliseconds: 1000 * 60 ~/ tempo);
  }

  listen(onData) => _controller.stream.listen(onData);
}

/**
 * Main class. Periodically chooses a string and a fret
 * and updates the view accordingly.
 */
class Controller {
  final View view;
  final Metronome m;
  final NumberInputElement tempo = querySelector("#tempo");

  static final NOTES = [
    'A', 'A♯', 'B', 'C', 'C♯', 'D', 'D♯', 'E', 'F', 'F♯', 'G', 'G♯'
  ];

  static final SUBSTITUTIONS = {
    'A#': 'B♭', 'C#': 'D♭', 'D♯': 'E♭', 'F♯': 'G♭', 'G♯': 'A♭'
  };

  static final _RAND = new Random();

  factory Controller.go() {
    var m = new Metronome();
    return new Controller(m, new View(m));
  }

  Controller(this.m, this.view) {
    m.listen((beat) {
      if (beat % 4 == 0) {
        update();
      }
    });
    m.tempo = tempo.valueAsNumber;
    tempo.onChange.listen((_) => m.tempo = tempo.valueAsNumber);
  }

  String chooseNote() {
    var note = NOTES[_RAND.nextInt(NOTES.length)];
    if (SUBSTITUTIONS.containsKey(note) && _RAND.nextBool()) {
      note = SUBSTITUTIONS[note];
    }
    return note;
  }

  int chooseString() {
    return _RAND.nextInt(6);
  }

  void update() {
    view.note = chooseNote();
    view.string = chooseString();
  }
}

void main() {
  new Controller.go();
}
