

class alu_passive_monitor extends uvm_monitor;

 	 virtual alu_interface vif;

  uvm_analysis_port #(alu_sequence_item) item_collected_port;

  	alu_sequence_item alu_sequence_item_1;

  `uvm_component_utils(alu_passive_monitor)

  function new (string name = "alu_passive_monitor", uvm_component parent);
    	super.new(name, parent);
    	alu_sequence_item_1 = new();
    item_collected_port = new("item_collected_port", this);
  	endfunction:new

  	function void build_phase(uvm_phase phase);
    	super.build_phase(phase);
    	if(!uvm_config_db#(virtual alu_interface)::get(this, "", "vif", vif))
       		`uvm_fatal("NOVIF",{"virtual interface must be set for: ",get_full_name(),".vif"});
  	endfunction:build_phase

  	virtual task run_phase(uvm_phase phase);
    	forever begin:forever_loop
      		@(vif.drv_done_e);          
          	alu_sequence_item_1.RES = vif.RES;
          	alu_sequence_item_1.ERR = vif.ERR;
          	alu_sequence_item_1.COUT = vif.COUT;
          	alu_sequence_item_1.OFLOW = vif.OFLOW;
          	alu_sequence_item_1.G = vif.G;
          	alu_sequence_item_1.E = vif.E;
          	alu_sequence_item_1.L = vif.L;
    		item_collected_port.write(alu_sequence_item_1);
    	end:forever_loop
  	endtask:run_phase
endclass:alu_passive_monitor
