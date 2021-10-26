# Tonic

Tonic is a programmable hardware architecture for the transport logic, i.e., reliable data delivery and congestion control. All the design files in this repository are available for use under the 3-clause BSD License.



## Code Structure

- **src/** - source files
  - **tonic.v** (Tonic's top-level)
  - **dd_engine/** (Data Delivery Engine)
  - **cr_engine/** (Credit Engine)
  - **user_defined_logic/**
  - Other components used by the engines (e.g., RAM, bitmap operations, etc.)
- **include/** system-wide constants
- **tb/** - testbench files
  - **config/** (.yaml files for configuring simulations and test parameters)
  - **sim/** (simulation files for Tonic, including a mock receiver in C)
- **tools/** (scripts for running simulations and tests)
- **build/** - temporary build files. The output of the build and simulation goes in this directory.
- **csim/** - Tonic's cycle-accurate simulator in C++.

**Note:** Some directories are empty as they are being ported into the new infrastructre.

----
## Setting up the Environment

Before running any scripts, make sure to setup the environment variables by running

```
source settings.sh
```

----
## Running Simulation and Other Tests

All the simulations and tests are executed through the `tools/runtest` script.

```
./tools/runtest --type [sim|unit|system] \
                --config path_of_config_file_from_config_root.yaml \
                [--debug]
```

**Notes:**
- The `system` and `unit` options are not included yet and therefore cannot be used for now.
- The `sim` option simulates the module that is designated in the config file using the initial parameters specified in the same file. Currently, we have simulation files for `tonic`, for which you can specify a protocol and initial parameters. See below for more information on the format of the configuration file.
- Note that *path_of_the_config_file_from_config_root.yaml* is **not** the full path to the config file. It is the path to the file starting from `tb/config`.
- The `debug` option is used to send a flag to simulation files to print debugging information. Please see `tb/sim/dd_engine/sim_top.v` for an example.

### The Configuration File

Configuration files are in YAML format. Here is the basic structure of a configuration file.

```
module_name:
  params:
    module_specific_param1: val1
    module_specific_param2: val2
    ...
  specs:
    sim_cycles: val

    # sim_specific_params
  sim_specific_param1: val1
  sim_specific_param2: val2
  ...
```

**Notes**
- `module_name` is, in most cases, the name of the top-level module for the test. Exception are top-level modules such as `tonic` and ``dd_engine`` that include one or more of the programmable modules (i.e., `user_defined_incoming` and `user_defined_timeout`). In those cases, `module_name` should be `top_level_module/protocol_name`. For instance, to test `tonic` with `reno`, the `module_name` should be `tonic/reno`.
- All the relevant simulations and test files for `module_name` (except for the source files) should be in  `tb/test_type/module_name`, where `test_type` is either of `sim`, `unit`, and `system`.
- `params` is for specifying module-specific parameters. For `tonic`, these are `init_wnd_size` and `init_rtx_timer_amnt`. As another example, if one were to write a unit test for the `fifo` module used in Tonic, these paramters could include its depth and width. 
- `specs` are parameters used for customizing the simulation:
  - `sim_cycles` specifies how many cycles to run the test for and should be specified in all configuration files.
  - For end-to-end simulations for `tonic`, the following options are required (See `tb/config/` for examples). 
`active_flow_cnt`, `receiver`, `loss_prob` (represented in X in thousands), and `rtt` are only used for end-to-end simulations for `tonic`. 
```
    active_flow_cnt: val (total number of flows to simulate)
    receiver: True/False (whether the simulations requires a mock receiver)
    loss_prob: X (the resulting loss probability will be X/1000)
    rtt: val (in nanoseconds)
  cr_type: val (type of the credit engine, 0 -> cwnd, 1 -> rate, 2 -> tokens)
    ...
```
- For top-level modules such as `tonic` and ``dd_engine`` that include one or more of the programmable modules, the following simulation variables should be specified as well: 
```
  user_context_w: val (number of bits used for protocol-specific state)
  init_user_context: val (in hex, the initial value for protocol-specific state)
  send_dd_context: 0 or 1 (whether to send protocol-specific state to cr engine. 0 for all cwnd-based protocols)
```
----
## Other Notes

### Credit Engines
The current version of the code does not include the implementation of the rate-based and grant-based credit engine. Thus, as of now, only protocols that use congestion window as means of handling credit can be simulated.

### Adding your Own Protocol

The current version of the code includes four example protocols in `src/user_defined_logic/`, all some variant of TCP: Reno, two different implementations of New Reno one based on [RFC 6582](https://tools.ietf.org/html/rfc6582), and an implementation of selective acknowledgment based on [RFC 6675](https://tools.ietf.org/html/rfc6675). To add your own protocol `proto`, create `user_defined_logic/proto` folder and implement `user_defined_incomig.v` and `user_defined_timeout.v`, following the input/output interface of the examples. Then create `tb/sim/tonic/proto` and follow the example in `tb/sim/tonic` to add protocol specific receiver behavior and simulation files.

