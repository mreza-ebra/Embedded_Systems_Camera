onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /fullsystemtestbench/sim_finished
add wave -noupdate /fullsystemtestbench/clk
add wave -noupdate /fullsystemtestbench/reset
add wave -noupdate /fullsystemtestbench/dut/CameraUnit/frame_valid
add wave -noupdate /fullsystemtestbench/dut/CameraUnit/line_valid
add wave -noupdate /fullsystemtestbench/dut/Streamer/output1
add wave -noupdate /fullsystemtestbench/dut/Streamer/output2
add wave -noupdate /fullsystemtestbench/dut/Streamer/ready
add wave -noupdate /fullsystemtestbench/dut/Debayer/output
add wave -noupdate /fullsystemtestbench/dut/Debayer/readyout
add wave -noupdate /fullsystemtestbench/dut/ColorUnit/CvtData
add wave -noupdate /fullsystemtestbench/dut/ColorUnit/ReadyOutColor
add wave -noupdate /fullsystemtestbench/dut/SecondFifo/data
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {1400868 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 379
configure wave -valuecolwidth 170
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
WaveRestoreZoom {148448 ps} {2091424 ps}
