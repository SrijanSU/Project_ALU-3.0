class alu_driver extends uvm_driver #(alu_sequence_item);

  	virtual alu_interface vif;
  	bit found_valid_11;
  	`uvm_component_utils(alu_driver)
      
  	function new (string name = "alu_driver", uvm_component parent);
    	super.new(name, parent);
  	endfunction:new

  	function void build_phase(uvm_phase phase);
    	super.build_phase(phase);

    	if(!uvm_config_db#(virtual alu_interface)::get(this, "", "vif", vif))

     		`uvm_fatal("NO_VIF",{"virtual interface must be set for: ",get_full_name(),".vif"});

  	endfunction:build_phase

  	virtual task run_phase(uvm_phase phase);
    	forever begin:forever_loop
    		seq_item_port.get_next_item(req);
    		drive();
    		seq_item_port.item_done();
    	end:forever_loop
  	endtask:run_phase

  	virtual task drive();
    	@(posedge vif.drv_cb);
      	if (is_single_operand_operation(req)) begin:single_operand_operation
//       		repeat(2) @(vif.drv_cb);
//             	-> vif.drv_done_e;
//       		repeat(4) @(vif.drv_cb);
          	driving();
		end:single_operand_operation
    
      	else if (req.INP_VALID == 2'b11 || req.INP_VALID == 2'b00) begin:multiple_operand_operation
          driving();
          	if(req.CMD inside{`MUL_INC,`MUL_SHIFT})begin:multiplication
    			repeat(3) @(vif.drv_cb);
            		-> vif.drv_done_e;
  			end:multiplication
  			else begin:other_operation
    			repeat(2) @(vif.drv_cb);
            		-> vif.drv_done_e;
  			end:other_operation
    		repeat(4) @(vif.drv_cb);

		end:multiple_operand_operation
		else begin:waiting_cycle
    		found_valid_11 = 1'b0;

          	for (int clk_count = 0; clk_count < `MAX_WAIT_CYCLE && !found_valid_11; clk_count++) 				begin:for_loop
        		req.CMD.rand_mode(0);
        		req.MODE.rand_mode(0);
              void'(req.randomize());
        		@(vif.drv_cb);
            	if (req.INP_VALID == 2'b11) begin:got_11
            		found_valid_11 = 1'b1;
                  	req.CMD.rand_mode(1);
                 	req.MODE.rand_mode(1);
            		$display("FOUND INP_VALID == 11 AT CYCLE %0d", clk_count + 1);
            		vif.OPA <= req.OPA;
      				vif.OPB <= req.OPB;
      				vif.INP_VALID <= req.INP_VALID;
      				vif.CE <= req.CE;
      				vif.CIN <= req.CIN;
      				vif.MODE <= req.MODE;
      				vif.CMD <= req.CMD;
                	`uvm_info("DRIVER","DRIVING TO DUT",UVM_MEDIUM);
      				req.print();
              		if(req.CMD inside{`MUL_INC,`MUL_SHIFT})begin:multiplication
    					repeat(3) @(vif.drv_cb);
            			-> vif.drv_done_e;
  					end:multiplication
  					else begin:other_operation
    					repeat(2) @(vif.drv_cb);
            				-> vif.drv_done_e;
  					end:other_operation
            		repeat(4) @(vif.drv_cb);
            		break;
        		end:got_11
        		else begin:not_got_11
                  	`uvm_info("DRIVER","DID NOT GOT 11",UVM_MEDIUM);  
                  `uvm_info("DRIVER",$sformatf("INP_VALID == %0d at cycle = %0d",req.INP_VALID,clk_count+1),UVM_MEDIUM);
        			 req.print();
        		end:not_got_11
    		end:for_loop

          if (!found_valid_11) begin:not_found
      			$display("DID NOT FOUND INP_VALID == 1 WITHIN %0d CLOCK CYCLE", `MAX_WAIT_CYCLE);
            		vif.OPA <= req.OPA;
      				vif.OPB <= req.OPB;
      				vif.INP_VALID <= req.INP_VALID;
      				vif.CE <= req.CE;
      				vif.CIN <= req.CIN;
      				vif.MODE <= req.MODE;
      				vif.CMD <= req.CMD;
                	`uvm_info("DRIVER","DRIVING TO DUT",UVM_MEDIUM);
      				req.print();
            		repeat(2) @(vif.drv_cb);
            		->vif.drv_done_e;
    		end:not_found
		end:waiting_cycle
  	endtask:drive
  	function bit is_single_operand_operation(alu_sequence_item req);
      if (req.MODE == 1'b1) begin:arithmetic
        	case (req.CMD)
            	`INC_A, `INC_B, `DEC_A, `DEC_B: return 1;
            	default: return 0;
        	endcase
    	end:arithmetic
    	else begin:logical
        	case (req.CMD)
            	`NOT_A, `NOT_B, `SHR1_A, `SHL1_A, `SHR1_B, `SHL1_B: return 1;
            	default: return 0;
        	endcase
    	end:logical
	endfunction:is_single_operand_operation
  
  task driving();
    vif.OPA <= req.OPA;
      		vif.OPB <= req.OPB;
      		vif.INP_VALID <= req.INP_VALID;
      		vif.CE <= req.CE;
      		vif.CIN <= req.CIN;
      		vif.MODE <= req.MODE;
      		vif.CMD <= req.CMD;
      		`uvm_info("DRIVER","DRIVING TO DUT",UVM_MEDIUM);
     	 	req.print();
  endtask
endclass:alu_driver
