#![forbid(unsafe_code)]

#[macro_use]
extern crate lazy_static;
extern crate eyre;
extern crate fs_extra;

mod cli;
//mod daemon;

use cli::Cli;
//use daemon::start_daemon_mode;

use eyre::{Result, WrapErr};
use clap::Parser;
use boop_gtk_fork::{
    executor,
    script,
    scriptmap
};

lazy_static! {
    static ref XDG_DIRS: xdg::BaseDirectories = match xdg::BaseDirectories::with_prefix("boop-gtk")
    {
        Ok(dirs) => dirs,
        Err(err) => panic!("Unable to find XDG directorys: {}", err),
    };
}


fn main() -> Result<()>{
    let args: Cli = cli::Cli::parse();

    // create user scripts directory if it doesn't exist
    let scripts_dir: std::path::PathBuf = XDG_DIRS.get_config_home().join("scripts");
    std::fs::create_dir_all(&scripts_dir).wrap_err_with(|| {
        format!(
            "Failed to create scripts directory in config: {}",
            scripts_dir.display()
        )
    })?;
    
    // load scripts
    let (mut script_map, load_script_error) = scriptmap::ScriptMap::new();
    if let Some(error) = load_script_error {
        eprintln!("Error loading scripts: {}", &error);
        //TODO: do the above the correct way
    }

    // read command args
    let script_name = args.script_name.join(" ");
    let script_name_lower = script_name.to_lowercase();
    //if args.daemon {
    //    start_daemon_mode();
    //    std::process::exit(0);
    //}
    if args.list_scripts {
        for (name, _) in script_map.0.iter() {
            println!("{}", name);
        }
        std::process::exit(0);
    }
    // if we've filtered for flags like --list-scripts, script_name won't be empty here
    // because Clap is configured with ArgRequiredElseHelp
    let _match;
    let matches: Vec<(&String, &script::Script)> = script_map.0.iter()
            .filter(|(name, _)| name.to_lowercase().starts_with(&script_name_lower))
            .collect();
    if matches.len() != 1 {
        // can't run a script here, so output the input and then print an error message
        std::io::copy(&mut std::io::stdin(), &mut std::io::stdout());
        if matches.len() == 0 {
            eprintln!("No scripts found with name: {}", script_name);
        } else if matches.len() > 1 {
            // can't pick a script, so output the input and then print options to stderr
            eprintln!("Can't autocomplete script name. Did you mean one of the following?");
            for (name, _) in matches {
                eprintln!("\t{}", name);
            }
        } else {
            unreachable!("matches.len() is not 0, 1, or >1. It is {}", matches.len());
        }
        std::process::exit(1);
    }
    _match = matches[0].0.clone();
    drop(matches);
    
    let s = script_map.0.get_mut(&_match).unwrap();
    let input = std::io::read_to_string(std::io::stdin())?;
    let execution_status: executor::ExecutionStatus = match s.execute(&input, None) {
        Err(_) => {
            std::io::copy(&mut std::io::stdin(), &mut std::io::stdout());
            eprintln!("Failed to execute script: {}", "[placeholder]");
            std::process::exit(1)
        },
        Ok(status) => status,
    };
    let replacement = execution_status.into_replacement();
    let output = match replacement {
        // the script did nothing?? output the input I guess
        executor::TextReplacement::None => {
            std::io::copy(&mut std::io::stdin(), &mut std::io::stdout());
            std::process::exit(1)
        }
        // These shouldn't happen
        executor::TextReplacement::Selection(str) => {
            eprintln!("Warning!! ExecutionStatus.into_replacement returned Selection, when Full was expected");
            str
        },
        executor::TextReplacement::Insert(str_vec) => {
            eprintln!("Warning!! ExecutionStatus.into_replacement returned Selection, when Full was expected");
            str_vec.join("\n")
        }
        executor::TextReplacement::Full(str) => str,
    };
    print!("{}", output);
    std::process::exit(0);
}
