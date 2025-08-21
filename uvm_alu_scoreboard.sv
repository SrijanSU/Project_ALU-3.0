`include "uvm_define.sv"
`uvm_analysis_imp_decl(_act_mon)
`uvm_analysis_imp_decl(_pass_mon)


class alu_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(alu_scoreboard)
    virtual alu_interface vif;
  uvm_analysis_imp_act_mon #(alu_sequence_item, alu_scoreboard) item_collected_export_active;
  uvm_analysis_imp_pass_mon #(alu_sequence_item, alu_scoreboard) item_collected_export_passive;    

    int match, mismatch;
    alu_sequence_item active_monitor_queue[$];  
    alu_sequence_item passive_monitor_queue[$];  
  
  	logic [`WIDTH:0] prev_RES;
    logic prev_COUT;
    logic prev_OFLOW;
    logic prev_ERR;
    logic prev_G;
    logic prev_E;
    logic prev_L;
    bit first_transaction;
    
    function new (string name = "alu_scoreboard", uvm_component parent);
        super.new(name, parent);
      	first_transaction = 1'b0;
    endfunction:new
    
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        uvm_config_db#(virtual alu_interface)::get(this,"","vif",vif);
      item_collected_export_active = new("item_collected_export_active", this);
      item_collected_export_passive = new("item_collected_export_passive", this);
    endfunction:build_phase
    
    virtual function void write_act_mon(alu_sequence_item pack);
        alu_sequence_item act_mon_item;
      	$display("Scoreboard received from active monitor:: Packet");
        
      act_mon_item = alu_sequence_item::type_id::create("act_mon_item");
        act_mon_item.copy(pack);
      active_monitor_queue.push_back(act_mon_item);
    endfunction:write_act_mon
  
  	virtual function void write_pass_mon(alu_sequence_item pack);
      	alu_sequence_item pass_mon_item;
     	$display("Scoreboard received from passive monitor:: Packet");
        
     	pass_mon_item = alu_sequence_item::type_id::create("pass_mon_item");
        pass_mon_item.copy(pack);
      	passive_monitor_queue.push_back(pass_mon_item);
    endfunction:write_pass_mon
  	
  	task store_previous_outputs(alu_sequence_item expected_result);
        prev_RES = expected_result.RES;
        prev_COUT = expected_result.COUT;
        prev_OFLOW = expected_result.OFLOW;
        prev_ERR = expected_result.ERR;
        prev_G = expected_result.G;
        prev_E = expected_result.E;
        prev_L = expected_result.L;
        first_transaction = 1'b0;
    endtask:store_previous_outputs

 	 task load_previous_outputs(alu_sequence_item expected_result);
       if(first_transaction) begin:first
            expected_result.RES = {`WIDTH+1{1'bz}};
            expected_result.COUT = 1'bz;
            expected_result.OFLOW = 1'bz;
            expected_result.ERR = 1'bz;
            expected_result.G = 1'bz;
            expected_result.E = 1'bz;
            expected_result.L = 1'bz;
        end:first 
        else begin:not_first
            expected_result.RES = prev_RES;
            expected_result.COUT = prev_COUT;
            expected_result.OFLOW = prev_OFLOW;
            expected_result.ERR = prev_ERR;
            expected_result.G = prev_G;
            expected_result.E = prev_E;
            expected_result.L = prev_L;
        end:not_first
    endtask:load_previous_outputs
    // Reference model function - same as yours but with better error handling
    function alu_sequence_item alu_ref_model(alu_sequence_item input_trans);
        alu_sequence_item expected_result;
       
        // Create expected result object
        expected_result = alu_sequence_item::type_id::create("expected_result");
        expected_result.copy(input_trans); // Copy inputs
        
        if(vif.cb_reference_model.RESET == 1'b1)begin:reset
            expected_result.RES = {`WIDTH+1{1'bz}};
            expected_result.COUT = 1'bz;
            expected_result.ERR = 1'bz;
            expected_result.OFLOW = 1'bz;
            expected_result.G = 1'bz;
            expected_result.E = 1'bz;
            expected_result.L = 1'bz;
        end:reset

      else if(expected_result.CE == 1'b0)begin:inactive_CE
            load_previous_outputs(expected_result);
        end:inactive_CE

        else if(expected_result.CE == 1'b1)begin:clock_enable_active
            expected_result.RES = {`WIDTH+1{1'bz}};
            expected_result.COUT = 1'bz;
            expected_result.ERR = 1'bz;
            expected_result.OFLOW = 1'bz;
            expected_result.G = 1'bz;
            expected_result.E = 1'bz;
            expected_result.L = 1'bz;
            if(expected_result.MODE == 1'b1)begin:arithmetic
                if(expected_result.INP_VALID == 2'b00)begin:INP_VALID_00
                    expected_result.ERR = 1'b1;
                end:INP_VALID_00

                else if(expected_result.INP_VALID == 2'b01)begin:INP_VALID_01
                    case(expected_result.CMD)
                        `INC_A : begin
                                    expected_result.RES = expected_result.OPA + 1;
                                 end
                        `DEC_A : begin
                                    expected_result.RES = expected_result.OPA - 1;
                                 end
                        default : expected_result.ERR = 1'b1;
                    endcase
                end:INP_VALID_01
                else if(expected_result.INP_VALID == 2'b10)begin:INP_VALID_10
                    case(expected_result.CMD)
                        `INC_B : begin
                                    expected_result.RES = expected_result.OPB + 1;
                                 end
                        `DEC_B : begin
                                    expected_result.RES = expected_result.OPB - 1;
                                 end
                        default : expected_result.ERR = 1'b1;
                    endcase
                end:INP_VALID_10

                else if(expected_result.INP_VALID == 2'b11)begin:INP_valid_11
                    case(expected_result.CMD)
                        `ADD : begin
                                  expected_result.RES = expected_result.OPA + expected_result.OPB;
                                  expected_result.COUT = (expected_result.RES[`WIDTH]) ? 1'b1 : 1'b0;
                               end
                        `SUB : begin
                                  expected_result.RES = expected_result.OPA - expected_result.OPB;
                                  expected_result.OFLOW = (expected_result.OPA < expected_result.OPB) ? 1'b1 : 1'b0;
                               end
                    `ADD_CIN : begin
                                  expected_result.RES  = expected_result.OPA + expected_result.OPB + expected_result.CIN;
                                  expected_result.COUT = (expected_result.RES[`WIDTH]) ? 1'b1 : 1'b0;
                               end
                    `SUB_CIN : begin
                                  expected_result.RES = expected_result.OPA - expected_result.OPB - expected_result.CIN;
                                  expected_result.OFLOW = (expected_result.OPA < expected_result.OPB || (expected_result.OPA == expected_result.OPB && expected_result.CIN)) ? 1'b1 : 1'b0;
                               end
                      `INC_A : begin
                                  expected_result.RES = expected_result.OPA + 1;
                               end
                      `DEC_A : begin
                                  expected_result.RES = expected_result.OPA - 1;
                               end
                      `INC_B : begin
                                  expected_result.RES = expected_result.OPB + 1;
                               end
                      `DEC_A : begin
                                  expected_result.RES = expected_result.OPB - 1;
                               end
                        `CMP : begin:CMP
                                    if(expected_result.OPA == expected_result.OPB)begin:eqaul
                                          expected_result.E = 1'b1;
                                    end:eqaul
                                    else if(expected_result.OPA > expected_result.OPB)begin:greater
                                          expected_result.G = 1'b1;
                                    end:greater
                                    else begin:lesser
                                          expected_result.L = 1'b1;
                                    end:lesser
                               end:CMP

                    `MUL_INC : begin:mul_increment
                                  expected_result.OPA = expected_result.OPA + 1;
                                  expected_result.OPB = expected_result.OPB + 1;
                                  expected_result.RES = expected_result.OPA * expected_result.OPB;
                               end:mul_increment
                  `MUL_SHIFT : begin:mul_shift
                                  expected_result.OPA = expected_result.OPA << 1;
                                  expected_result.RES = expected_result.OPA * expected_result.OPB;
                               end:mul_shift
                     default : expected_result.ERR = 1'b1;
                    endcase
                end:INP_valid_11
            end:arithmetic
            else begin:logical
                if(expected_result.INP_VALID == 2'b00)begin:INP_VALID_00
                    expected_result.ERR = 1'b1;
                end:INP_VALID_00
                else if(expected_result.INP_VALID == 2'b01)begin:INP_VALID_01
                   case(expected_result.CMD)
                         `NOT_A : begin
                                    expected_result.RES = {1'b0,~(expected_result.OPA)};
                                  end
                        `SHR1_A : begin
                                    expected_result.RES = {1'b0,expected_result.OPA >> 1};
                                  end
                        `SHL1_A : begin
                                    expected_result.RES = {1'b0,expected_result.OPA << 1};
                                  end
                        default : expected_result.ERR = 1'b1;
                    endcase
                end:INP_VALID_01
                else if(expected_result.INP_VALID == 2'b10)begin:INP_VALID_10
                    case(expected_result.CMD)
                         `NOT_B : begin
                                     expected_result.RES = {1'b0,~(expected_result.OPB)};
                                  end
                        `SHR1_B : begin
                                     expected_result.RES = {1'b0,expected_result.OPB >> 1};
                                  end
                        `SHL1_B : begin
                                     expected_result.RES = {1'b0,expected_result.OPB << 1};
                                  end
                        default : expected_result.ERR = 1'b1;
                    endcase
                end:INP_VALID_10

                else if(expected_result.INP_VALID == 2'b11)begin:INP_valid_11
                    case(expected_result.CMD)
                         `AND : begin
                                   expected_result.RES = {1'b0,expected_result.OPA & expected_result.OPB};
                                end
                        `NAND : begin
                                   expected_result.RES = {1'b0,~(expected_result.OPA & expected_result.OPB)};
                                end
                          `OR : begin
                                   expected_result.RES = {1'b0,expected_result.OPA | expected_result.OPB};
                                end
                         `NOR : begin
                                   expected_result.RES = {1'b0,~(expected_result.OPA | expected_result.OPB)};
                                end
                         `XOR : begin
                                   expected_result.RES = {1'b0,expected_result.OPA ^ expected_result.OPB};
                                end
                        `XNOR : begin
                                   expected_result.RES = {1'b0,~(expected_result.OPA ^ expected_result.OPB)};
                                end
                       `NOT_A : begin
                                   expected_result.RES = {1'b0,~(expected_result.OPA)};
                                end
                      `SHR1_A : begin
                                   expected_result.RES = {1'b0,expected_result.OPA >> 1};
                                end
                      `SHL1_A : begin
                                   expected_result.RES = {1'b0,expected_result.OPA << 1};
                                end
                       `NOT_B : begin
                                   expected_result.RES = {1'b0,~(expected_result.OPB)};
                                end
                      `SHR1_B : begin
                                   expected_result.RES = {1'b0,expected_result.OPB >> 1};
                                end
                      `SHL1_B : begin
                                   expected_result.RES = {1'b0,expected_result.OPB << 1};
                                end
                     `ROL_A_B : begin
                                   int value1 =  expected_result.OPB[`ROR_WIDTH-1:0];
                                   expected_result.RES = {1'b0,(expected_result.OPA << value1 | expected_result.OPA >> (`WIDTH - value1))};
                                   expected_result.ERR = (expected_result.OPB > {`ROR_WIDTH + 1{1'b1}});
                                end
                     `ROR_A_B : begin
                                   int value1 =  expected_result.OPB[`ROR_WIDTH-1:0];
                                   expected_result.RES = {1'b0,(expected_result.OPA >> value1 | expected_result.OPA << (`WIDTH - value1))};
                                   expected_result.ERR = (expected_result.OPB > {`ROR_WIDTH + 1{1'b1}});
                                end
                      default : expected_result.ERR = 1'b1;
                    endcase
                end:INP_valid_11
            end:logical

            store_previous_outputs(expected_result);
        end:clock_enable_active
        return expected_result;
    endfunction
    
    virtual task run_phase(uvm_phase phase);
        alu_sequence_item actual_result;    // From monitor
        alu_sequence_item input_stimulus;   // From driver  
        alu_sequence_item expected_result;  // From reference model
        
        forever begin:forever_loop
            // Wait for both queues to have data
          wait(active_monitor_queue.size() > 0 && passive_monitor_queue.size() > 0);
            
            `uvm_info(get_type_name(), $sformatf("-------------------------------------"), UVM_LOW)
            
            // Get actual results and input stimulus
            actual_result = passive_monitor_queue.pop_front();
            input_stimulus = active_monitor_queue.pop_front();


            `uvm_info(get_type_name(), $sformatf(
                "Processing: opa=%0d opb=%0d cmd=%0d mode=%0d,inp_valid = %0d,ce = %0d,cin = %0d",
                input_stimulus.OPA, input_stimulus.OPB, input_stimulus.CMD, input_stimulus.MODE,input_stimulus.INP_VALID,input_stimulus.CE,input_stimulus.CIN), UVM_LOW)
            
            // Generate expected results using reference model
            expected_result = alu_ref_model(input_stimulus);
            
            // Compare actual vs expected
          if ({actual_result.RES, actual_result.ERR, actual_result.OFLOW, actual_result.COUT, 
               actual_result.G, actual_result.E, actual_result.L} === 
              {expected_result.RES, expected_result.ERR, expected_result.OFLOW, expected_result.COUT, 
               expected_result.G, expected_result.E, expected_result.L}) begin:comparing_match
                
                match++;
                `uvm_info(get_type_name(), "----           TEST PASS           ----", UVM_NONE)
                `uvm_info(get_type_name(), "---------------------------------------", UVM_NONE)
                `uvm_info(get_type_name(), $sformatf("Expected: res=%0d err=%0d oflow=%0d cout=%0d g=%0d e=%0d l=%0d",
                    expected_result.RES, expected_result.ERR, expected_result.OFLOW, expected_result.COUT, 
                    expected_result.G, expected_result.E, expected_result.L), UVM_LOW)
                `uvm_info(get_type_name(), $sformatf("Actual  : res=%0d err=%0d oflow=%0d cout=%0d g=%0d e=%0d l=%0d",
                    actual_result.RES, actual_result.ERR, actual_result.OFLOW, actual_result.COUT, 
                    actual_result.G, actual_result.E, actual_result.L), UVM_LOW)
            `uvm_info(get_type_name(),$sformatf("MATCH = %0d ,MISMATCH = %0d",match,mismatch),UVM_MEDIUM);
                    
            end:comparing_match
          	else begin:compare_mismatch
                mismatch++;
                `uvm_error(get_type_name(), "----           TEST FAIL           ----")
                `uvm_info(get_type_name(), "---------------------------------------", UVM_NONE)
                `uvm_info(get_type_name(), $sformatf("Expected: res=%0d err=%0d oflow=%0d cout=%0d g=%0d e=%0d l=%0d",
                    expected_result.RES, expected_result.ERR, expected_result.OFLOW, expected_result.COUT, 
                    expected_result.G, expected_result.E, expected_result.L), UVM_LOW)
                `uvm_info(get_type_name(), $sformatf("Actual  : res=%0d err=%0d oflow=%0d cout=%0d g=%0d e=%0d l=%0d",
                    actual_result.RES, actual_result.ERR, actual_result.OFLOW, actual_result.COUT, 
                    actual_result.G, actual_result.E, actual_result.L), UVM_LOW)
            end:compare_mismatch
            `uvm_info(get_type_name(),$sformatf("MATCH = %0d ,MISMATCH = %0d",match,mismatch),UVM_MEDIUM);
            `uvm_info(get_type_name(), "------------------------------------", UVM_LOW)
        end:forever_loop
    endtask:run_phase
endclass:alu_scoreboard

