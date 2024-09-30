require_relative "../modules/continuous_operation.rb"

# Example of Continuous Operation.
#
# Adds a HTML dialog opened from *Extensions > Continuous Operation Example*
# that lets you draw randomly placed construction points.
#
# If you undo once, all points created from the same dialog session are removed.
#
# If you manually make some changes to the model while the dialog is open, say
# draw a line using Line tool, the points added before the line, the
# line itself, and the points added after the line show up as three separate
# operations in the undo stack.
module DrawPointsExample
  INSTRUCTIONS =
    "If you undo once, all points created from the same dialog session are removed.\n\n"\
    "If you manually make some changes to the model while the dialog is open, say´"\
    "draw a line using Line tool, the points added before the line, the "\
    "line itself, and the points added after the line show up as three separate "\
    "operations in the undo stack."

  HTML = <<-EOT
    #{INSTRUCTIONS.gsub("\n", '<br />')}<br /><br />
    <button onclick="sketchup.draw()">Add Point</button>
  EOT

  @ip = Sketchup::InputPoint.new

  # Open the dialog containing from where the user can draw points.
  def self.show_dialog
    # Create Continuous Operation manager when the UI is shown.
    @co = ContinuousOperation.new("Points")

    if @dlg && @dlg.visible?
      @dlg.bring_to_front
    else
      @dlg ||= UI::HtmlDialog.new(dialog_title: "Continuous Operation Example", width: 500, height: 250)
      @dlg.set_html(HTML)
      @dlg.add_action_callback("draw") { sequential_point_draw }

      # Stop listening to model transactions when the UI closes.
      @dlg.set_on_closed { @co.stop }

      @dlg.show
    end
  end

  # Draw a construction point as part of a continuous operation.
  def self.sequential_point_draw
    @co.start_operation { draw_point }
  end

  # Draw a construction point at a random location in the view.
  def self.draw_point
    model = Sketchup.active_model
    view = model.active_view
    @ip.pick(view, rand(view.vpwidth), rand(view.vpheight))
    point = @ip.position

    model.active_entities.add_cpoint(point)
  end

  menu = UI.menu("Plugins")
  menu.add_item("Continuous Operation Example") { show_dialog }
end
