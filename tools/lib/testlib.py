import os, yaml, shlex, sys
import subprocess as subp
# User Modules
import config as cfg
import dbglib as dbg
import simlib as sim


class Test(object):
    def __init__(self, name, tb_dir, config_d):
        self.name = name
        self.tb_dir = tb_dir
        self.config_d = config_d
        self.build_dir = os.path.join(cfg.BUILD_DIR, name)
        self.CreateBuildDir()
        self.use_slurm = False
        self.buildsim_log = os.path.join(self.build_dir, "buildsim.log")
        self.runsim_log = os.path.join(self.build_dir, "runsim.log")

        rest, n = os.path.split(self.name)
        self.tb_name_l = [n]
        while len(rest) > 0:
            rest, n = os.path.split(rest)
            self.tb_name_l.append(n)

        self.tb_name_l.reverse()

    # Create build folder if it doesn't exist
    def CreateBuildDir(self):
        if not os.path.exists(self.build_dir):
            dbg.print_info("Creating build folder: %s" % self.build_dir)
            os.makedirs(self.build_dir)

    def GetName(self):
        return self.name

    def GetParams(self):
        return self.config_d['params']

    def GetSpecs(self):
        return self.config_d['specs']

    def Run(self):
        # Build simulation model
        dbg.print_info("Building simulation model for '%s'" % self.name)
        flog = open(self.buildsim_log, 'w')
        rv = sim.buildSim(self.name, self.tb_dir, self.tb_name_l,
                          self.GetParams(), self.GetSpecs(), self.build_dir, flog)
        flog.close()
        if rv != 0:
            dbg.print_error("Failed to build a simulation model for '%s'" % self.name)
            dbg.print_error("Check log: %s" % self.buildsim_log)
            return 1

        # Run Simulation
        dbg.print_info("Running simulation for '%s'" % self.name)
        flog = open(self.runsim_log, 'w')
        sim.runSim(self.name, self.build_dir, flog)
        flog.close()

        # Check if test passed
        if sim.isTestPassed(self.runsim_log):
            dbg.print_success("Test for '%s' passed" % self.name)
        else:
            dbg.print_error("Test for '%s' failed" % self.name)

        return 0


class UnitTest(Test):
    def __init__(self, name, tb_dir, config_d):
        super(UnitTest, self).__init__(name, tb_dir, config_d)
        self.gen_ss_log = os.path.join(self.build_dir, "gen_ss.log")

    def genSrcSnk(self):
        gen_ss_path = os.path.join(cfg.TB_UNIT_DIR, self.name, "gen_ss.py")
        gen_ss_opt = ""
        param_d = self.GetParams()
        for param_name in param_d:
            gen_ss_opt += " --%s %d" % (param_name, param_d[param_name])

        spec_d = self.GetSpecs()
        for spec_name in spec_d:
            gen_ss_opt += " --%s %d" % (spec_name, spec_d[spec_name])
       
        if dbg.DEBUG:
            gen_ss_opt += " --debug"
 
        gen_ss_cmd = gen_ss_path + gen_ss_opt
        #TODO: change for slurm
        flog = open(self.gen_ss_log, 'w')
        proc = subp.Popen(shlex.split(gen_ss_cmd), stdout=flog, stderr=flog)
        proc.wait()
        flog.close()
        return proc.returncode

    def Run(self):
        # Generate src/snk files
        dbg.print_info("Generating SRC/SNK files for '%s'" % self.name)
        rv = self.genSrcSnk()
        if rv != 0:
            dbg.print_error("Failed to generate SRC/SNK files for '%s'" % self.name)
            dbg.print_error("Check log: %s" % self.gen_ss_log)
            return 1

        super(UnitTest, self).Run()

class SystemTest(Test):
    def __init__(self, name, tb_dir, config_d):
        super(SystemTest, self).__init__(name, tb_dir, config_d)

class Sim(Test):
    def __init__(self, name, tb_dir, config_d):
        super(Sim, self).__init__(name, tb_dir, config_d)

    def NeedsReceiver(self):
        return ('receiver' in self.config_d['specs']
                and self.config_d['specs']['receiver'])

    def Run(self):
        # Build simulation model
        dbg.print_info("Building simulation model for '%s'" % self.name)
        flog = open(self.buildsim_log, 'w')

        if self.NeedsReceiver():
            rv = sim.buildSimWithVPI(self.name, self.tb_dir, self.tb_name_l,
                                     self.GetParams(), self.GetSpecs(), 
                                     self.build_dir, flog)
        else:
            rv = sim.buildSim(self.name, self.tb_dir, self.tb_name_l,
                              self.GetParams(), self.GetSpecs(), 
                              self.build_dir, flog)

        flog.close()
        if rv != 0:
            dbg.print_error("Failed to build a simulation model for '%s'" % self.name)
            dbg.print_error("Check log: %s" % self.buildsim_log)
            return 1

        # Run Simulation
        dbg.print_info("Running simulation for '%s'" % self.name)
        flog = open(self.runsim_log, 'w')
        sim.runSim(self.name, self.build_dir, flog)
        flog.close()

        # Check if test passed
        dbg.print_success("Simulation for '%s' finished" % self.name)

        return 0

def readTestConfig(cfg_name):
    cfg_path = os.path.join(cfg.TB_CONFIG_DIR, cfg_name)
    with open(cfg_path, 'r') as ymlfile:
        run_cfg = yaml.load(ymlfile)

    return run_cfg
