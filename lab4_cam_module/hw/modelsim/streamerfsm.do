onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /fullsystemtestbench/dut/StreamerUnit/start
add wave -noupdate /fullsystemtestbench/dut/StreamerUnit/FVAL
add wave -noupdate /fullsystemtestbench/dut/StreamerUnit/RVAL
add wave -noupdate /fullsystemtestbench/dut/StreamerUnit/PIXCLK
add wave -noupdate /fullsystemtestbench/dut/StreamerUnit/DATA
add wave -noupdate /fullsystemtestbench/dut/StreamerUnit/capture
add wave -noupdate /fullsystemtestbench/dut/StreamerUnit/read_request1
add wave -noupdate /fullsystemtestbench/dut/StreamerUnit/read_request2
add wave -noupdate /fullsystemtestbench/dut/StreamerUnit/output1
add wave -noupdate /fullsystemtestbench/dut/StreamerUnit/output2
add wave -noupdate /fullsystemtestbench/dut/StreamerUnit/empty2
add wave -noupdate /fullsystemtestbench/dut/StreamerUnit/ready
add wave -noupdate /fullsystemtestbench/dut/StreamerUnit/state
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {551 ns} 0}
quietly wave cursor active 1
configure wave -namecolwidth 489
configure wave -valuecolwidth 327
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ms
update
WaveRestoreZoom {495 ns} {813 ns}
