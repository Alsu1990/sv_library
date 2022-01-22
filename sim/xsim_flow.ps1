
$SOURCES_SV= "tb.sv"




Write-Output "### COMPILING SYSTEMVERILOG ###"
xvlog --sv  $SOURCES_SV -nolog

Write-Output "### ELABORATING ###"
xelab -debug all -top tb -snapshot tb_snapshot -nolog

Write-Output "### RUNNING SIMULATION ###"
xsim tb_snapshot -tclbatch xsim_config.tcl -nolog

Write-Output "### OPENING WAVES ###"
xsim --gui adder_tb_snapshot.wdb

exit 0
