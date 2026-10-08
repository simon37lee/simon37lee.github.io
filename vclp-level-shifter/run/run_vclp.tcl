# =====================================================================
#  run_vclp.tcl : VC LP RTL(UPF) 체크
#  실행: cd run && vc_static_shell -f run_vclp.tcl
# =====================================================================
set_app_var enable_lp true

# (선택) Netlist 단계/LS cell mapping 체크 시 라이브러리 지정
# set_app_var search_path "/path/to/lib/db"
# set_app_var link_library "* std_cell_1p0v.db std_cell_0p8v.db ls_cell.db"

# 1. RTL 읽기
read_file -top top -format verilog -vcs "-f filelist.f"

# 2. UPF 읽기
read_upf ../upf/top.upf

# 3. Low Power 체크
check_lp -stage upf
check_lp -stage design

# 4. 리포트
report_lp            -file report_lp.txt
report_lp -verbose   -file report_lp_verbose.txt
report_lp -limit 0 -verbose

quit
