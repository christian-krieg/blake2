all:
	vivado -mode batch -source synth.tcl
	vivado -mode batch -source prog.tcl

synth:
	vivado -mode batch -source synth.tcl

prog:
	vivado -mode batch -source prog.tcl

clean:
	rm -rf vivado
	rm -f  vivado*.jou
	rm -f  vivado*.log
	rm -f  vivado*.str
	rm -f  webtalk*.log
	rm -f  webtalk*.jou
	rm -rf .Xil
