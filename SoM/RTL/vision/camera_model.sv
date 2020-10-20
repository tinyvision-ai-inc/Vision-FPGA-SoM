    
    /*
     Send out a single frame of known data for verification
     Assumes ROWS, COLS as defined constants
     */
task send_incr_frame;
    
        begin
            
            frame_vld = '0;
            line_vld = '0;
            pixel_dat = '0;
            $display("Starting image transfer");
            
            repeat (10) @(posedge pixel_clk);
            frame_vld = '1;
            
            repeat (5) @(posedge pixel_clk);
            
            repeat (ROWS) begin
                line_vld = '0;
                repeat (5) @(posedge pixel_clk);
                line_vld = '1;
                repeat (COLS) begin
                    pixel_dat = pixel_dat + 'd1;
                    @(posedge pixel_clk);
                end
                
                line_vld = '0;
                
            end
            repeat (10) @(posedge pixel_clk);
            frame_vld = '0;
        end
        
endtask // send_incr_frame