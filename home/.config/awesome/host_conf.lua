--local naughty = require("naughty")
local awful = require("awful")
local beautiful = require("beautiful")
local gears = require("gears")
local hotkeys_popup = require("awful.hotkeys_popup")
local helpers = require("helpers")
local theme_assets = require("beautiful.theme_assets")

-- generate and load applications menu
local os = require("os")
os.execute(
	"xdg_menu --format awesome --root-menu /etc/xdg/menus/arch-applications.menu >" 
	.. awful.util.getdir("config") 
	.. "/archmenu.lua"
)
local xdg_menu = require("archmenu")

-- ############################################################################################
local HOSTNAME = helpers.hostname

local APPS = {
	["terminal"]		=	"alacritty",
	["lock_manager"]	=	"xsecurelock",
	["lock_command"]	=	"loginctl lock-session",
	["file_manager"]	=	"pcmanfm",
	["browser"]			=	"firefox",
}

local TITLEBAR_SIZE = 22
if HOSTNAME == "NB-ZAVYALOV2" then
	TITLEBAR_SIZE = 30
end

-- ############################################################################################
-- Theme
function initTheme()
	beautiful.init(gears.filesystem.get_themes_dir() .. "zenburn/theme.lua")
	beautiful.useless_gap	= 1

	local color_f = "#285577"
	local color_n = "#5f676a"
	--local color_u = "#FF5500"
	local color_u = "#DC510C"

	-- urgency
	beautiful.fg_urgent  = beautiful.bg_focus
	beautiful.bg_urgent  = color_u

	-- borders
	--beautiful.border_focus = color_f
	--beautiful.border_normal = color_n
	
	-- notifications
	beautiful.notification_bg = color_f
	beautiful.notification_fg = "#ffffff"
	beautiful.notification_border_color = beautiful.fg_normal

	-- menu
	beautiful.menu_border_width	= 1
	beautiful.menu_submenu_icon	= nil
	beautiful.menu_submenu		= "> "
	beautiful.menu_height		= 25
	beautiful.menu_width		= 160
	beautiful.menu_border_color	= beautiful.fg_normal

	-- tooltips
	beautiful.tooltip_border_color = beautiful.fg_normal
	beautiful.tooltip_border_width = 0.8

	-- disable default wallpaper
	beautiful.wallpaper = nil
	gears.wallpaper.set("#151515")

	-- env
	beautiful.font			= "Ubuntu Bold 10"
	beautiful.border_width	= 3
	beautiful.wibar_height	= 20
	beautiful.notification_max_width=350
	beautiful.notification_max_height = 100
	beautiful.systray_icon_spacing = 2

	if HOSTNAME == "ux533f" then
		beautiful.xresources.set_dpi(130)
	end
end

-- ############################################################################################
-- Menu
function getMenu()
	awesome_menu = {
		{"Restart",	awesome.restart},
		{"Exit",	function() helpers.promptRun("exit ?", awesome.quit) end}
	}

	exit_menu = {
		{"Suspend",			"systemctl suspend -i"},
		{"Shutdown",	function() helpers.promptRun("shutdown ?",	"systemctl poweroff -i"	) end},
		{"Reboot",		function() helpers.promptRun("reboot ?",	"systemctl reboot -i"	) end},
	}

	main_menu = awful.menu({
		items = {
			{"Awesome",			awesome_menu, beautiful.awesome_icon},
			{"Applications",	xdgmenu},
			{"File Manager",	APPS.file_manager},
			{"System",			exit_menu},
			{"Lock Screen",		APPS.lock_command}
		}
	})

	return main_menu
end

-- ############################################################################################
-- Hotkeys
function getHotkeys()
		hotkeys = gears.table.join(
			awful.key({ modkey,			},	"r",	function () awful.spawn('rofi -show run')			end),
			awful.key({ modkey,	"Shift"	},	"d",	function () awful.spawn('rofi -show window')		end),
			awful.key({ modkey,	"Shift"	},	"p",	function () awful.spawn(APPS.file_manager,	false)	end),
			awful.key({ modkey,	"Shift"	},	"F12",	function () awful.spawn(APPS.lock_command,	false)	end),

			awful.key({	}, "XF86AudioRaiseVolume",	function () helpers.volume("inc")		end),
			awful.key({	}, "XF86AudioLowerVolume",	function () helpers.volume("dec")		end),
			awful.key({	}, "XF86AudioMute",			function () helpers.volume("toggle")	end),
			awful.key({	}, "XF86MonBrightnessUp",	function () helpers.backlight("inc")	end),
			awful.key({	}, "XF86MonBrightnessDown",	function () helpers.backlight("dec")	end),

			awful.key({ }, "XF86AudioPlay",	function () awful.spawn('playerctl play-pause',	false)	end),
			awful.key({ }, "XF86AudioPrev",	function () awful.spawn('playerctl previous',	false)	end),
			awful.key({ }, "XF86AudioNext",	function () awful.spawn('playerctl next',		false)	end),

			awful.key({ modkey,			}, "Up",	function () awful.client.focus.bydirection("up")	end),
			awful.key({ modkey,			}, "Down",	function () awful.client.focus.bydirection("down")	end),
			awful.key({ modkey,			}, "Left",	function () awful.client.focus.bydirection("left")	end),
			awful.key({ modkey,			}, "Right",	function () awful.client.focus.bydirection("right")	end),

			awful.key({ modkey,			}, "s",	function () awful.screen.focused().tags[9]:view_only()	end),
			awful.key({ modkey,			}, "g",	function () awful.screen.focused().tags[8]:view_only()	end),

			awful.key({ modkey,	"Shift"	}, "/",		hotkeys_popup.show_help),
			--awful.key({ 'Ctrl',			}, "space",	naughty.destroy_all_notifications),

			-- clipboard
			--awful.key({ 'Ctrl',			}, "grave",	function () awful.spawn.with_shell('~/src/dotfiles/bin/gpaste-menu') end)
			awful.key({ 'Ctrl',			}, "grave",	function () awful.spawn.with_shell('clipmenu') end)
	)

	return hotkeys
end

-- ############################################################################################
-- Tags layouts
function getLayouts()
	layouts = {}
	for i = 1, 9 do layouts[i] = awful.layout.suit.tile end

	layouts[2] = awful.layout.suit.max
	layouts[3] = awful.layout.suit.max
	layouts[8] = awful.layout.suit.floating

	return layouts
end

-- ############################################################################################
-- Client rules
function getClientRules(client_rules)
	-- float apps list
	float_apps = {
		"Nm-connection-editor",
		"Vpnui",
		"Pavucontrol",
		"Nitrogen",
		"Transmission-gtk",
		"Blueman-manager",
		"Spotify",
		"qBittorrent",
		"mpv",
		"Skype",
		"explorer.exe"
	}
	float_apps_top = {
		"Galculator",
		"flameshot",
		"Gcolor3"
	}

	-- host additional settings
	client_rules = gears.table.join(client_rules, {
		{rule = {class = "TelegramDesktop"}, properties = {screen = 1, tag = "9"}}
	})
	
	-- set window rules
	client_rules = gears.table.join(client_rules, {
		-- disable titlebars
		{rule_any = {type = {"normal", "dialog"}}, properties = {titlebars_enabled = false}},

		-- set floating
		{rule_any = {class = gears.table.join(float_apps, float_apps_top)},
		properties = {floating = true}},

		-- set on-top
		{rule_any =	{class = float_apps_top}, properties = {ontop = true}},

		-- fix for chromium
		--{rule = {class = "Chromium"}, properties = {floating = true}},
		--{rule = {class = "Chromium", role = "pop-up"}, properties = {titlebars_enabled = true}},
		
		-- thunderbird
		{rule = {class = "Thunderbird"}, properties = {screen = 1, tag = "9"}},

	})

	return client_rules
end

-- ############################################################################################
-- Fixes
client.connect_signal("request::geometry", function(c)
	if client.focus then
		if not client.focus.fullscreen then
			client.focus.border_width = beautiful.border_width
		end
	end
end)

-- ############################################################################################
-- Autostart
function initAutostart()
	run_list = {
		'xss-lock -- ' .. APPS.lock_manager,
		'libinput-gestures-setup start',
		'clipmenud',
		'light -N 1',
		'dunst',
		'blueman-applet',
		'thunderbird',
		'firefox',
		APPS.terminal .. ' -e tmux-workspace.sh',
	}
	
	run_list_with_sleep = {
		'telegram-desktop',
		'alttab',
	}

    -- run always
	awful.spawn.with_shell('setxkbmap -layout "us,ru" -option grp:caps_toggle')
	awful.spawn.with_shell('xsettingsd')

	-- run once
	for i, app_name in ipairs(run_list) do helpers.runOnce(app_name) end
	
	-- run once with sleep
	for i, app_name in ipairs(run_list_with_sleep) do helpers.runOnce(app_name, 5) end

	-- setup tags
	awful.tag.incmwfact(0.05, awful.tag.find_by_name(awful.screen.focused(), "9"))

end

-- ############################################################################################

return {
	apps			=	APPS,
	titlebar_size	=	TITLEBAR_SIZE,
	initTheme		=	initTheme,
	initAutostart	=	initAutostart,
	getMenu			=	getMenu,
	getHotkeys		=	getHotkeys,
	getLayouts		=	getLayouts,
	getClientRules	=	getClientRules
}
