/**
 * Objective D'Art fretboard trainer.
 */

import 'dart:async' show Stream;
import 'dart:html' show Element, querySelector;
import 'dart:math' show Random;

var controller;
void main() {
  controller = new Controller();
}

/**
 * Manages a set of elements, only one of which is active at once.
 */
class Activator {
  List<Element> _children;
  int activeIndex = null;

  Activator(Element parent) {
    _children = parent.getElementsByClassName('highlander');
  }

  void activate(int index) {
    if (activeIndex != null) {
      _children[activeIndex].classes.remove('active');
    }
    activeIndex = index;
    _children[activeIndex].classes.add('active');
  }
}

class View {
  Element _note = querySelector('#note');
  Activator _strings = new Activator(querySelector('#strings'));
  Activator _beats = new Activator(querySelector('#metronome'));
  int activeString = null;
  int activeBeat = null;

  View(Metronome m) {
    m.stream.listen((beat) => this.beat = beat % 4);
  }

  set note (String note) {
    _note.text = note;
  }

  set string (int string) {
    _strings.activate(string);
  }

  set beat (int beat) {
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

  Metronome(Duration delay) {
    this.delay = delay;
  }

  set delay (Duration delay) {
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
  Metronome m;

  var delay = const Duration(milliseconds: 1500);

  var NOTES = [
    'A', 'A♯', 'B', 'C', 'C♯', 'D', 'D♯', 'E', 'F', 'F♯', 'G', 'G♯'
  ];

  var SUBSTITUTIONS = {
    'A#': 'B♭', 'C#': 'D♭', 'D♯': 'E♭', 'F♯': 'G♭', 'G♯': 'A♭'
  };

  var _rand = new Random();

  Controller() {
    m = new Metronome(delay);
    view = new View(m);
    m.stream.listen((beat) {
      if (beat % 4 == 0) {
        update();
      }
    });
  }

  String chooseNote() {
    var note = NOTES[_rand.nextInt(NOTES.length)];
    if (SUBSTITUTIONS.containsKey(note) && _rand.nextBool()) {
      note = SUBSTITUTIONS[note];
    }
    return note;
  }

  int chooseString() {
    return _rand.nextInt(6);
  }

  void update() {
    view.note = chooseNote();
    view.string = chooseString();
  }
}