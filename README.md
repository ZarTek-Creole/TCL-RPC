# TCL-RPC

RPC for Eggdrop. Botnets are cool, but being able to execute commands from one bot to another is better

## Installation

1. Copy the `rpc-server.tcl` and `rpc-server.cfg` file to your eggdrop's `scripts/` directory.
2. Edit the `rpc-server.cfg` file to your liking.
3. Then, in your eggdrop config file, add the following line:

```tcl
    source scripts/rpc-server.tcl
```

## Usage

connect to port defined in `rpc-server.cfg` and send a command. The command should be in the following format:

```tcl
    <password> <command> <arguments>
```

### Commands

tcl : execute a tcl command
    tcl <tcl command>

call: call a fonction or procedure
    call <function> <arguments>
