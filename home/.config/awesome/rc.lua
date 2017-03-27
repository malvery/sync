-- Standard awesome library
local gears = require("gears")
local awful = require("awful")
require("awful.autofocus")
-- Widget and layout library
local wibox = require("wibox")
-- Theme handling library
local beautiful = require("beautiful")
-- Notification library
local naughty = require("naughty")
local menubar = require("menubar")
local hotkeys_popup = require("awful.hotkeys_popup").widget

--widgets
local vicious = require("vicious") 

-- Custom hosts rules -------------------------
require("host_conf")

local popen = assert(io.popen('hostname', 'r'))
local conf_hostname = popen:read('*all')

popen:close()

--naughty.notify({ text = conf_hostname })
local host_conf = getConfList(conf_hostname)
----------------------------------------------

-- {{{ Error handling
-- Check if awesome encountered an error during startup and fell back to
-- another config (This code will only ever execute for the fallback config)
if awesome.startup_errors then
    naughty.notify({ preset = naughty.config.presets.critical,
                     title = "Oops, there were errors during startup!",
                     text = awesome.startup_errors })
end

-- Handle runtime errors after startup
do
    local in_error = false
    awesome.connect_signal("debug::error", function (err)
        -- Make sure we don't go into an endless error loop
        if in_error then return end
        in_error = true

        naughty.notify({ preset = naughty.config.presets.critical,
                         title = "Oops, an error happened!",
                         text = tostring(err) })
        in_error = false
    end)
end
-- }}}

-- {{{ Variable definitions
-- Themes define colours, icons, font and wallpapers.
--naughty.notify({ text = awful.util.get_configuration_dir() .. host_conf.theme })
beautiful.init(awful.util.get_configuration_dir() .. host_conf.theme)

-- This is used later as the default terminal and editor to run.
terminal = "urxvt"
editor = os.getenv("EDITOR") or "nano"
editor_cmd = terminal .. " -e " .. editor

-- Default modkey.
-- Usually, Mod4 is the key with a logo between Control and Alt.
-- If you do not like this or do not have such a key,
-- I suggest you to remap Mod4 to another key using xmodmap or other tools.
-- However, you can use another modifier like Mod1, but it may interact with others.
modkey = "Mod4"

-- Table of layouts to cover with awful.layout.inc, order matters.
awful.layout.layouts = {
    awful.layout.suit.tile,
    awful.layout.suit.tile.bottom,
    awful.layout.suit.max,
    awful.layout.suit.floating,
}
-- }}}

-- {{{ Helper functions
local function client_menu_toggle_fn()
    local instance = nil

    return function ()
        if instance and instance.wibox.visible then
            instance:hide()
            instance = nil
        else
            instance = awful.menu.clients({ theme = { width = 250 } })
        end
    end
end
-- }}}

-- {{{ Menu
-- Create a launcher widget and a main menu
myawesomemenu = {
	 { "open terminal", terminal },
   { "quit", function() awesome.quit() end },
	 { "restart", awesome.restart }
}

exit_menu = {
	 { "Shutdowm", "systemctl poweroff" },
	 { "Reboot", "systemctl reboot" },
	 { "Suspend", "systemctl suspend" },
	 { "Logout", function() awesome.quit() end }
}

mymainmenu = awful.menu({ items = {
		{ "Awesome", myawesomemenu, beautiful.awesome_icon },
		{ "" },
		{ "Files",		host_conf.d_apps.file_manager },
		{ "Player",		host_conf.d_apps.media_player },
		{ "Torrent",	host_conf.d_apps.torrents			},
		{ "Browser",	host_conf.d_apps.browser			},
		{ "" },
		{ "Lock",			host_conf.d_apps.lock_manager },
		{ "Exit",			exit_menu									}
	}
})

mylauncher = awful.widget.launcher({ image = beautiful.awesome_icon,
                                     menu = mymainmenu })

-- Menubar configuration
menubar.utils.terminal = terminal -- Set the terminal for applications that require it
-- }}}

-- Keyboard map indicator and switcher
mykeyboardlayout = awful.widget.keyboardlayout()

-- {{{ Wibar
-- Create a textclock widget
mytextclock = wibox.widget.textclock()

-- Create a wibox for each screen and add it
local taglist_buttons = awful.util.table.join(
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

local tasklist_buttons = awful.util.table.join(
                     --[[awful.button({ }, 1, function (c)
                                              if c == client.focus then
                                                  c.minimized = true
                                              else
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
                                          end),]]
                     awful.button({ }, 3, client_menu_toggle_fn()),
                     awful.button({ }, 4, function ()
                                              awful.client.focus.byidx(1)
                                          end),
                     awful.button({ }, 5, function ()
                                              awful.client.focus.byidx(-1)
                                          end))

local function set_wallpaper(s)
    -- Wallpaper
    if beautiful.wallpaper then
        local wallpaper = beautiful.wallpaper
        -- If wallpaper is a function, call it with the screen
        if type(wallpaper) == "function" then
            wallpaper = wallpaper(s)
        end
        gears.wallpaper.maximized(wallpaper, s, true)
    end
end

-- Re-set wallpaper when a screen's geometry changes (e.g. different resolution)
screen.connect_signal("property::geometry", set_wallpaper)

-- Custom widgets ---------------------------
-- cpu
cpuwidget = wibox.widget.textbox()
vicious.register(cpuwidget, vicious.widgets.cpu, " CPU: $1% |")

-- mem
memwidget = wibox.widget.textbox()
vicious.register(memwidget, vicious.widgets.mem, " MEM: $1% |", 13)

-- eth
netwidget = wibox.widget.textbox() 

if host_conf.widget.network.name == 'net' then
	vicious.register(netwidget, vicious.widgets.net, " NET: ${" .. host_conf.widget.network.device .. " down_kb}Kb/s |", 13)
elseif host_conf.widget.network.name == 'wifi' then
	vicious.register(netwidget, vicious.widgets.wifi, " WLAN: ${ssid} ${linp}% |", 13, host_conf.widget.network.device)
end

-- volume
volwidget = wibox.widget.textbox() 
vicious.register(volwidget, vicious.widgets.volume, " VOL: $1% |", 2, "Master")

function volume(action)
	if action == "+" or action == "-" then
		awful.util.spawn("amixer -D pulse set Master 5%" .. action .. " unmute")
	elseif action == "toggle" then
		awful.util.spawn("amixer -D pulse set Master toggle")
	end
	vicious.force({ volwidget })
end

volwidget:buttons(awful.util.table.join(
	awful.button({ }, 3, function()
		volume("toggle")
	end),
	awful.button({ }, 4, function()
		volume("+")
	end),
	awful.button({ }, 5, function()
		volume("-")
	end)
))

-- batt
batwidget = wibox.widget.textbox()
vicious.register(batwidget, vicious.widgets.bat, " BAT: $2% :: ", 120 , "BAT0")

function backlight(action)
	if action == "dec" or action == "inc" then
		awful.util.spawn("xbacklight -" .. action .. " 2")
	end
end

batwidget:buttons(awful.util.table.join(
	awful.button({ }, 4, function()
		backlight("inc")
	end),
	awful.button({ }, 5, function()
		backlight("dec")
	end)
))
--
------------------------------------------------------

awful.screen.connect_for_each_screen(function(s)
    -- Wallpaper
    set_wallpaper(s)

    -- Each screen has its own tag table.
    awful.tag({ "1", "2", "3", "4", "5", "6", "7", "8", "9" }, s, awful.layout.layouts[1])

    -- Create a promptbox for each screen
    s.mypromptbox = awful.widget.prompt()
    -- Create an imagebox widget which will contains an icon indicating which layout we're using.
    -- We need one layoutbox per screen.
    s.mylayoutbox = awful.widget.layoutbox(s)
    s.mylayoutbox:buttons(awful.util.table.join(
                           awful.button({ }, 1, function () awful.layout.inc( 1) end),
                           awful.button({ }, 3, function () awful.layout.inc(-1) end),
                           awful.button({ }, 4, function () awful.layout.inc( 1) end),
                           awful.button({ }, 5, function () awful.layout.inc(-1) end)))
    -- Create a taglist widget
    s.mytaglist = awful.widget.taglist(s, awful.widget.taglist.filter.all, taglist_buttons)

    -- Create a tasklist widget
    s.mytasklist = awful.widget.tasklist(s, awful.widget.tasklist.filter.currenttags, tasklist_buttons)

    -- Create the wibox
    s.mywibox = awful.wibar({ position = "top", screen = s })

    -- Add widgets to the wibox
    s.mywibox:setup {
        layout = wibox.layout.align.horizontal,
        { -- Left widgets
            layout = wibox.layout.fixed.horizontal,
            mylauncher,
            s.mytaglist,
            s.mypromptbox,
        },
        s.mytasklist, -- Middle widget
        { -- Right widgets
            layout = wibox.layout.fixed.horizontal,
						cpuwidget,
						memwidget,
						netwidget,
						volwidget,
						batwidget,
						mykeyboardlayout,
            wibox.widget.systray(),
            mytextclock,
            s.mylayoutbox,
        },
    }
end)
-- }}}

-- {{{ Mouse bindings
root.buttons(awful.util.table.join(
    awful.button({ }, 3, function () mymainmenu:toggle() end),
    awful.button({ }, 4, awful.tag.viewnext),
    awful.button({ }, 5, awful.tag.viewprev)
))
-- }}}

-- {{{ Key bindings
globalkeys = awful.util.table.join(
    awful.key({ modkey,           }, "a",      hotkeys_popup.show_help,
              {description="show help", group="awesome"}),

    --[[awful.key({ modkey,           }, "Left",   awful.tag.viewprev,
              {description = "view previous", group = "tag"}),

    awful.key({ modkey,           }, "Right",  awful.tag.viewnext,
              {description = "view next", group = "tag"}),]]

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

    awful.key({ modkey, "Shift"   }, "m", function () mymainmenu:show() end,
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

    -- Standard program
    awful.key({ modkey, "Shift"   }, "Return", function () awful.spawn(terminal) end,
              {description = "open a terminal", group = "launcher"}),
    
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

							
		-- Custom screen navigation
		
		awful.key({ modkey,           }, "q",			function () awful.screen.focus( 1) end),
		awful.key({ modkey,           }, "w",			function () awful.screen.focus( 3) end),	
		awful.key({ modkey,           }, "e",			function () awful.screen.focus( 2) end),
		
		awful.key({ modkey, "Shift"   }, "q",			function (c) awful.client.movetoscreen(c, 1) end),
		awful.key({ modkey, "Shift"   }, "w",			function (c) awful.client.movetoscreen(c, 3) end),
		awful.key({ modkey, "Shift"   }, "e",			function (c) awful.client.movetoscreen(c, 2) end),
		
		--awful.key({ modkey,           }, "w",			function () awful.screen.focus_relative(-1) end),	
		--awful.key({ modkey,           }, "e",			function () awful.screen.focus_relative( 1) end),
	  --	
		--awful.key({ modkey, "Shift"   }, "w",			function (c) awful.client:move_to_screen(c.screen.index-1) end),
		--awful.key({ modkey, "Shift"   }, "e",			function (c) awful.client:move_to_screen(c.screen.index+1) end),


		-- Custom hotkeys
		awful.key({ modkey,           }, "r",			function () awful.util.spawn("gmrun") end),

	  awful.key({ modkey, "Shift"   }, "p",			function () awful.util.spawn(host_conf.d_apps.file_manager) end),
		awful.key({ modkey, "Shift"   }, "F12",		function () awful.util.spawn(host_conf.d_apps.lock_manager) end),

		awful.key({	}, "XF86AudioRaiseVolume",	function () awful.util.spawn("amixer -D pulse set Master 5%+ unmute") end),
		awful.key({ }, "XF86AudioLowerVolume",	function () awful.util.spawn("amixer -D pulse set Master 5%- unmute") end),
		awful.key({ }, "XF86AudioMute",					function () awful.util.spawn("amixer -D pulse set Master toggle") end),

		awful.key({ }, "XF86MonBrightnessUp",		function () awful.util.spawn("xbacklight -inc 2") end),
		awful.key({ }, "XF86MonBrightnessDown",	function () awful.util.spawn("xbacklight -dec 2") end),
		
		-- Custom client manipulation
		awful.key({ modkey,           }, "Up",		function () awful.client.focus.bydirection("up")		end),	
		awful.key({ modkey,           }, "Down",	function () awful.client.focus.bydirection("down")	end),
		awful.key({ modkey,           }, "Left",	function () awful.client.focus.bydirection("left")	end),	
		awful.key({ modkey,           }, "Right",	function () awful.client.focus.bydirection("right")	end),

		awful.key({ modkey,           }, "s",	function () awful.tag.viewonly(awful.tag.gettags(awful.tag.getscreen())[9])	end),
		awful.key({ modkey,           }, "g",	function () awful.tag.viewonly(awful.tag.gettags(awful.tag.getscreen())[8])	end),

    -- Menubar
    awful.key({ modkey }, "p", function() menubar.show() end,
              {description = "show the menubar", group = "launcher"})
)

clientkeys = awful.util.table.join(
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

    awful.key({ modkey,           }, "Return", function (c) c:swap(awful.client.getmaster()) end,
              {description = "move to master", group = "client"}),

    awful.key({ modkey,           }, "o",      function (c) c:move_to_screen()               end,
              {description = "move to screen", group = "client"}),

    awful.key({ modkey,           }, "t",      function (c) c.ontop = not c.ontop            end,
              {description = "toggle keep on top", group = "client"}),

    awful.key({ modkey,           }, "n",
        function (c)
            c.minimized = true
        end ,
        {description = "minimize", group = "client"}),

    awful.key({ modkey,           }, "m",
        function (c)
            c.maximized = not c.maximized
            c:raise()
        end ,
        {description = "maximize", group = "client"})
)

-- Bind all key numbers to tags.
-- Be careful: we use keycodes to make it works on any keyboard layout.
-- This should map on the top row of your keyboard, usually 1 to 9.
for i = 1, 9 do
    globalkeys = awful.util.table.join(globalkeys,
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

clientbuttons = awful.util.table.join(
    awful.button({ }, 1, function (c) client.focus = c; c:raise() end),
    awful.button({ modkey }, 1, awful.mouse.client.move),
    awful.button({ modkey }, 3, awful.mouse.client.resize))

-- Set keys
root.keys(globalkeys)
-- }}}

-- {{{ Rules
-- Rules to apply to new clients (through the "manage" signal).
local win_rules = {
    { rule = { },
      properties = { 
				border_width = beautiful.border_width,
        border_color = beautiful.border_normal,
        focus = awful.client.focus.filter,
        raise = true,
        keys = clientkeys,
        buttons = clientbuttons,
        screen = awful.screen.preferred,
        placement = awful.placement.no_overlap+awful.placement.no_offscreen			
			}
    },

    -- Floating clients.
    { rule_any = {
        instance = {
          "copyq",  -- Includes session name in class.
        },

        class = {
          "Wpa_gui",
				},

				class = {
          "Chromium",
				},

        name = {
          "Event Tester",  -- xev.
        },

        role = {
          "AlarmWindow",  -- Thunderbird's calendar.
          "pop-up",       -- e.g. Google Chrome's (detached) Developer Tools.
        }
      }, properties = { floating = true }},
}

-- load custom rules from host_conf.lua
for key, value in ipairs(host_conf.w_rules)
do
	table.insert(win_rules, value)	
end

awful.rules.rules = win_rules

-- }}}

-- {{{ Signals
-- Signal function to execute when a new client appears.
client.connect_signal("manage", function (c)
    if awesome.startup and
      not c.size_hints.user_position
      and not c.size_hints.program_position then
        awful.placement.no_offscreen(c)
    end
end)

-- Enable sloppy focus, so that focus follows mouse.
client.connect_signal("mouse::enter", function(c)
    if awful.layout.get(c.screen) ~= awful.layout.suit.magnifier
        and awful.client.focus.filter(c) then
        client.focus = c
    end
end)

client.connect_signal("focus", function(c) c.border_color = beautiful.border_focus end)
client.connect_signal("unfocus", function(c) c.border_color = beautiful.border_normal end)

-- Autostart
function run_once(cmd)
  findme = cmd
  firstspace = cmd:find(" ")
  if firstspace then
    findme = cmd:sub(0, firstspace-1)
  end
  awful.util.spawn_with_shell("pgrep -u $USER -x " .. findme .. " > /dev/null || (" .. cmd .. ")")
end

awful.util.spawn_with_shell("(killall kbdd || true) && kbdd")

for key, value in ipairs(host_conf.autostart)
do
	run_once(value)
end

-- }}}
