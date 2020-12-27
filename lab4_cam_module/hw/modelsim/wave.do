onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /fullsystemtestbench/sim_finished
add wave -noupdate /fullsystemtestbench/clk
add wave -noupdate /fullsystemtestbench/reset
add wave -noupdate /fullsystemtestbench/addr
add wave -noupdate /fullsystemtestbench/read
add wave -noupdate /fullsystemtestbench/write
add wave -noupdate /fullsystemtestbench/rddata
add wave -noupdate /fullsystemtestbench/wrdata
add wave -noupdate /fullsystemtestbench/dut/MasterUnit/StartAddr
add wave -noupdate /fullsystemtestbench/dut/MasterUnit/Length
add wave -noupdate /fullsystemtestbench/dut/SecondFifo/q
add wave -noupdate /fullsystemtestbench/dut/Tmp
add wave -noupdate /fullsystemtestbench/MasterOutput
add wave -noupdate /fullsystemtestbench/BurstCount
add wave -noupdate /fullsystemtestbench/dut/StreamerUnit/FVAL
add wave -noupdate /fullsystemtestbench/dut/StreamerUnit/RVAL
add wave -noupdate /fullsystemtestbench/dut/StreamerUnit/ready
add wave -noupdate /fullsystemtestbench/dut/StreamerUnit/DATA
add wave -noupdate /fullsystemtestbench/dut/StreamerUnit/empty1
add wave -noupdate /fullsystemtestbench/dut/StreamerUnit/empty2
add wave -noupdate /fullsystemtestbench/dut/StreamerUnit/write_request1
add wave -noupdate /fullsystemtestbench/dut/StreamerUnit/write_request2
add wave -noupdate /fullsystemtestbench/dut/StreamerUnit/output1
add wave -noupdate /fullsystemtestbench/dut/StreamerUnit/output2
add wave -noupdate /fullsystemtestbench/dut/DebayerUnit/readyout
add wave -noupdate /fullsystemtestbench/dut/DebayerUnit/output
add wave -noupdate /fullsystemtestbench/dut/ColorUnit/ReadyOutColor
add wave -noupdate /fullsystemtestbench/dut/ColorUnit/CvtData
add wave -noupdate /fullsystemtestbench/dut/MasterUnit/FifoWords
add wave -noupdate /fullsystemtestbench/empty
add wave -noupdate /fullsystemtestbench/dut/StreamerUnit/line__61/pixel_num
add wave -noupdate /fullsystemtestbench/dut/StreamerUnit/line__61/row_num
add wave -noupdate /fullsystemtestbench/dut/MasterUnit/CBURST
add wave -noupdate /fullsystemtestbench/dut/MasterUnit/ReadFifo
add wave -noupdate /fullsystemtestbench/dut/SecondFifo/data
add wave -noupdate /fullsystemtestbench/dut/SecondFifo/wrreq

TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {540951 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 331
configure wave -valuecolwidth 202
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
WaveRestoreZoom {482863 ps} {694852 ps}
