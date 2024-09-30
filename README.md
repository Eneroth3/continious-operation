# Continuous Operation

Wrapper around SketchUp's `Sketchup::Model#start_operation` and
`#commit_operation` that makes subsequent operations transparent to the previous
ones.

This is useful when you want a live model change e.g. when dragging a slider,
but don't want every step of the slider to create a new entry in the undo stack.

If the user draws something else to the model, these changes are kept separate
in the undo stack from the continuous operation.
(This is kinda the whole point with this thingy; otherwise you could just
blindly set the `transparent` argument to true)

A similar behavior is used by SketchUp for the material color sliders.
