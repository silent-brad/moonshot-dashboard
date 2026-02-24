return {
	{
		name = "main",
		layout = "default",
		widgets = {
			{ name = "weather", slot = "top_left" },
			{ name = "btc", slot = "top_right" },
			{ name = "verse", slot = "bottom" },
		},
	},
	{
		name = "finance",
		layout = "grid",
		widgets = {
			{ name = "btc", slot = "1" },
			{ name = "stocks", slot = "2" },
			{ name = "markets", slot = "3" },
			{ name = "news", slot = "4" },
		},
	},
	{
		name = "productivity",
		layout = "default",
		widgets = {
			{ name = "calendar", slot = "top_left" },
			{ name = "todo", slot = "top_right" },
			{ name = "clock", slot = "bottom" },
		},
	},
	{
		name = "system",
		layout = "focus",
		widgets = {
			{ name = "system", slot = "main" },
		},
	},
}
