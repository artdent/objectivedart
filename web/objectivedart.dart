/**
 * Objective D'Art fretboard trainer.
 */

import 'dart:async' show StreamController, Timer;
import 'dart:html' show Element, CheckboxInputElement, NumberInputElement,
    querySelector, querySelectorAll, window;
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

/// Converts an id-safe string (no Unicode) into a note name.
String noteName(String noteId) {
  assert(noteId.startsWith('choose_'));
  String note = noteId['choose_'.length].toUpperCase();
  // 'is' and 'es' are the German suffixes for sharp and flat.
  // (This convention is borrowed from Lilypond.)
  if (noteId.endsWith('is')) {
    return note + '♯';
  } else if (noteId.endsWith('es')) {
    return note + '♭';
  }
  return note;
}

/// Updates the display and holds references to relevant HTML elements.
class View {
  final Element _note = querySelector('#note');
  final List<CheckboxInputElement> noteToggles =
      querySelector('#choosenotes').querySelectorAll('input');
  final NumberInputElement tempoInput = querySelector('#tempo');
  final Activator _strings = new Activator(querySelector('#strings'));
  final Activator _beats = new Activator(querySelector('#metronomedisplay'));

  View() {
    // If <input type="number"> is not supported, at least fix
    // the resulting layout bug.
    // TODO: just use a polyfill here.
    if (!NumberInputElement.supported) {
      tempoInput.style.width = '100px';
    }
  }

  set note(String note) {
    if (note != null) {
      _note.text = note;
    }
  }

  set string(int string) {
    _strings.activate(string);
  }

  set beat(int beat) {
    _beats.activate(beat);
  }

  int get tempo {
    return int.parse(tempoInput.value);
  }

  Set<String> get enabledNotes {
    return noteToggles
        .where((checkbox) => checkbox.checked)
        .map((checkbox) => noteName(checkbox.id))
        .toSet();
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

  /**
   * Notes to choose from. May contain duplicates, so that choosing
   * from this list uniformly at random doesn't bias the choices
   * in favor of notes that have enharmonic equivalents.
   */
  final List<String> noteChoices = [];

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
    if (noteChoices.length == 0) {
      return null;
    }
    return noteChoices[_RAND.nextInt(noteChoices.length)];
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

  void updateActiveNotes() {
    var enabledNotes = view.enabledNotes;
    // A note goes into the list once if its enharmonic equivalent
    // is also in the list, and twice otherwise.
    // This allows selecting from noteChoices uniformly at random.
    noteChoices.clear();
    for (var note in enabledNotes) {
      noteChoices.add(note);
      if (!SUBSTITUTIONS.containsKey(note) ||
          !enabledNotes.contains(SUBSTITUTIONS[note])) {
        noteChoices.add(note);
      }
    }
  }

  /// Serializes the user-editable state as json.
  Object toJson() {
    return {
      'tempo': _tempo,
      'activeNotes': view.noteToggles
          .map((checkbox) => checkbox.checked)
          .toList(),
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

    List<bool> activeNotes = obj['activeNotes'];
    if (activeNotes != null) {
      for (var i = 0; i < activeNotes.length; i++) {
        view.noteToggles[i].checked = activeNotes[i];
      }
    }
    updateActiveNotes();
  }
}

class Controller {
  final Model model;
  final View view;

  factory Controller.go() {
    var m = new Metronome();
    var view = new View();
    assert(view.noteToggles.length > 0);
    var model = new Model(view, m);
    return new Controller(model, view);
  }

  Controller(this.model, this.view) {
    load();
    view.tempoInput.onChange.listen((_) {
      model.tempo = view.tempo;
      save();
    });
    for (var checkbox in view.noteToggles) {
      checkbox.onChange.listen((target) {
        model.updateActiveNotes();
        save();
      });
    }
  }

  /// Loads user-modified state from local storage.
  void load() {
    var saved = window.localStorage['objectivedart'];
    model.fromJson(saved != null ? JSON.decode(saved) : {},
      defaultTempo: view.tempo
    );
  }

  /// Saves user-modified state to local storage.
  void save() {
    window.localStorage['objectivedart'] = JSON.encode(model.toJson());
  }
}

void main() {
  new Controller.go();
}
