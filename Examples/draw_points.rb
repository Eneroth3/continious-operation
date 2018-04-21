require_relative "../continuous_commit.rb"

module OperationSequenceLib
module Examples
module DrawPoints

  INSTRUCTIONS =
    "Points added from here should be merged into a single entry in the undo "\
    "stack. Undo once and they should all be gone.<br /><br/>"\
    "This continuity should however be interrupted if another action to the "\
    "model is performed. If you manually modify the model, your modification, "\
    "the points drawn before and the points drawn after should be 3 separate "\
    "entries to the undo stack."

  HTML = <<-EOT
    #{INSTRUCTIONS}<br /><br />
    <button onclick="sketchup.draw()">Add Point</button>
  EOT

  @ip = Sketchup::InputPoint.new
  @os = OperationSequence.new("Points")
  @dlg = nil

  # Draw a guide point in the center of the view.
  def self.draw_point
    model = Sketchup.active_model
    view = model.active_view
    @ip.pick(view, view.vpwidth / 2, view.vpheight / 2)
    point = @ip.position

    model.active_entities.add_cpoint(point)
  end

  # Draw point as part of operation sequence, meaning that if the previous
  # operation to the model was within the same sequence, they are merged into
  # one entry in the undo stack.
  def self.sequential_point_draw
    @os.start_operation { draw_point }
  end

  def self.show_dialog
    @os.start

    if @dlg && @dlg.visible?
      @dlg.bring_to_front
    else
      @dlg ||= UI::HtmlDialog.new(dialog_title: "OperationSequence Example")
      @dlg.set_html(HTML)
      @dlg.add_action_callback("draw") { sequential_point_draw }
      @dlg.set_on_closed { @os.stop }
      @dlg.show
    end

    nil
  end

  menu = UI.menu("Plugins")
  menu.add_item("Continuous Operation Example") { show_dialog }

end
end
end
