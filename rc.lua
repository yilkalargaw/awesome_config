--[[

     Awesome WM configuration template
     github.com/lcpz

--]]

local awesome, client, mouse, screen, tag = awesome, client, mouse, screen, tag
local ipairs, string, os, table, tostring, tonumber, type = ipairs, string, os, table, tostring, tonumber, type

local gears         = require("gears")
local awful         = require("awful")
                      require("awful.autofocus")
local wibox         = require("wibox")
local beautiful     = require("beautiful")
local naughty       = require("naughty")
local lain          = require("lain")
local menubar       = require("menubar")
local freedesktop   = require("freedesktop")
local hotkeys_popup = require("awful.hotkeys_popup").widget
                      require("awful.hotkeys_popup.keys")
local my_table      = awful.util.table or gears.table -- 4.{0,1} compatibility
local dpi           = require("beautiful.xresources").apply_dpi


local startup_programs = require("runonce")

if awesome.startup_errors then
    naughty.notify({ preset = naughty.config.presets.critical,
                     title = "Oops, there were errors during startup!",
                     text = awesome.startup_errors })
end

-- Handle runtime errors after startup
do
    local in_error = false
    awesome.connect_signal("debug::error", function (err)
        if in_error then return end
        in_error = true

        naughty.notify({ preset = naughty.config.presets.critical,
                         title = "Oops, an error happened!",
                         text = tostring(err) })
        in_error = false
    end)
end

local function run_once(cmd_arr)
    for _, cmd in ipairs(cmd_arr) do
        awful.spawn.with_shell(string.format("pgrep -u $USER -fx '%s' > /dev/null || (%s)", cmd, cmd))
    end
end

-- run_once({ "urxvtd", "unclutter -root" }) -- entries must be separated by commas

local themes = {
    "blackburn",       -- 1
    "copland",         -- 2
    "dremora",         -- 3
    "holo",            -- 4
    "multicolor",      -- 5
    "powerarrow",      -- 6
    "powerarrow-dark", -- 7
    "rainbow",         -- 8
    "steamburn",       -- 9
    "vertex",          -- 10
    "myvertex",        -- 11
    "myvertex_one",    -- 12
    "myvertex_embers", -- 13
    "myvertex_nordic", -- 14
}

local chosen_theme = themes[14]
local modkey       = "Mod4"
local altkey       = "Mod1"
local terminal     = "kitty"
local vi_focus     = false -- vi-like client focus - https://github.com/lcpz/awesome-copycats/issues/275
local cycle_prev   = true -- cycle trough all previous client or just the first -- https://github.com/lcpz/awesome-copycats/issues/274
local editor       = os.getenv("EDITOR") or "jmacs"
local gui_editor   = os.getenv("GUI_EDITOR") or "flatpak run org.gnome.gedit"
local browser      = os.getenv("BROWSER") or "firefox"
local scrlocker    = "xscreensaver-command -l"

awful.util.terminal = terminal
awful.util.tagnames = { "1", "2", "3", "4", "5", "6", "7", "8", "9"}
awful.layout.layouts = {
    awful.layout.suit.floating,
    awful.layout.suit.tile,
    awful.layout.suit.tile.left,
    awful.layout.suit.tile.bottom,
    awful.layout.suit.tile.top,
    awful.layout.suit.fair,
    awful.layout.suit.fair.horizontal,
    -- awful.layout.suit.spiral,
    -- awful.layout.suit.spiral.dwindle,
    awful.layout.suit.max,
    awful.layout.suit.max.fullscreen,
    awful.layout.suit.magnifier,
    -- awful.layout.suit.corner.nw,
    -- awful.layout.suit.corner.ne,
    -- awful.layout.suit.corner.sw,
    -- awful.layout.suit.corner.se,
    -- lain.layout.cascade,
    -- lain.layout.cascade.tile,
    -- lain.layout.centerwork,
    -- lain.layout.centerwork.horizontal,
    -- lain.layout.termfair,
    -- lain.layout.termfair.center,
}

awful.util.taglist_buttons = my_table.join(
    awful.button({ }, 1, function(t) t:view_only() end),
    awful.button({ modkey }, 1, function(t)
        if client.focus then
            client.focus:move_to_tag(t)
        end
    end),
    awful.button({ }, 3, awful.tag.viewtoggle),
    awful.button({ modkey }, 3, function(t)
        if client.focus then
            client.focus:toggle_tag(t)
        end
    end),
    awful.button({ }, 4, function(t) awful.tag.viewnext(t.screen) end),
    awful.button({ }, 5, function(t) awful.tag.viewprev(t.screen) end)
)

awful.util.tasklist_buttons = my_table.join(
    awful.button({ }, 1, function (c)
        if c == client.focus then
            c.minimized = true
        else
            --c:emit_signal("request::activate", "tasklist", {raise = true})<Paste>

            -- Without this, the following
            -- :isvisible() makes no sense
            c.minimized = false
            if not c:isvisible() and c.first_tag then
                c.first_tag:view_only()
            end
            -- This will also un-minimize
            -- the client, if needed
            client.focus = c
            c:raise()
        end
    end),
    awful.button({ }, 2, function (c) c:kill() end),
    awful.button({ }, 3, function ()
        local instance = nil

        return function ()
            if instance and instance.wibox.visible then
                instance:hide()
                instance = nil
            else
                instance = awful.menu.clients({theme = {width = dpi(250)}})
            end
        end
    end),
    awful.button({ }, 4, function () awful.client.focus.byidx(1) end),
    awful.button({ }, 5, function () awful.client.focus.byidx(-1) end)
)

lain.layout.termfair.nmaster           = 3
lain.layout.termfair.ncol              = 1
lain.layout.termfair.center.nmaster    = 3
lain.layout.termfair.center.ncol       = 1
lain.layout.cascade.tile.offset_x      = dpi(2)
lain.layout.cascade.tile.offset_y      = dpi(32)
lain.layout.cascade.tile.extra_padding = dpi(5)
lain.layout.cascade.tile.nmaster       = 5
lain.layout.cascade.tile.ncol          = 2

beautiful.init(string.format("%s/.config/awesome/themes/%s/theme.lua", os.getenv("HOME"), chosen_theme))
-- }}}

-- {{{ Menu
local myawesomemenu = {
    { "hotkeys", function() return false, hotkeys_popup.show_help end },
    { "manual", terminal .. " -e man awesome" },
    { "edit config", string.format("%s -e %s %s", terminal, editor, awesome.conffile) },
    { "restart", awesome.restart },
    { "quit", function() awesome.quit() end }
}
----[[
awful.util.mymainmenu = freedesktop.menu.build({
    icon_size = beautiful.menu_height or dpi(16),
    before = {
        { "Awesome", myawesomemenu, beautiful.awesome_icon },
        -- other triads can be put here
    },
    after = {
        { "Open terminal", terminal },
        -- other triads can be put here
    }
})
--]]
-- hide menu when mouse leaves it
--awful.util.mymainmenu.wibox:connect_signal("mouse::leave", function() awful.util.mymainmenu:hide() end)

menubar.utils.terminal = terminal -- Set the Menubar terminal for applications that require it
-- }}}

--[[
-- {{{ Screen
-- Re-set wallpaper when a screen's geometry changes (e.g. different resolution)
screen.connect_signal("property::geometry", function(s)
    -- Wallpaper
    if beautiful.wallpaper then
        local wallpaper = beautiful.wallpaper
        -- If wallpaper is a function, call it with the screen
        if type(wallpaper) == "function" then
            wallpaper = wallpaper(s)
        end
        gears.wallpaper.maximized(wallpaper, s, true)
    end
end)

--]]

--[[
-- No borders when rearranging only 1 non-floating or maximized client
screen.connect_signal("arrange", function (s)
    local only_one = #s.tiled_clients == 1
    for _, c in pairs(s.clients) do
        if only_one and not c.floating or c.maximized then
            c.border_width = 1
        else
            c.border_width = beautiful.border_width
        end
    end
end)
==]]

-- Create a wibox for each screen and add it
awful.screen.connect_for_each_screen(function(s) beautiful.at_screen_connect(s) end)
-- }}}

root.buttons(my_table.join(
--    awful.button({ }, 3, function () awful.util.mymainmenu:toggle() end),
    awful.button({ }, 4, awful.tag.viewnext),
    awful.button({ }, 5, awful.tag.viewprev)
))

-- {{{ Key bindings
globalkeys = gears.table.join(
    awful.key({ modkey,           }, "s",      hotkeys_popup.show_help,
              {description="show help", group="awesome"}),
    awful.key({ modkey,           }, "Left",   awful.tag.viewprev,
              {description = "view previous", group = "tag"}),
    awful.key({ modkey,           }, "Right",  awful.tag.viewnext,
              {description = "view next", group = "tag"}),
    awful.key({ modkey,           }, "Escape", awful.tag.history.restore,
              {description = "go back", group = "tag"}),

    awful.key({ modkey,           }, "j",
        function ()
            awful.client.focus.byidx( 1)
        end,
        {description = "focus next by index", group = "client"}
    ),
    awful.key({ modkey,           }, "k",
        function ()
            awful.client.focus.byidx(-1)
        end,
        {description = "focus previous by index", group = "client"}
    ),
    awful.key({ modkey,           }, "w", function () mymainmenu:show() end,
              {description = "show main menu", group = "awesome"}),

    -- Layout manipulation
    awful.key({ modkey, "Shift"   }, "j", function () awful.client.swap.byidx(  1)    end,
              {description = "swap with next client by index", group = "client"}),
    awful.key({ modkey, "Shift"   }, "k", function () awful.client.swap.byidx( -1)    end,
              {description = "swap with previous client by index", group = "client"}),
    awful.key({ modkey, "Control" }, "j", function () awful.screen.focus_relative( 1) end,
              {description = "focus the next screen", group = "screen"}),
    awful.key({ modkey, "Control" }, "k", function () awful.screen.focus_relative(-1) end,
              {description = "focus the previous screen", group = "screen"}),
    awful.key({ modkey,           }, "u", awful.client.urgent.jumpto,
              {description = "jump to urgent client", group = "client"}),
    awful.key({ modkey,           }, "Tab",
        function ()
            awful.client.focus.history.previous()
            if client.focus then
                client.focus:raise()
            end
        end,
        {description = "go back", group = "client"}),

      -- Show/Hide Wibox
    awful.key({ modkey }, "b", function ()
            for s in screen do
                s.mywibox.visible = not s.mywibox.visible
                if s.mybottomwibox then
                    s.mybottomwibox.visible = not s.mybottomwibox.visible
                end
            end
        end,
        {description = "toggle wibox", group = "awesome"}),

    -- On the fly useless gaps change
    awful.key({ modkey }, "=", function () lain.util.useless_gaps_resize(1) end,
              {description = "increment useless gaps", group = "tag"}),
    awful.key({ modkey }, "-", function () lain.util.useless_gaps_resize(-1) end,
              {description = "decrement useless gaps", group = "tag"}),

    -- Dynamic tagging
    awful.key({ modkey, "Shift" }, "n", function () lain.util.add_tag() end,
              {description = "add new tag", group = "tag"}),
    awful.key({ modkey, "Shift" }, "r", function () lain.util.rename_tag() end,
              {description = "rename tag", group = "tag"}),
    awful.key({ modkey, "Shift" }, "Left", function () lain.util.move_tag(-1) end,
              {description = "move tag to the left", group = "tag"}),
    awful.key({ modkey, "Shift" }, "Right", function () lain.util.move_tag(1) end,
              {description = "move tag to the right", group = "tag"}),
    awful.key({ modkey, "Shift" }, "d", function () lain.util.delete_tag() end,
              {description = "delete tag", group = "tag"}),

    -- Standard program
    awful.key({ modkey,           }, "Return", function () awful.spawn(terminal) end,
              {description = "open a terminal", group = "launcher"}),
    awful.key({ modkey, "Control" }, "r", awesome.restart,
              {description = "reload awesome", group = "awesome"}),

--    awful.key({ modkey, "Shift"   }, "q", awesome.quit,
--              {description = "quit awesome", group = "awesome"}),

    awful.key({ modkey,           }, "l",     function () awful.tag.incmwfact( 0.05)          end,
              {description = "increase master width factor", group = "layout"}),
    awful.key({ modkey,           }, "h",     function () awful.tag.incmwfact(-0.05)          end,
              {description = "decrease master width factor", group = "layout"}),
    awful.key({ modkey, "Shift"   }, "h",     function () awful.tag.incnmaster( 1, nil, true) end,
              {description = "increase the number of master clients", group = "layout"}),
    awful.key({ modkey, "Shift"   }, "l",     function () awful.tag.incnmaster(-1, nil, true) end,
              {description = "decrease the number of master clients", group = "layout"}),
    awful.key({ modkey, "Control" }, "h",     function () awful.tag.incncol( 1, nil, true)    end,
              {description = "increase the number of columns", group = "layout"}),
    awful.key({ modkey, "Control" }, "l",     function () awful.tag.incncol(-1, nil, true)    end,
              {description = "decrease the number of columns", group = "layout"}),
    awful.key({ modkey,           }, "space", function () awful.layout.inc( 1)                end,
              {description = "select next", group = "layout"}),
    awful.key({ modkey, "Shift"   }, "space", function () awful.layout.inc(-1)                end,
              {description = "select previous", group = "layout"}),

    awful.key({ modkey, "Control" }, "n",
              function ()
                  local c = awful.client.restore()
                  -- Focus restored client
                  if c then
                      client.focus = c
                      c:raise()
                  end
              end,
              {description = "restore minimized", group = "client"}),

    -- Prompt
    awful.key({ modkey },            "r",     function () awful.screen.focused().mypromptbox:run() end,
              {description = "run prompt", group = "launcher"}),

    awful.key({ modkey }, "x",
              function ()
                  awful.prompt.run {
                    prompt       = "Run Lua code: ",
                    textbox      = awful.screen.focused().mypromptbox.widget,
                    exe_callback = awful.util.eval,
                    history_path = awful.util.get_cache_dir() .. "/history_eval"
                  }
              end,
              {description = "lua execute prompt", group = "awesome"}),
    -- Menubar
    awful.key({ modkey }, "p", function() menubar.show() end,
              {description = "show the menubar", group = "launcher"}),


------------------------------------------------------------------------
   -- Volume Keys
   awful.key({}, "XF86AudioLowerVolume", function ()
     awful.util.spawn("amixer -q -D pulse sset Master 5%-", false)
   end),
   awful.key({}, "XF86AudioRaiseVolume", function ()
     awful.util.spawn("amixer -q -D pulse sset Master 5%+", false)
   end),
   awful.key({}, "XF86AudioMute", function ()
     awful.util.spawn("amixer -D pulse set Master 1+ toggle", false)
   end),



--	--screensaver , screenshot and screen casting
--        awful.key({"Mod4" }, "\\"  , function ()
--                  awful.util.spawn_with_shell("catfish") end),

--    -- X screen locker
--    awful.key({ modkey, "Control" }, "Delete", function () os.execute(scrlocker) end,
--              {description = "lock screen", group = "hotkeys"}),

       awful.key({ modkey, "Control" }, "Delete", function ()
	      awful.util.spawn_with_shell("xscreensaver-command -l") end),
       awful.key({ modkey, "Shift" }, "Delete", function ()
	      awful.util.spawn_with_shell("lxqt-leave") end),

--	awful.key({ modkey, "Shift" }, "Delete", function ()
--	      awful.util.spawn_with_shell("lxsession-logout") end),
--	awful.key({"Mod4" }, "i"  , function ()
--	      awful.util.spawn_with_shell("rofi -theme Arc-Dark -combi-modi run,drun -show combi -modi combi") end),
--	awful.key({"Mod4" }, ","  , function ()
--	      awful.util.spawn_with_shell("rofi -theme Arc-Dark  -show window") end)


--        awful.key({modkey, "Shift" }, "q" , function ()
--                 awful.util.spawn("xfce4-session-logout") end),
--        awful.key({ }, "Print" , function ()
--                 awful.util.spawn("xfce4-screenshooter -f") end),
--        awful.key({"Control" }, "Print"  , function ()
--                 awful.util.spawn_with_shell("xfce4-screenshooter -w") end),
--       awful.key({"Mod4" }, "Print"  , function ()
--               awful.util.spawn_with_shell("xfce4-screenshooter -r") end)
--        awful.key({ }, "Print" , function ()
--                 awful.util.spawn("mate-screenshoot") end),
--        awful.key({"Control" }, "Print"  , function ()
--                 awful.util.spawn_with_shell("mate-screenshoot -w") end),
--        awful.key({"Mod4" }, "Print"  , function ()
--                 awful.util.spawn_with_shell("mate-screenshoot -r") end),

--       awful.key({ "Mod4" }, "p", function ()
--	      awful.util.spawn_with_shell("xfce4-popup-whiskermenu") end)

--	-- Brightness
--
--   awful.key({ }, "XF86MonBrightnessDown", function ()
--       awful.util.spawn("xbacklight -dec 5") end),
--   awful.key({ }, "XF86MonBrightnessUp", function ()
--       awful.util.spawn("xbacklight -inc 5") end)

--    -- Brightness
    awful.key({ modkey, "Control" }, "KP_Add", function () os.execute("lxqt-config-brightness -i 20") end),
    awful.key({ modkey, "Control" }, "KP_Subtract", function () os.execute("lxqt-config-brightness -d 20") end),
    awful.key({ modkey, "Control" }, "]", function () os.execute("lxqt-config-brightness -i 20") end),
    awful.key({ modkey, "Control" }, "[", function () os.execute("lxqt-config-brightness -d 20") end)

------------------------------------------------------------------------
)

clientkeys = gears.table.join(
    awful.key({ modkey,           }, "f",
        function (c)
            c.fullscreen = not c.fullscreen
            c:raise()
        end,
        {description = "toggle fullscreen", group = "client"}),
    awful.key({ modkey, "Shift"   }, "c",      function (c) c:kill()                         end,
              {description = "close", group = "client"}),
    awful.key({ modkey, "Control" }, "space",  awful.client.floating.toggle                     ,
              {description = "toggle floating", group = "client"}),
    awful.key({ modkey, "Control" }, "Return", function (c) c:swap(awful.client.getmaster()) end,
              {description = "move to master", group = "client"}),
    awful.key({ modkey,           }, "o",      function (c) c:move_to_screen()               end,
              {description = "move to screen", group = "client"}),
    awful.key({ modkey,           }, "t",      function (c) c.ontop = not c.ontop            end,
              {description = "toggle keep on top", group = "client"}),
    awful.key({ modkey,           }, "n",
        function (c)
            -- The client currently has the input focus, so it cannot be
            -- minimized, since minimized clients can't have the focus.
            c.minimized = true
        end ,
        {description = "minimize", group = "client"}),
    awful.key({ modkey,           }, "m",
        function (c)
            c.maximized = not c.maximized
            c:raise()
        end ,
        {description = "(un)maximize", group = "client"}),
    awful.key({ modkey, "Control" }, "m",
        function (c)
            c.maximized_vertical = not c.maximized_vertical
            c:raise()
        end ,
        {description = "(un)maximize vertically", group = "client"}),
    awful.key({ modkey, "Shift"   }, "m",
        function (c)
            c.maximized_horizontal = not c.maximized_horizontal
            c:raise()
        end ,
        {description = "(un)maximize horizontally", group = "client"})
)

-- Bind all key numbers to tags.
-- Be careful: we use keycodes to make it work on any keyboard layout.
-- This should map on the top row of your keyboard, usually 1 to 9.
for i = 1, 9 do
    globalkeys = gears.table.join(globalkeys,
        -- View tag only.
        awful.key({ modkey }, "#" .. i + 9,
                  function ()
                        local screen = awful.screen.focused()
                        local tag = screen.tags[i]
                        if tag then
                           tag:view_only()
                        end
                  end,
                  {description = "view tag #"..i, group = "tag"}),
        -- Toggle tag display.
        awful.key({ modkey, "Control" }, "#" .. i + 9,
                  function ()
                      local screen = awful.screen.focused()
                      local tag = screen.tags[i]
                      if tag then
                         awful.tag.viewtoggle(tag)
                      end
                  end,
                  {description = "toggle tag #" .. i, group = "tag"}),
        -- Move client to tag.
        awful.key({ modkey, "Shift" }, "#" .. i + 9,
                  function ()
                      if client.focus then
                          local tag = client.focus.screen.tags[i]
                          if tag then
                              client.focus:move_to_tag(tag)
                          end
                     end
                  end,
                  {description = "move focused client to tag #"..i, group = "tag"}),
        -- Toggle tag on focused client.
        awful.key({ modkey, "Control", "Shift" }, "#" .. i + 9,
                  function ()
                      if client.focus then
                          local tag = client.focus.screen.tags[i]
                          if tag then
                              client.focus:toggle_tag(tag)
                          end
                      end
                  end,
                  {description = "toggle focused client on tag #" .. i, group = "tag"})
    )
end

clientbuttons = gears.table.join(
    awful.button({ }, 1, function (c) client.focus = c; c:raise() end),
    awful.button({ modkey }, 1, awful.mouse.client.move),
    awful.button({ modkey }, 3, awful.mouse.client.resize))

-- Set keys
root.keys(globalkeys)
-- }}}

function custom_focus_filter(c)
    if global_focus_disable then
        return nil
    end
    return awful.client.focus.filter(c)
end

awful.rules.rules = {
    -- All clients will match this rule.
    { rule = { },
      properties = { border_width = beautiful.border_width,
                     border_color = beautiful.border_normal,
                     focus = awful.client.focus.filter,
                     raise = true,
                     keys = clientkeys,
                     buttons = clientbuttons,
                     screen = awful.screen.preferred,
                     placement = awful.placement.no_overlap+awful.placement.no_offscreen,
                     size_hints_honor = false
     }
    },

    -- Titlebars

--    { rule_any = { type = { "dialog, normal" } },
--      properties = { titlebars_enabled = true } },

    { rule_any = { type = { "normal" } },
      properties = { titlebars_enabled = false } },

    { rule_any = { type = { "dialog" } },
      properties = { titlebars_enabled = false } },

    { rule_any = { type = { "desktop" } },
      properties = { sticky = true, border_width = 0} },

    -- Set Emacs to always map on the tag named "emacs" on screen 1.
    { rule = { class = "Emacs" },
      properties = {tag = "emacs", maximized = true } },

    -- Set browsers to alway map on the tag named "web"
    { rule_any = { class = { "Firefox",
			     "firefox",
			     "Mozilla Firefox",
			     "Chromium",
			     "Opera",
			     "Midori",
			     "Vivaldi",
			     "Basilisk",
			     "Brave",
			     "IceCat",
			     "LibreWolf",
                             "librewolf",
			     "microsoft-edge-dev",
			     "Microsoft-edge-dev",
			     "microsoft-edge",
			     "Microsoft-edge",
			     "google-chrome",
			     "Google-chrome",
			     "Falkon",
			     "Falkon Browser", },
		   name = {"Pale Moon", }},
      properties = {tag = "web" }},

    { rule_any = { name = { "GNU Image Manipulation Program",
			    "MyPaint",
			    "Inkscape",
			    "krita" }},
      properties = { maximized = true } },

    { rule = { name = "Whisker Menu" },
      properties = {floating = true } },

    { rule = { role = "xfce4-terminal-dropdown" },
      properties = {floating = true } },
      
    { rule = { class = "Xfce4-panel" },
      properties = { ontop=true, border_width = 0 } },

--    { rule = { name = "xfdashboard" },
--      properties = { maximized=true, floating=true, ontop=true, border_width = 0 } },


     -- -- I need rules to raise xfce4-to the top when focused
     -- { rule = { class = "xfce4-panel" },
     --   properties = {raise = true } },


    -- Set Firefox to always map on the first tag on screen 1.
    --  { rule = { class = "Firefox" },
    --    properties = { screen = 1, tag = awful.util.tagnames[1] } },

      -- { rule = { name = "pcmanfm-qt" },
      --   properties = { sticky = true, border_width = 0, focus=false} },

     -- { rule = { class = "pcmanfm-qt" },
     --   properties = { floating = true, sticky = true, ontop = true, above = true, border_width = 0},
     --   callback = awful.placement.centered },

      -- { rule = { name = "pcmanfm" },
      --   properties = { sticky = true, border_width = 0, focus=false} },

      { rule = { name = "conky" },
        properties = { sticky = true, border_width = 0, focus=false} },


}

-- Signal function to execute when a new client appears.
client.connect_signal("manage", function (c)
    -- Set the windows at the slave,
    -- i.e. put it at the end of others instead of setting it master.
    -- if not awesome.startup then awful.client.setslave(c) end

    if awesome.startup and
      not c.size_hints.user_position
      and not c.size_hints.program_position then
        -- Prevent clients from being unreachable after screen count changes.
        awful.placement.no_offscreen(c)
    end
end)

-- Add a titlebar if titlebars_enabled is set to true in the rules.
client.connect_signal("request::titlebars", function(c)
    -- Custom
    if beautiful.titlebar_fun then
        beautiful.titlebar_fun(c)
        return
    end

    -- Default
    -- buttons for the titlebar
    local buttons = my_table.join(
        awful.button({ }, 1, function()
            c:emit_signal("request::activate", "titlebar", {raise = true})
            awful.mouse.client.move(c)
        end),
        awful.button({ }, 2, function() c:kill() end),
        awful.button({ }, 3, function()
            c:emit_signal("request::activate", "titlebar", {raise = true})
            awful.mouse.client.resize(c)
        end)
    )

    awful.titlebar(c, {size = dpi(16)}) : setup {
        { -- Left
            awful.titlebar.widget.iconwidget(c),
            buttons = buttons,
            layout  = wibox.layout.fixed.horizontal
        },
        { -- Middle
            { -- Title
                align  = "center",
                widget = awful.titlebar.widget.titlewidget(c)
            },
            buttons = buttons,
            layout  = wibox.layout.flex.horizontal
        },
        { -- Right
            awful.titlebar.widget.floatingbutton (c),
            awful.titlebar.widget.maximizedbutton(c),
            awful.titlebar.widget.stickybutton   (c),
            awful.titlebar.widget.ontopbutton    (c),
            awful.titlebar.widget.closebutton    (c),
            layout = wibox.layout.fixed.horizontal()
        },
        layout = wibox.layout.align.horizontal
    }
end)

--[[
-- Enable sloppy focus, so that focus follows mouse.
client.connect_signal("mouse::enter", function(c)
    c:emit_signal("request::activate", "mouse_enter", {raise = vi_focus})
end)
--]]

client.connect_signal("focus", function(c) c.border_color = beautiful.border_focus end)
client.connect_signal("unfocus", function(c) c.border_color = beautiful.border_normal end)

-- startup_programs.run("xfsettingsd")
-- startup_programs.run("mate-settings-daemon")
-- startup_programs.run("/usr/libexec/mate-settings-daemon")
-- startup_programs.run("/usr/libexec/polkit-mate-authentication-agent-1")
-- startup_programs.run("mate-session")
-- startup_programs.run("caja -n")
-- startup_programs.run("lxsession")
-- startup_programs.run("lxsettings-daemon")
   startup_programs.run("xsettingsd")
-- startup_programs.run("start-pulseaudio-x11")
   startup_programs.run("nm-applet")
   startup_programs.run("picom")
-- startup_programs.run("xfce4-power-manager")
-- startup_programs.run("xfce4-power-manager --restart")
-- startup_programs.run("mate-power-manager")
-- startup_programs.run(" lxqt-powermanagement")
   startup_programs.run("conky -c ~/.config/conky/conkyrc")
-- startup_programs.run("mate-volume-control-status-icon")
   startup_programs.run("lxpolkit")
   startup_programs.run("ibus-daemon -drx")
-- startup_programs.run("/usr/libexec/xfce-polkit")
   startup_programs.run("xscreensaver -no-splash")
   startup_programs.run("udiskie -A -t")
-- startup_programs.run("abrt-applet")
-- startup_programs.run("blueberry-tray")
-- startup_programs.run("dnfdragora-updater")

   startup_programs.run("xmodmap ~/.Xmodmap")
-- startup_programs.run("sleep 15s ; volumeicon &")

-- startup_programs.run("sh ~/.mouse.sh")
-- startup_programs.run("sh ~/.mykeys.sh")

-- startup_programs.run("xfce4-panel")
-- startup_programs.run("ulauncher")
--
--startup_programs.run("~/.config/awesome/wallpaper.sh")

-- scan directory, and optionally filter outputs
function scandir(directory, filter)
   local i, t, popen = 0, {}, io.popen
   if not filter then
      filter = function(s) return true end
   end
   print(filter)
   for filename in popen('ls -a "'..directory..'"'):lines() do
      if filter(filename) then
	 i = i + 1
	 t[i] = filename
      end
   end
   return t
end

-- }}}
---[[
-- this part deals with setting images from the wallpaper directories as a wallpaper in slideshow mode  
-- configuration - edit to your liking
wp_index = 1
wp_timeout  = 300
wp_path = (string.format("%s/.config/awesome/wallpapers/", os.getenv("HOME")))
wp_filter = function(s) return string.match(s,"%.png$") or string.match(s,"%.jpg$") end
wp_files = scandir(wp_path, wp_filter)

wp_index = math.random( 1, #wp_files)

for s = 1, screen.count() do
   gears.wallpaper.maximized(wp_path .. wp_files[wp_index], s, true)
end

-- setup the timer
wp_timer = timer { timeout = wp_timeout }
wp_timer:connect_signal("timeout", function()

			   -- set wallpaper to current index for all screens
			   for s = 1, screen.count() do
			      gears.wallpaper.maximized(wp_path .. wp_files[wp_index], s, true)
			   end

			   -- stop the timer (we don't need multiple instances running at the same time)
			   wp_timer:stop()

			   -- get next random index
			   wp_index = math.random( 1, #wp_files)

			   --restart the timer
			   wp_timer.timeout = wp_timeout
			   wp_timer:start()
end)

-- initial start when rc.lua is first run
wp_timer:start()
--]]
