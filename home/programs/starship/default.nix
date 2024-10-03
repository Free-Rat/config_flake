{ inputs, lib, pkgs, ... }: {
	programs.starship = {
		enable = true;
		enableFishIntegration = true;
		settings = {
			format =
				let
					git = "$git_commit$git_state$git_status";
					langs = "$docker_context$package$c$cmake$cobol$daml$dart$deno$dotnet$elixir$elm$erlang$fennel$golang$guix_shell$haskell$haxe$helm$java$julia$kotlin$gradle$lua$nim$nodejs$ocaml$opa$perl$php$pulumi$purescript$python$raku$rlang$red$ruby$rust$scala$solidity$swift$terraform$vlang$vagrant$zig$buf$conda$meson$spack$memory_usage$aws$gcloud$openstack$azure$env_var$crystal";

				in
					# "$username$hostname($shlvl)$nix_shell${git}$jobs$character";
					"$directory$nix_shell${git}$jobs$character";
			# ''
			#   $username$hostname($shlvl)($cmd_duration) $fill ${langs}($nix_shell) $directory(${git}) 
			#   $jobs$character
			# '';

			fill = {
				symbol = " ";
				disabled = false;
			};

			username = {
				format = "[$user]($style)";
				show_always = true;
				style = "bold";
			};

			hostname = {
				format = "[@$hostname]($style) ";
				ssh_only = false;
				style = "thin green";
			};

			shlvl = {
				format = "[$shlvl]($style) ";
				style = "cyan";
				threshold = 2;
				repeat = true;
				disabled = false;
			};

			cmd_duration = {
				format = "took [$duration]($style) ";
			};

			directory = {
				format = "[$path]($style)( [$read_only]($read_only_style)) ";
			};

			nix_shell = {
				format = "[$symbol]($style) ";
				# format = "[$name <- $symbol]($style) ";
				impure_msg = "";
				symbol = " ";
				style = "thin red";
			};

			character = {
				error_symbol = "[~~>](bold red)";
				success_symbol = "[->>](bold green)";
				vimcmd_symbol = "[<<-](bold yellow)";
				vimcmd_visual_symbol = "[<<-](bold cyan)";
				vimcmd_replace_symbol = "[<<-](bold purple)";
				vimcmd_replace_one_symbol = "[<<-](bold purple)";
			};

			time = {
				format = "\\\[[$time]($style)\\\]";
				disabled = false;
			};

			jobs = {
				style = "thin";
			};
		};
	};
}
