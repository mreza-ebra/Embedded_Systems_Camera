onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /fullsystemtestbench/dut/clk
add wave -noupdate /fullsystemtestbench/dut/Reset
add wave -noupdate /fullsystemtestbench/cmos/frame_valid
add wave -noupdate /fullsystemtestbench/cmos/line_valid
add wave -noupdate /fullsystemtestbench/cmos/data
add wave -noupdate /fullsystemtestbench/dut/Streamer/start
add wave -noupdate /fullsystemtestbench/dut/Streamer/output1
add wave -noupdate /fullsystemtestbench/dut/Streamer/output2
add wave -noupdate /fullsystemtestbench/dut/Streamer/ready
add wave -noupdate /fullsystemtestbench/dut/Debayer/output
add wave -noupdate /fullsystemtestbench/dut/Debayer/readyout
add wave -noupdate /fullsystemtestbench/dut/ColorUnit/CvtData
add wave -noupdate /fullsystemtestbench/dut/ColorUnit/ReadyOutColor
add wave -noupdate /fullsystemtestbench/dut/SecondFifo/data
add wave -noupdate /fullsystemtestbench/dut/MasterUnit/StartAddr
add wave -noupdate /fullsystemtestbench/dut/MasterUnit/Length
add wave -noupdate /fullsystemtestbench/dut/MasterUnit/FifoData
add wave -noupdate /fullsystemtestbench/dut/MasterUnit/MemAddr
add wave -noupdate -radix hexadecimal /fullsystemtestbench/dut/MasterUnit/MasterWriteData
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {780000 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 236
configure wave -valuecolwidth 218
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
configure wave -timelineunits ns
update
WaveRestoreZoom {0 ps} {1840527 ps}
