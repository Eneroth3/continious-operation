module ContinuousCommitLib

# Create a stream of model operations that are all merged into one in the undo
# stack. Can be used when there are several changes to the model performed
# subsequently, e.g. on each key down in a dialog, to avoid numerous entries in
# the undo stack.
#
# If another action is performed during the continuous commit it resets and
# breaks and a new stream of commits is stared.
#
# Useful for actions carried out repeatedly from HTML dialog, e.g. on each key
# press, to avoid flooding the undo stack, while still allowing the user to
# perform separate actions to the model without these different kinds of
# operation merging.
#
# TODO: Look over documentation and naming, and figure out where operation,
# transaction and commit should be used.
class ContinuousCommit

  def initialize(name:)
    @name = name
    @make_trans_to_prev = false
    @caused_current_transcation = false
    @observers = Observers.new(self)
  end

  def start_operation
    model = Sketchup.active_model
    model.start_operation(@name, true, false, @make_trans_to_prev)

    if block_given?
      yield
      commit_operation
    end
  end

  # TODO: Can operation be started and committed separately?
  def commit_operation
    @caused_current_transcation = true
    #UI.start_timer(0) { @caused_current_transcation = false }

    model = Sketchup.active_model
    model.commit_operation

    @caused_current_transcation = false
    @make_trans_to_prev = true

    nil
  end

  # Reset continuity. The following commits will not be made transparent into
  # the one performed prior to this point.
  #
  # @return [Void]
  def reset
    @make_trans_to_prev = false

    nil
  end

  # Start listening to model operations and reset the continuous operation in
  # the case of an independent operation being carried out. Do this before
  # making commits.
  #
  # @return [Void]
  #
  # REVIEW: Call bake into initialize?
  def start
    @observers.observe_app

    nil
  end

  # Stop listening to model operations. Do this when there will not be more
  # commits in this stream.
  #
  # @return [Void]
  def stop
    @observers.end_observe_app

    nil
  end

  #-----------------------------------------------------------------------------

  # @private
  def on_model_transaction
    return if @caused_current_transcation
    reset

    nil
  end

  # @private
  class Observers

    def initialize(cc)
      @cc = cc
    end

    def observe_app
      @app_observer ||= AppObserver.new(self)
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
      @model_observer ||= ModelObserver.new(@cc)
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

      def initialize(observers)
        @observers = observers
      end

      def onActivateModel(model)
        on_activate_model(model)
      end

      def onNewModel(model)
        on_activate_model(model)
      end

      def onOpenModel(model)
        on_activate_model(model)
      end

      private

      def on_activate_model(model)
        @observers.observe_model(model)
      end

    end

    class ModelObserver < Sketchup::ModelObserver

      def initialize(cc)
        @cc = cc
      end

      def onTransactionCommit(_)
        @cc.on_model_transaction
      end

      def onTransactionRedo(_)
        @cc.on_model_transaction
      end

      def onTransactionUndo(_)
        @cc.on_model_transaction
      end

    end

  end

end
end
