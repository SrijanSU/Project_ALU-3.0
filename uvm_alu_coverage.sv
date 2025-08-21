`uvm_analysis_imp_decl(_active_mon)
`uvm_analysis_imp_decl(_passive_mon)

class alu_coverage extends uvm_component;

    `uvm_component_utils(alu_coverage)


  uvm_analysis_imp_active_mon #(alu_sequence_item, alu_coverage) act_mon;
  uvm_analysis_imp_passive_mon #(alu_sequence_item, alu_coverage) pass_mon;


	alu_sequence_item txn_mon1, txn_drv1;
	real mon1_cov,drv1_cov;

	covergroup driver_cov;
  
        INPUT_VALID : coverpoint txn_drv1.INP_VALID { bins valid_opa = {2'b01};
                                                       bins valid_opb = {2'b10};
                                                       bins valid_both = {2'b11};
                                                       bins invalid = {2'b00};
                                                     }
        COMMAND : coverpoint txn_drv1.CMD { bins arithmetic[] = {[0:10]};
                                             bins logical[] = {[0:13]};
                                             bins arithmetic_invalid[] = {[11:15]};
                                             bins logical_invalid[] = {14,15};
                                          }
      	MODE : coverpoint txn_drv1.MODE { bins arithmetic = {1};
                                           bins logical = {0};
                                         }
       CLOCK_ENABLE : coverpoint txn_drv1.CE { bins clock_enable_valid = {1};
                                                bins clock_enable_invalid = {0};
                                               }
       OPERAND_A : coverpoint txn_drv1.OPA { bins opa[]={[0:(2**`WIDTH)-1]};}
       OPERAND_B : coverpoint txn_drv1.OPB { bins opb[]={[0:(2**`WIDTH)-1]};}
       CARRY_IN : coverpoint txn_drv1.CIN { bins cin_high = {1};
                                             bins cin_low = {0};
                                           }
       MODE_CMD_: cross MODE,COMMAND;

  	endgroup:driver_cov

 	covergroup monitor_cov;
        RESULT_CHECK:coverpoint txn_mon1.RES { bins result[]={[0:(2**`WIDTH)-1]};
                                                            option.auto_bin_max = 8;}
        CARR_OUT:coverpoint txn_mon1.COUT{ bins cout_active = {1};
                                            bins cout_inactive = {0};
                                          }
        OVERFLOW:coverpoint txn_mon1.OFLOW { bins oflow_active = {1};
                                              bins oflow_inactive = {0};
                                            }
        ERROR:coverpoint txn_mon1.ERR { bins error_active = {1};
                                       }
        GREATER:coverpoint txn_mon1.G { bins greater_active = {1};
                                       }
        EQUAL:coverpoint txn_mon1.E { bins equal_active = {1};
                                     }
        LESSER:coverpoint txn_mon1.L { bins lesser_active = {1};
                                    }
    

  	endgroup:monitor_cov

	function new(string name = "", uvm_component parent);
  		super.new(name, parent);
  		monitor_cov = new;
        driver_cov = new;
      act_mon = new("act_mon", this);
      pass_mon = new("pass_mon", this);

	endfunction:new
  

  	function void write_active_mon(alu_sequence_item t);

      	txn_drv1 = t;
        driver_cov.sample();
  //`uvm_info(get_type_name, $sformatf("[MONITOR]  rdata=%d", txn_mon1.rdata), UVM_MEDIUM);
	endfunction:write_active_mon
  
	function void write_passive_mon(alu_sequence_item t);
        txn_mon1 = t;
        monitor_cov.sample();
  //`uvm_info(get_type_name, $sformatf("[MONITOR]  rdata=%d", txn_mon1.rdata), UVM_MEDIUM);
	endfunction:write_passive_mon
  
  
  
	function void extract_phase(uvm_phase phase);
        super.extract_phase(phase);
        drv1_cov = driver_cov.get_coverage();
        mon1_cov = monitor_cov.get_coverage();
	endfunction:extract_phase

	function void report_phase(uvm_phase phase);
        super.report_phase(phase);
      `uvm_info(get_type_name, $sformatf("[INPUT] Coverage ------> %0.2f%%,", drv1_cov), UVM_MEDIUM);
      `uvm_info(get_type_name, $sformatf("[OUTPUT] Coverage ------> %0.2f%%", mon1_cov), UVM_MEDIUM);
  	endfunction:report_phase

endclass:alu_coverage

