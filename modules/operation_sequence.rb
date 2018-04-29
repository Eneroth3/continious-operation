module OperationSequenceLib

# Define a sequence of operations.
#
# Each subsequent operation in the same sequence is made transparent to the
# previous one (seemingly merged into one undo stack entry) unless an operation
# outside of the sequence was performed in between, or the sequence was
# explicitly interrupted.
#
# This can be useful to allow multiple small changes, e.g. on each individual
# key press in a text input, without flooding the undo stack.
#
# Note that SketchUp's undo stack only contains 100 operations, and that
# transparent (chained) operations count separately, even if they to the user
# appear as one.
#
# @example
#   os = OperationSequenceLib::OperationSequence.new("Draw Point")
#   os.start
#   ip = Sketchup::InputPoint.new
#   UI.menu("Plugins").add_item("Draw Point") do
#     os.start_operation do
#       model = Sketchup.active_model
#       view = model.active_view
#       # Find random point within view.
#       ip.pick(view, rand(view.vpwidth), rand(view.vpheight))
#       point = ip.position
#       model.active_entities.add_cpoint(point)
#     end
#   end
class OperationSequence

  # Commit an individual operation started by `#start_operation`.
  #
  # @return [Void]
  def commit_operation
    @caused_current_transcation = true

    model = Sketchup.active_model
    model.commit_operation

    @caused_current_transcation = false
    @make_trans_to_prev = true

    nil
  end

  # Initialize a new operation sequence.
  #
  # @param op_name [String] The name of the operation(s) in the undo stack.
  def initialize(op_name)
    @op_name = op_name
    @make_trans_to_prev = false
    @caused_current_transcation = false
    @observers = Observers.new(self)
  end

  # Prevent next operation from being transparent to the previous one (seemingly
  # merged into one undo stack entry).
  #
  # @return [Void]
  def interrupt
    @make_trans_to_prev = false

    nil
  end

  # @private
  def interupt
    raise NoMethodError, "It is spelled interrupt. inter-rupt. inter. Rupt."
  end

  # Start listen to model transactions and interrupt the sequence if an outside
  # transaction is performed. Call this before starting an individual operation,
  # e.g. when the UI performing the sequential operations is shown.
  #
  # @return [Void]
  def start
    @make_trans_to_prev = false
    @observers.observe_app

    nil
  end

  # Start an individual operation within the sequence. Call this before making
  # changes to the model. Either explicitly call `#commit_operation` when the
  # changes are done, or call this method with a code block to implicitly commit
  # the operation when the block ends.
  #
  # @return [Void]
  def start_operation
    model = Sketchup.active_model
    model.start_operation(@op_name, true, false, @make_trans_to_prev)

    if block_given?
      yield
      commit_operation
    end

    nil
  end

  # Stop listening to model operations. Call this to free up resources when
  # there will not be any sequential operations for some time, e.g. when the UI
  # for performing them is closed. `start` can later be called on the same
  # operation sequence, e.g. if the UI is shown again.
  #
  # @return [Void]
  def stop
    @observers.end_observe_app

    nil
  end

  #-----------------------------------------------------------------------------

  # Called from observers whenever a transaction is committed to the model
  # (between #start and #stop).
  #
  # @private
  def on_model_transaction
    return if @caused_current_transcation
    interrupt

    nil
  end

  # Wrapper for adding and removing observers.
  # REVIEW: Make a separate interface for observers that automatically gets
  # added when new models are opened.
  #
  # @private
  class Observers

    def initialize(os)
      @os = os
    end

    def observe_app
      @app_observer ||= AppObserver.new(self, @os)
      Sketchup.remove_observer(@app_observer)
      Sketchup.add_observer(@app_observer)
      observe_model(Sketchup.active_model)

      nil
    end

    def end_observe_app
      Sketchup.remove_observer(@app_observer)
      end_observe_model(Sketchup.active_model)
      @app_observer = nil

      nil
    end

    def observe_model(model)
      @model_observer ||= ModelObserver.new(@os)
      model.remove_observer(@model_observer)
      model.add_observer(@model_observer)

      nil
    end

    def end_observe_model(model)
      model.remove_observer(@model_observer)
      model.selection.remove_observer(@selection_observer)
      @selection_observer = nil

      nil
    end

    class AppObserver < Sketchup::AppObserver

      def initialize(observers, os)
        @observers = observers
        @os = os
      end

      def onActivateModel(model)
        @observers.observe_model(model)
        # REVIEW: Ideally there should be separate sequences for separate models
        # somehow. As I don't have access to test the multi document interface
        # (Mac only) I can't develop that and instead simply interrupt the
        # sequence on model change. Not doing anything would cause faulty
        # operation merging if the user switches model while using an operation
        # sequence.
        @os.interupt
      end

      def onNewModel(model)
        @observers.observe_model(model)
      end

      def onOpenModel(model)
        @observers.observe_model(model)
      end

    end

    class ModelObserver < Sketchup::ModelObserver

      def initialize(os)
        @os = os
      end

      def onTransactionCommit(_)
        @os.on_model_transaction
      end

      def onTransactionRedo(_)
        @os.on_model_transaction
      end

      def onTransactionUndo(_)
        @os.on_model_transaction
      end

    end

  end

end
end
