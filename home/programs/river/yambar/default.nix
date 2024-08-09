{ ... } : {
	programs.yambar = {
		enable = true;
		# settings = builtins.readFile ./settings.yaml;
		# settings = {
			# bar = {
			# 	location = "top";
			# 	height = 20;
			# 	# foreground = "ffffffff";
			# 	background = "00000066";
			#
			# 	font = "Monaspace Krypton:style=bold:pixelsize = 13";
			#
			# 	spacing = 2;
			# 	margin = 0;
			# 	layer = "top";
			#
			# 	left = [
			# 	{
			# 		clock = {
			# 		    time-format = "%H:%M %Z";
			# 			content = [{ 
			# 				string.text = "{date} {time}";
			# 			}];
			# 		};
			# 	}
			# 	];
			#
			#
			# 	center = [
			# 		{
			# 			# river = {
			# 				# anchors = {
			# 		}
			# 	];
			# 	
			# 	right = [
			# 	{
			# 		clock.content = [
			# 		{
			# 			string.text = "{time}";
			# 		}
			# 		];
			# 	}
			# 	];
			# };
		# };
	};
}

