import os, subprocess, re
# Local modules
import commonlib as common
import config as cfg
import dbglib as dbg

def genSimDefs(tb_name, param_d, spec_d):
    def_s = ""
    for param in param_d:
        d = " +define+%s_%s=%s" % (tb_name.upper(), param.upper(), str(param_d[param]))
        def_s += d

    for spec in spec_d:
        d = " +define+%s=%s" % (spec.upper(), str(spec_d[spec]))
        def_s += d

    if dbg.DEBUG:
        def_s += "+define+DEBUG"

    return def_s

def buildSim(tb_name, tb_dir, tb_name_l,
             param_d, spec_d, build_dir, flog):
    sim_tool = "vcs"
    build_opt = "-full64 +v2k -debug_all +lint=all,noVCDE -timescale=1ps/1ps"
    
    ## flists
    common_flist_path = os.path.join(tb_dir, "sim.flist")
    
    other_flist_path = tb_dir
    all_other_flists = ''
    for name in tb_name_l:
        other_flist_path = os.path.join(other_flist_path, name)
        all_other_flists += '-f %s ' % os.path.join(other_flist_path, "sim.flist") 
    
    ## other
    sim_def = genSimDefs(tb_name_l[0], param_d, spec_d)

    build_cmd = "%s %s -f %s %s %s" % (sim_tool, build_opt, common_flist_path, 
                                          all_other_flists, sim_def)

    prev_dir = os.getcwd()
    os.chdir(build_dir)
    # TODO: change for Slurm
    flog.write("*"*40 + '\n')
    flog.write("Build command:\n")
    flog.write("*"*40 + '\n')
    flog.write(build_cmd + '\n')
    flog.write("*"*40 + '\n')
    flog.write("\n\n")
    flog.flush()
    proc = common.launchJob(None, build_cmd, False, [], flog)
    proc.wait()
    os.chdir(prev_dir)

    return proc.returncode

def buildSimWithVPI(tb_name, tb_dir, tb_name_l,
                    param_d, spec_d, build_dir, flog):
    sim_tool = "vcs"
    build_opt = "-full64 +v2k +vpi -debug_all +lint=all,noVCDE -timescale=1ps/1ps"

    ## flists
    common_flist_path = os.path.join(tb_dir, "sim.flist")
    
    other_flist_path = tb_dir
    all_other_flists = ''
    for name in tb_name_l:
        other_flist_path = os.path.join(other_flist_path, name)
        all_other_flists += '-f %s ' % os.path.join(other_flist_path, "sim.flist") 

    vpi_flist_path = os.path.join(cfg.VPI_RECEIVER_DIR, "sim.flist")
    
    ## CFLAGS
    cflags = "-CFLAGS "
    cflags += '"-I%s" ' % cfg.VPI_RECEIVER_DIR 
    #cflags += '"-I%s/amd64/lib" ' % os.environ['VCS_HOME'] 
    
    ## other
    sim_def = genSimDefs(tb_name_l[0], param_d, spec_d)
    tab_path = os.path.join(cfg.VPI_RECEIVER_DIR, "sim_receiver.tab") 

    

    build_cmd = "%s %s -P %s -f %s %s -f %s %s %s" % (sim_tool, build_opt, tab_path, common_flist_path,
                                                   all_other_flists, vpi_flist_path, sim_def, cflags)

    prev_dir = os.getcwd()
    os.chdir(build_dir)
    # TODO: change for Slurm
    flog.write("*"*40 + '\n')
    flog.write("Build command:\n")
    flog.write("*"*40 + '\n')
    flog.write(build_cmd + '\n')
    flog.write("*"*40 + '\n')
    flog.write("\n\n")
    flog.flush()
    proc = common.launchJob(None, build_cmd, False, [], flog)
    proc.wait()
    os.chdir(prev_dir)

    return proc.returncode

def runSim(tb_name, build_dir, flog):
    prev_dir = os.getcwd()
    os.chdir(build_dir)
    proc = subprocess.Popen("./simv", stdout=flog, stderr=flog)
    proc.wait()

    os.chdir(prev_dir)

def isTestPassed(log_path):
    flog = open(log_path, 'r')
    log_data = flog.read()
    flog.close()

    m = re.search("PASSED", log_data)
    if m == None:
        return False
    else:
        return True
