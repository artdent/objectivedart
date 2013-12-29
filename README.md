A simple fretboard trainer.

This app asks you to play random notes on random strings at a timed interval.
It is a trivial web app that just barely meets my own needs.
If you want something fancier, [this Android app](https://play.google.com/store/apps/details?id=com.redrabbit.android.guitar.guitarfretboardtrainerlite&hl=en)
looks interesting.

The name has threefold meaning: it sounds like "objet d'art"; the objective
of using it is to learn the art of playing guitar; and the program
is written in Dart. Any relation to other things beginning with
"Objective" is pure trolling^Wcoincidence.

Features:
- Tempo adjustment
- Choose the subset of notes to learn
- Tempo and note selection saved to local storage

TODO (might happen, especially if someone requests it):
- Choose the subset of strings to learn

TODO (not going to happen unless someone sends a patch):
- Use web audio API to listen for note onsets and pitches

Bugs:
- Tempo up/down toggles don't show up in Firefox
  (`<input type="number">` is not fully supported until FF28).
- Untested in Internet Explorer.
