#!/usr/bin/env rust-script

use std::process::Command;
use std::str;

fn main() {
    // Run `pamixer --get-mute`
    let mute_output = Command::new("pamixer")
        .arg("--get-mute")
        .output()
        .expect("Failed to run pamixer");

    let is_muted = str::from_utf8(&mute_output.stdout)
        .unwrap_or("")
        .trim()
        .eq("true");

    if is_muted {
        println!("Vol: muted");
    } else {
        // Run `pamixer --get-volume`
        let volume_output = Command::new("pamixer")
            .arg("--get-volume")
            .output()
            .expect("Failed to run pamixer");

        let volume = str::from_utf8(&volume_output.stdout).unwrap_or("0").trim();

        println!("V: {}%", volume);
    }
}
