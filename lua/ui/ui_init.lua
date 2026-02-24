local ui = {}

-- Layout
ui.Container = require("ui.layout.container")
ui.Row = require("ui.layout.row")
ui.Column = require("ui.layout.column")
ui.Grid = require("ui.layout.grid")
ui.Spacer = require("ui.layout.spacer")

-- Display
ui.Text = require("ui.display.text")
ui.Heading = require("ui.display.heading")
ui.Badge = require("ui.display.badge")
ui.Divider = require("ui.display.divider")
ui.Icon = require("ui.display.icon")

-- Data
ui.Value = require("ui.data.value")
ui.Progress = require("ui.data.progress")
ui.Chart = require("ui.data.chart")
ui.Table = require("ui.data.table")
ui.List = require("ui.data.list")

-- Feedback
ui.Loading = require("ui.feedback.loading")
ui.Error = require("ui.feedback.error")

-- Composite
ui.Panel = require("ui.composite.panel")
ui.Card = require("ui.composite.card")
ui.Stat = require("ui.composite.stat")
ui.Header = require("ui.composite.header")
ui.ScreenIndicator = require("ui.composite.screen_indicator")

-- Utility functions
function ui.rgb(r, g, b)
	return display.rgb(r, g, b)
end

function ui.load_theme(name)
	return require("config.themes." .. name)
end

return ui
