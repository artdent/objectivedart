/**
 * Objective D'Art fretboard trainer.
 */

import 'dart:async' show StreamController, Timer;
import 'dart:html' show Element, NumberInputElement, querySelector, window;
import 'dart:math' show Random;
import 'dart:convert' show JSON;

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

/// Updates the display.
class View {
  final Element _note = querySelector('#note');
  final NumberInputElement tempoInput = querySelector("#tempo");
  final Activator _strings = new Activator(querySelector('#strings'));
  final Activator _beats = new Activator(querySelector('#metronomedisplay'));

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
 * Main state. Chooses a string and a fret
 * and updates the view accordingly.
 */
class Model {
  final View view;
  final Metronome m;

  /// Tempo in beats per minute.
  int _tempo = null;

  static final NOTES = [
    'A', 'A♯', 'B', 'C', 'C♯', 'D', 'D♯', 'E', 'F', 'F♯', 'G', 'G♯'
  ];

  static final SUBSTITUTIONS = {
    'A♯': 'B♭', 'C♯': 'D♭', 'D♯': 'E♭', 'F♯': 'G♭', 'G♯': 'A♭'
  };

  static final _RAND = new Random();

  Model(this.view, this.m) {
    m.listen((beat) {
      view.beat = beat % 4;
      if (beat % 4 == 0) {
        chooseNextNote();
      }
    });
  }

  String _chooseNote() {
    var note = NOTES[_RAND.nextInt(NOTES.length)];
    if (SUBSTITUTIONS.containsKey(note) && _RAND.nextBool()) {
      note = SUBSTITUTIONS[note];
    }
    return note;
  }

  int _chooseString() {
    return _RAND.nextInt(6);
  }

  void chooseNextNote() {
    view.note = _chooseNote();
    view.string = _chooseString();
  }

  set tempo(int tempo) {
    _tempo = tempo;
    m.tempo = tempo;
  }

  /// Serializes the user-editable state as json.
  Object toJson() {
    return {
      'tempo': _tempo
    };
  }

  /// Resets the user-editable state from a json object.
  void fromJson(obj, {defaultTempo}) {
    int t = obj['tempo'];
    if (t == null) {
      t = defaultTempo;
    }
    this.tempo = t;
    view.tempoInput.value = t.toString();
  }
}

class Controller {
  final Model model;
  final NumberInputElement tempoInput;

  factory Controller.go() {
    var m = new Metronome();
    var view = new View();
    var model = new Model(view, m);
    return new Controller(model, view.tempoInput);
  }

  Controller(this.model, this.tempoInput) {
    load();
    tempoInput.onChange.listen((_) {
      model.tempo = int.parse(tempoInput.value);
      save();
    });
  }

  void load() {
    var saved = window.localStorage['objectivedart'];
    model.fromJson(saved != null ? JSON.decode(saved) : {},
      defaultTempo: int.parse(tempoInput.value)
    );
  }

  void save() {
    window.localStorage['objectivedart'] = JSON.encode(model.toJson());
  }
}

void main() {
  new Controller.go();
}
