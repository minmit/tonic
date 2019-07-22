import os

TONIC_HOME = os.environ["TONIC_HOME"]
BUILD_DIR = os.path.join(TONIC_HOME, "build")
TB_DIR = os.path.join(TONIC_HOME, "tb")
TB_CONFIG_DIR = os.path.join(TB_DIR, "config")
TB_UNIT_DIR = os.path.join(TB_DIR, "unit")
TB_SYSTEM_DIR = os.path.join(TB_DIR, "system")
TB_SIM_DIR = os.path.join(TB_DIR, "sim")
VPI_RECEIVER_DIR = os.path.join(TB_DIR, "sim", "common", "sim_receiver")
