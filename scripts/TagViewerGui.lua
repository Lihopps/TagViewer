local debug = false

local gui = require("__flib__/gui-lite")
local mod_gui = require("__core__/lualib/mod-gui")
local util = require("scripts.util")

--local util = require("script.util")

--- @param name string
--- @param sprite string
--- @param tooltip LocalisedString
--- @param handler function
local function frame_action_button(name, sprite, tooltip, handler)
    return {
        type = "sprite-button",
        name = name,
        style = "frame_action_button",
        sprite = sprite .. "_white",
        hovered_sprite = sprite .. "_black",
        clicked_sprite = sprite .. "_black",
        tooltip = tooltip,
        handler = handler,
    }
end

local function action_button(name,caption, tooltip, handler)
    return {
        type = "button",
        name = name,
        caption=caption,
        style_mods = { horizontally_stretchable = true },
        tooltip = tooltip,
        mouse_button_filter = { "left" },
        handler = { [defines.events.on_gui_click] = handler },

    }
end

--- @param e EventData.on_gui_click
local function on_button_table_clicked(e)
    local str = util.split(e.element.name, "/*")[1]
    if e.element.sprite == "utility/collapse" then
        e.element.sprite = "utility/expand"
    else
        e.element.sprite = "utility/collapse"
    end
    local elems = global.lihop_tagReaderView_state[e.player_index].elems
    elems[str].visible = not elems[str].visible
end

local function update_data(data, elem, flowname)
    for k, v in pairs(data) do
        if type(v) == "table" then
            if next(v) then
                local name = flowname .. k
                local flow = {
                    type = "flow",
                    style_mods = {vertically_squashable=true},
                    direction = "vertical",
                    {
                        type = "flow",
                        style_mods = {vertically_squashable=true},
                        direction = "horizontal",
                        {
                            type = "sprite-button",
                            style = "frame_action_button",
                            sprite = "utility/collapse",
                            name = name .. "/*button",
                            handler = { [defines.events.on_gui_click] = on_button_table_clicked },
                        },
                        {
                            type = "label",
                            caption = tostring(k) .. " : "
                        }
                    },
                    {
                        type = "flow",
                        style_mods = {vertically_squashable=true},
                        name = name,
                        direction = "horizontal",
                        {
                            type = "line",
                            style_mods = {vertically_squashable=true },
                            direction = "vertical"
                        },
                        {
                            type = "flow",
                            style_mods = {vertically_squashable=true},
                            name = name .. "flow",
                            direction = "vertical",
                        }
                    }
                }
                local elems = gui.add(elem[flowname], flow)
                for i, j in pairs(elems) do
                    elem[i] = j
                end
                update_data(v, elem, name .. "flow")
            else
                gui.add(elem[flowname],
                    {
                        type = "flow",
                        style_mods = {vertically_squashable=true},
                        direction = "horizontal",
                        {
                            type = "label",
                            caption = tostring(k) .. " : {}"
                        }
                    })
            end
        else
            gui.add(elem[flowname],
                {
                    type = "flow",
                    style_mods = {vertically_squashable=true},
                    direction = "horizontal",
                    {
                        type = "label",
                        caption = tostring(k) .. " : " .. tostring(v)
                    }
                })
        end
    end
end

--- @param e EventData.on_gui_click
local function on_button_data_clicked(e)
    local player = game.players[e.player_index]
    if not player then return end
    local item = player.cursor_stack
    local elems = global.lihop_tagReaderView_state[e.player_index].elems
    elems.tags_flow.clear()
    if not item or not item.valid or not item.valid_for_read then 
        update_data({"No Item"}, elems, "tags_flow")
    else
        if item.is_item_with_tags then
            local tag = item.tags
            update_data(tag, elems, "tags_flow")
        else
            update_data({"Not an Item with tags"}, elems, "tags_flow")
        end
    end
end

--- @param e EventData.on_gui_click
local function on_button_copy_clicked(e)
    local player = game.players[e.player_index]
    if not player then return end
    local item = player.cursor_stack
    if not item or not item.valid or not item.valid_for_read then 
        return
    else
        if item.is_item_with_tags then
            player.cursor_stack.set_stack({name=item.name,count=item.count+1,tags=item.tags})
        else
            return
        end
    end
end

--- @param e EventData.on_gui_click
local function show(e, elems)
    elems.lihop_tagReader_Main.visible  = true
    game.players[e.player_index].opened = elems.lihop_tagReader_Main
end

--- @param e EventData.on_gui_click
local function hide(e, elems)
    if not elems then
        elems = global.lihop_tagReaderView_state[e.player_index].elems
    end
    elems.lihop_tagReader_Main.visible = false
    game.players[e.player_index].opened = nil
end



--- @param e EventData.on_gui_click
local function toggle_visible(e)
    local elems = global.lihop_tagReaderView_state[e.player_index].elems
    if elems.lihop_tagReader_Main.visible then
        hide(e, elems)
    else
        show(e, elems)
        if debug then
            local player = game.players[e.player_index]
            player.cursor_stack.set_stack({ name = "item-with-tags", count = 1 })
            player.cursor_stack.tags = { test = 1, tab = { a = 1, b = 2 } }
        end
    end
end

local function created_duplicated_button()
    if game.active_mods["Factor-y"] then -- or modsettings ?
        return action_button("copybutton",{"gui.copytag"}, {"gui.copytooltip"}, on_button_copy_clicked)
    else
        return {}
    end
end

local tagReader = {}

--- @param e EventData.on_gui_closed
function tagReader.on_gui_closed(e)
    hide(e, nil)
end

--- Build the GUI for the given player.
--- @param player LuaPlayer
function tagReader.build(player)
    local elems = gui.add(player.gui.screen, {
        type = "frame",
        name = "lihop_tagReader_Main",
        direction = "vertical",
        style_mods = { size={500,700}},
        elem_mods = { auto_center = true },
        {
            type = "flow",
            style = "flib_titlebar_flow",
            drag_target = "lihop_tagReader_Main",

            { type = "label",        style = "frame_title",               caption = { "gui.tag-viewer" }, ignored_by_interaction = true },
            { type = "empty-widget", style = "flib_titlebar_drag_handle", ignored_by_interaction = true },
            frame_action_button("close_button", "utility/close", { "gui.close-instruction" }, hide),
        },
        {
            type = "frame",
            style = "inside_shallow_frame",
            style_mods = { horizontally_stretchable = true }, --{ width = 500 },
            direction = "vertical",
            {
                type = "frame",
                style = "subheader_frame",
                action_button("databutton",{"gui.seetag"}, {"gui.tagtooltip"}, on_button_data_clicked),
                created_duplicated_button()
            },
            {
                type = "scroll-pane",
                style = "flib_naked_scroll_pane_no_padding",
                style_mods = {  horizontally_stretchable = true, },
                {
                    type = "flow",
                    name = "tags_flow",
                    style_mods = { vertical_spacing = 8, padding = 12,vertically_squashable=true },
                    direction = "vertical",
                },
            },
        },
    })
    elems.lihop_tagReader_Main.visible = false
    global.lihop_tagReaderView_state[player.index] = {
        elems = elems,
        player = player,
    }
    local button_flow = mod_gui.get_button_flow(player) --[[@as LuaGuiElement]]
    gui.add(button_flow, {
        type = "sprite-button",
        name="TagViewer",
        style = mod_gui.button_style,
        sprite = "lihop-tagviewer",
        handler = toggle_visible,
    })
end

gui.add_handlers({
    hide = hide,
    toggle_visible = toggle_visible,
    on_button_data_clicked = on_button_data_clicked,
    on_button_table_clicked = on_button_table_clicked,
    on_button_copy_clicked=on_button_copy_clicked,
})




return tagReader
