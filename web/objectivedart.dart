/**
 * Objective D'Art fretboard trainer.
 */

import 'dart:async' show Stream;
import 'dart:html' show Element, querySelector;
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
  final Activator _beats = new Activator(querySelector('#metronome'));

  View(Metronome m) {
    m.stream.listen((beat) => this.beat = beat % 4);
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
 */
class Metronome {
  /**
   * The event stream. A broadcast stream that sends an
   * incrementing integer as its event.
   */
  var stream;

  Duration _delay;

  Metronome(this._delay);

  set delay(Duration delay) {
    // TODO: changing the delay removes all listeners from the metronome.
    stream = new Stream.periodic(delay, (beat) => beat)
        .asBroadcastStream();
  }
}

/**
 * Main class. Periodically chooses a string and a fret
 * and updates the view accordingly.
 */
class Controller {
  View view;
  final Metronome m;

  static const DELAY = const Duration(milliseconds: 1500);

  static final NOTES = [
    'A', 'A♯', 'B', 'C', 'C♯', 'D', 'D♯', 'E', 'F', 'F♯', 'G', 'G♯'
  ];

  static final SUBSTITUTIONS = {
    'A#': 'B♭', 'C#': 'D♭', 'D♯': 'E♭', 'F♯': 'G♭', 'G♯': 'A♭'
  };

  static final _RAND = new Random();

  Controller()
      : this.m = new Metronome(DELAY) {
    // It would be nice if view were final, but it needs
    // to be passed the metronome, which is non-static. Sigh.
    view = new View(m);
    m.stream.listen((beat) {
      if (beat % 4 == 0) {
        update();
      }
    });
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

var controller;
void main() {
  controller = new Controller();
}
