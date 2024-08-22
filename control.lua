local mod_gui = require("__core__/lualib/mod-gui")

local gui = require("__flib__.gui-lite")
local TagReaderView = require("scripts.TagViewerGui")

--BOOTSTRAP

gui.handle_events()

script.on_init(function()
    if not global.lihop_tagReaderView_state then global.lihop_tagReaderView_state = {} end
end)


script.on_configuration_changed(function(e)
    global.lihop_tagReaderView_state = {}
    for _,player in pairs(game.players) do
        if player.gui.screen.lihop_tagReader_Main then
            player.gui.screen.lihop_tagReader_Main.destroy()
        end
        local flow=mod_gui.get_button_flow(player)
        if flow.TagViewer then
            flow.TagViewer.destroy()
        end
        TagReaderView.build(player)
    end
end)

-- Create the GUI when a player is created
script.on_event({
    defines.events.on_player_created
}, function(e)
    local player = game.get_player(e.player_index) --[[@as LuaPlayer]]
    TagReaderView.build(player)
end)

script.on_event(defines.events.on_gui_closed, function(e)
    if e.element then
        if e.element.name == "lihop_tagReader_Main" then
            TagReaderView.on_gui_closed(e)
        end
    end
end)
