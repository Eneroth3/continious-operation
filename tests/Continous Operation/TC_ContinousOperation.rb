require 'testup/testcase'
require_relative "../../modules/continuous_operation.rb"

class TC_ContinuousOperation < TestUp::TestCase

  def setup
    # ...
  end

  def teardown
    # ...
  end

  #-----------------------------------------------------------------------------

  def test_basic
    model = Sketchup.active_model
    co = ContinuousOperation.new("Draw CPoints")

    cp = nil

    # Create a point
    co.start_operation do
      cp = model.entities.add_cpoint(ORIGIN)
    end

    # Create another point
    # This operation should merge into the previous one
    co.start_operation do
      model.entities.add_cpoint(ORIGIN)
    end

    # Expected to delete both points
    Sketchup.undo
    assert(cp.deleted?)

    co.stop
    discard_model_changes
  end

  def test_interupted
    model = Sketchup.active_model
    co = ContinuousOperation.new("Draw CPoints")

    cp1 = nil
    cp2 = nil
    cp3 = nil

    # Create a point in a continuous operation
    co.start_operation do
      cp1 = model.entities.add_cpoint(ORIGIN)
    end

    # Create a second point _outside_ of the continuous operation
    # This simulates the user making another model change outside of our extension
    cp2 = model.entities.add_cpoint(ORIGIN)

    # Create another point within our continuous operation
    co.start_operation do
      cp3 = model.entities.add_cpoint(ORIGIN)
    end

    # Expected to delete the third point only
    Sketchup.undo
    refute(cp1.deleted?)
    refute(cp2.deleted?)
    assert(cp3.deleted?)

    # Expected to delete the second point only
    Sketchup.undo
    refute(cp1.deleted?)
    assert(cp2.deleted?)
    assert(cp3.deleted?)

    # Expected to delete the first point only
    Sketchup.undo
    assert(cp1.deleted?)
    assert(cp2.deleted?)
    assert(cp3.deleted?)

    co.stop
    discard_model_changes
  end

  def test_explicit_commit
    model = Sketchup.active_model
    co = ContinuousOperation.new("Draw CPoints")

    # Create a point
    co.start_operation
    cp = model.entities.add_cpoint(ORIGIN)
    co.commit_operation

    # Create another point
    # This operation should merge into the previous one
    co.start_operation
    model.entities.add_cpoint(ORIGIN)
    co.commit_operation

    # Expected to delete both points
    Sketchup.undo
    assert(cp.deleted?)

    co.stop
    discard_model_changes
  end

  def test_explicit_interupt
    model = Sketchup.active_model
    co = ContinuousOperation.new("Draw CPoints")

    cp1 = nil
    cp2 = nil

    # Create a point in a continuous operation
    co.start_operation do
      cp1 = model.entities.add_cpoint(ORIGIN)
    end

    # Explicitly interrupt the sequence this time
    co.interrupt

    # Create another point within our continuous operation
    co.start_operation do
      cp2 = model.entities.add_cpoint(ORIGIN)
    end

    # Expected to delete the second point only
    Sketchup.undo
    refute(cp1.deleted?)
    assert(cp2.deleted?)

    # Expected to delete the first point only
    Sketchup.undo
    assert(cp1.deleted?)
    assert(cp2.deleted?)

    co.stop
    discard_model_changes
  end

  def test_Operation_Double
    # Two unrelated extensions should be able to run in parallel and both
    # use their own continuous operation.

    model = Sketchup.active_model
    co1 = ContinuousOperation.new("Draw CPoints 1")
    co2 = ContinuousOperation.new("Draw CPoints 2")

    cpts1 = []
    cpts2 = []

    co1.start_operation do
      cpts1 << model.entities.add_cpoint(ORIGIN)
    end
    co1.start_operation do
      cpts1 << model.entities.add_cpoint(ORIGIN)
    end

    co2.start_operation do
      cpts2 << model.entities.add_cpoint(ORIGIN)
    end
    co2.start_operation do
      cpts2 << model.entities.add_cpoint(ORIGIN)
    end

    co1.start_operation do
      cpts1 << model.entities.add_cpoint(ORIGIN)
    end

    Sketchup.undo
    assert(cpts1[-1].deleted?, "Point should be deleted.")
    refute(cpts1[-2].deleted?, "Point should be kept.")
    refute(cpts2[-1].deleted?, "Point should be kept.")

    Sketchup.undo
    assert(cpts2[-1].deleted?, "Point should be deleted.")
    assert(cpts2[-2].deleted?, "Point should be deleted.")
    refute(cpts1[-2].deleted?, "Point should be kept.")

    Sketchup.undo
    assert(cpts1[-2].deleted?, "Point should be deleted.")
    assert(cpts1[-3].deleted?, "Point should be deleted.")

    co1.stop
    co2.stop
    discard_model_changes
  end

end
