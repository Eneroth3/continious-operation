# Manages a sequence of related operations so that they show up as a single
# entry in the SketchUp undo stack.
#
# See example in `examples` folder.
class ContinuousOperation
  # Create a ContinuousOperation object.
  #
  # @param operation_name [String]
  #   Title of the operation to show in Edit > Undo.
  def initialize(operation_name)
    @operation_name = operation_name

    @transparent_to_previous = false
    @triggered_itself = false

    attach_observers
  end

  # Start an individual operation within the sequence. Call this before making
  # changes to the model.
  #
  # Either explicitly call `#commit_operation` when the changes are done,
  # or call this method with a code block to implicitly commit the operation
  # when the block ends.
  def start_operation
    model = Sketchup.active_model
    model.start_operation(@operation_name, true, false, @transparent_to_previous)

    if block_given?
      yield
      commit_operation
    end

    nil
  end

  # Commit an individual operation started by `#start_operation`.
  #
  # This call can be skipped if you call `#start_operation` with a code block.
  def commit_operation
    @triggered_itself = true

    model = Sketchup.active_model
    model.commit_operation # Observers are called here

    @triggered_itself = false
    @transparent_to_previous = true

    nil
  end

  # Explicitly interrupt the continuous operation, i.e. make the next operation
  # not transparent to the previous one.
  #
  # If the user interrupts the sequence by using another tool, this is
  # automatically detected and handled.
  #
  # (I've forgotten why I made this public API).
  def interrupt
    @transparent_to_previous = false

    nil
  end

  # @private
  def interupt
    # Okay, this one is so funny I'm keeping it.
    raise NoMethodError, "It is spelled interrupt. inter-rupt. inter. Rupt."
  end

  # Stop listening to model operations.
  #
  # Typically called when the UI controlling the contentious operation closes.
  # This call makes this object unusable. Create a new object in its place next
  # time the UI is shown.
  def stop
    remove_observers

    nil
  end

  # API

  # @api sketchup-observers
  # @see https://ruby.sketchup.com/Sketchup/AppObserver.html
  def self.onActivateModel(*_args)
    attach_observers
    set_dialog_values

    # Ideally there should be separate objects tracking separate models.
    # But I don't have a Mac to test the multi doc interface on.
    # Instead just interrupt the sequence on model change so we don't
    # accidentally merge undo stack entries wth unrelated model changes.
    interupt
  end

  # @api sketchup-observers
  # @see https://ruby.sketchup.com/Sketchup/AppObserver.html
  def self.onNewModel(*_args)
    attach_observers
    set_dialog_values

    # See above comment
    interupt
  end

  # @api sketchup-observers
  # @see https://ruby.sketchup.com/Sketchup/AppObserver.html
  def self.onOpenModel(*_args)
    attach_observers
    set_dialog_values

    # See above comment
    interupt
  end

  # @api sketchup-observers
  # @see https://ruby.sketchup.com/Sketchup/ModelObserver.html
  def onTransactionCommit(*_args)
    interrupt unless @triggered_itself
  end
  alias onTransactionRedo onTransactionCommit
  alias onTransactionUndo onTransactionCommit

  private

  def attach_observers
    # Remove first to avoid attaching same object multiple times.
    remove_observers

    Sketchup.add_observer(self)
    Sketchup.active_model.add_observer(self)
  end

  def remove_observers
    Sketchup.remove_observer(self)
    Sketchup.active_model.remove_observer(self)
  end
end
