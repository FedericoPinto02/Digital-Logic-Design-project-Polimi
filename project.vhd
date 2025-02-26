library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use ieee.std_logic_unsigned.all;
use std.textio.all;




entity project_reti_logiche is
PORT(
    i_clk       : IN  std_logic;
    i_rst       : IN  std_logic;
    i_start     : IN  std_logic;
    i_add       : IN  std_logic_vector(15 DOWNTO 0);
    i_k         : IN  std_logic_vector(9 DOWNTO 0);
    
    o_done      : OUT std_logic;
    
    o_mem_addr  : OUT std_logic_vector(15 DOWNTO 0);
    i_mem_data  : IN  std_logic_vector(7 DOWNTO 0);
    o_mem_data  : OUT std_logic_vector(7 DOWNTO 0);
    o_mem_we    : OUT std_logic;
    o_mem_en    : OUT std_logic
  );
end project_reti_logiche;

architecture behavioral of project_reti_logiche is
  
 -- STATE MACHINE SIGNAL
  signal r1_select :  STD_LOGIC;
  signal r2_load :    STD_LOGIC;
  signal r2_select :  STD_LOGIC;
  signal r3_load :    STD_LOGIC;
  signal r3_select :  STD_LOGIC;
  signal r4_load :    STD_LOGIC;
  signal r4_select :  STD_LOGIC;
  signal r5_load :    STD_LOGIC;
  signal r5_select :  STD_LOGIC;
  signal cr_load :    STD_LOGIC;
  signal cr_select :  STD_LOGIC;
  signal help_select :  STD_LOGIC;
  signal help_done_clk :  STD_LOGIC;
  
  
 
  --SIGNAL TO SEND DATA
signal o_reg2 : STD_LOGIC_VECTOR(15 downto 0);
signal o_reg3 : STD_LOGIC_VECTOR(10 downto 0);
signal o_reg4 : STD_LOGIC_VECTOR(7 downto 0);
signal o_reg5 : STD_LOGIC_VECTOR(7 downto 0);
signal o_reg_cr : STD_LOGIC_VECTOR(7 downto 0);
signal dec_k : STD_LOGIC_VECTOR(10 downto 0);
signal dec_cr : STD_LOGIC_VECTOR(7 downto 0);
signal mul : STD_LOGIC_VECTOR(10 downto 0);
signal help_for_done : STD_LOGIC; 
signal mux_1 : STD_LOGIC_VECTOR(15 downto 0);
signal mux_3 :  STD_LOGIC_VECTOR(10 downto 0);
signal demux_4_0 : STD_LOGIC_VECTOR(7 downto 0);
signal demux_4_1 : STD_LOGIC_VECTOR(7 downto 0);
signal mux_5 : STD_LOGIC_VECTOR(7 downto 0);
signal mux_cr : STD_LOGIC_VECTOR(7 downto 0);
signal mux_help : STD_LOGIC_VECTOR(7 downto 0);
signal final_select : STD_LOGIC;


--FSM SIGNAL AND STATE
type S is(S0,S1,S2,S3,S4,S5,S6,S7,S8,S9,S10,S11,S12,S13);
signal cur_state, next_state : S;

begin

-- ADDER

--MULTIPLEXER
   with r1_select  select 
     mux_1 <= i_add when '0',
              o_reg2 when '1',
              "XXXXXXXXXXXXXXXX" when others;

--REGISTRO 
  process(i_clk,i_rst,i_add,i_start)
 begin
  if(i_rst= '1' or i_start='0') then 
     o_reg2<="0000000000000000";
  elsif i_clk 'event and i_clk = '1' then
      if(r2_load='1') then
       o_reg2<=mux_1+'1';
       end if;
     end if;
   end process;

--MULTIPLEXER
 with r2_select  select 
     o_mem_addr <= o_reg2 when '1',
              i_add when '0',
             "XXXXXXXXXXXXXXXX" when others;

--k counter 
       
      -- ESTENSIONE A 11 BIT + MOLTIPLICAZIONE
      process(i_k)
      begin
      mul<= i_k & '0';  
      end process;
      
--MULTIPLEXER      
      with r3_select  select 
      mux_3 <= mul when '0',
              dec_k when '1',
              "XXXXXXXXXXX" when others;
              
--REGISTRO       
      process(i_clk,i_rst,i_start)
 begin
  if(i_rst= '1' or i_start='0') then 
     o_reg3<="00000000001";
  elsif i_clk 'event and i_clk = '1' then
      if(r3_load='1') then
       o_reg3<=mux_3;
       end if; 
     end if;
   end process; 
   
--DECREMENTO   
   dec_k<= o_reg3 - 1;
   
 -- SELETTORE PER AIUTO O_DONE  
   process(i_rst,o_reg3,i_start)
   begin
    if(i_rst= '1' or i_start='0') then
      help_for_done <= '0';
      elsif (o_reg3 = "00000000000") then
        help_for_done <= '1';
        else
         help_for_done <= '0';
         end if;
   end process;

-- SELETTORE O_DONE   
   o_done <= '0' when (cur_state = S0) else help_for_done;

-- SEGNALE CONTROLLO K PARI/DISPARI  
   process(i_rst,o_reg3,i_start)
   begin
    if(i_rst= '1' or i_start='0') then
      final_select<= '0';
      elsif (to_integer(unsigned(o_reg3)) mod 2 = 0 ) then
        final_select <= '1';
        else
        final_select <= '0';
         end if;
   end process; 
   
   

    --CREDIBILITY BLOCK
   
    with cr_select  select 
      mux_cr <= "00011111" when '0',
              dec_cr when '1',
              "XXXXXXXX" when others;
              
             
  --REGISTRO             
     process(i_clk,i_rst,i_start,o_reg5)
 begin
  if(i_rst= '1' or i_start='0') then 
     o_reg_cr<="00000000";
  elsif i_clk 'event and i_clk = '0' then
      if(cr_load='1' and o_reg5 /= "00000000") then
       o_reg_cr<=mux_cr;
       end if;
     end if;
   end process;   
   
  -- DECREMENTO CONTROLLATO DELLA CREDIBILITA' 
   process(i_rst,final_select,o_reg_cr,i_start)
   begin
    if(i_rst= '1' or i_start='0') then
      dec_cr <= "00000000";
      elsif (final_select = '1' and o_reg_cr/="00000000") then
        dec_cr <=  std_logic_vector(unsigned(o_reg_cr) - 1);
        else
        dec_cr <=  o_reg_cr;
         end if;
   end process; 
   
  
   --LOGIC BLOCK 
 
 --REGISTRO   
    process(i_clk,i_rst,i_start)
 begin
   if(i_rst= '1' or i_start='0') then 
     o_reg4<="00000000";
  elsif i_clk 'event and i_clk = '1' then
      if(r4_load='1') then
       o_reg4<=i_mem_data;
       end if;
     end if;
   end process;    
  
  --DEMULTIPLEXER    
     process(o_reg4,final_select,i_rst,i_start)
    begin
   if(i_rst= '1' or i_start='0') then
   demux_4_1<="00000000";
   demux_4_0<="00000000";
   elsif(final_select='1' ) then 
   demux_4_0<= o_reg4;
   demux_4_1<="00000000";
   elsif(final_select='0') then 
   demux_4_1<= o_reg4;
    demux_4_0<=o_reg4;
   else
   demux_4_1<="XXXXXXXX";
   demux_4_0<="XXXXXXXX";
   end if;
   end process;
  
  --REGISTRO  
    process(i_clk,i_rst,i_start,o_reg2,i_add )
 begin
  if(i_rst= '1' or i_start='0') then 
     o_reg5<="00000000";
  elsif i_clk 'event and i_clk = '0' then
      if(r5_load='1' and demux_4_0/="00000000" and to_integer(unsigned(o_reg2)- unsigned(i_add)) mod 2 /= 0 ) then
       o_reg5<=demux_4_0;
       end if;
     end if;
   end process; 
  
  --MULTIPLEXER 
              
     process(r5_select,o_reg5,demux_4_1)
       begin
       if( r5_select = '0') then
          mux_5 <= o_reg5;
          elsif( r5_select = '1' ) then
           mux_5 <= demux_4_1;
           else
           mux_5<="XXXXXXXX";
           end if;
          end process;          
 
 --MULTIPLEXER             
               process(help_select,mux_5,i_mem_data)
       begin
       if(help_select = '0' and i_mem_data/="00000000") then
          mux_help <= i_mem_data;
          else
          mux_help <= mux_5;
           end if;
          end process;
  
  --MULTIPLEXER        
          with final_select  select 
      o_mem_data <= o_reg_cr when '0',
              mux_help when '1',
              "XXXXXXXX" when others;
       
       --FSM   
           
           process(i_clk,i_rst,i_start)
        begin
             if(i_rst='1' or i_start='0') then
               cur_state<= S0;
               elsif i_clk 'event and i_clk = '1' then 
               cur_state <= next_state;
               
               else
               end if;
               end process;    
 
      process(cur_state,i_start,help_for_done,o_reg4,i_mem_data,i_k,o_reg2,i_add)
         begin
         
            next_state<=cur_state;
            
             case cur_state is
             
               when S0 => 
                    if (i_start = '1') then
                     next_state<=S1;
                    else
                    next_state<=S0;
                     end if;
                     
               when S1 => 
                  
                  next_state<=S2;
                  
                 
                    
               
               
                when S2 =>  
                
                
                  next_state<=S13;
                 
          
                     
               when S13 => 
               if(i_mem_data="00000000") then
               next_state<=S11;
               else
               next_state<=S3;
               end if;       
                
               when S3 => next_state<=S4;       
               
               when S4 => next_state<=S5;   
                       
               when S5 => 
                     
                    if (o_reg4/="00000000" and to_integer(unsigned(o_reg2)- unsigned(i_add)) mod 2 /= 0) then
                     next_state<=S9;
                     else
                     next_state<=S10;
                    end if;    
               
               when S6 => 
                if help_for_done = '1' then
                     next_state<=S8;
                      else
                     next_state<=S5;
                     end if;            
                     
               when S7 => 
                     
                     next_state<=S6;
                                
              
              when S8 => next_state<=S0;
                      
              when S9 => next_state<=S7;  
                    
              when S10 => next_state<=S7; 
              
              when S11 => next_state<=S12;
              
              when S12 => next_state<=S5;
              
            
        
             end case;
          end process;  
          
      process(cur_state)
             begin
              
              r1_select <= '1';
              r2_load <= '0';
              r2_select <= '1';
              r3_load <= '0';
              r3_select <= '0';
              r4_load <= '0';
              r4_select <= '0';
              r5_load <= '0';
              r5_select <= '0';
              cr_load <= '0';
              cr_select <= '1';
              o_mem_we <= '0';    
              o_mem_en <= '0';
              help_select<= '1';
               
              
              
              case cur_state is
              
                   when S0=> 
                  o_mem_en <= '1';
                   
                   
                   when S1=> 
                      r1_select <= '0';
                      r2_load <= '1';
                      r2_select <= '0';
                      o_mem_we <= '0';    
                      o_mem_en <= '1';  
                      
                   when S2=> 
                     r4_load <= '1';
                     r3_load <= '1';
                     r3_select <= '0';
                     r2_load <= '0';
                     r2_select <= '0';
                     o_mem_we <= '0';    
                     o_mem_en <= '1';
                     
                   when S3=> 
                       r3_load <= '0';
                       r3_select <= '1';
                       r2_load <= '0';
                       r2_select <= '0';
                       o_mem_we <= '0';    
                       o_mem_en <= '1';
                       r5_load <= '1';
                       r5_select <= '0'; 
                       
                    when S4=> 
                       r3_load <= '1';
                       r3_select <= '1'; 
                       r2_load <= '0';
                       r2_select <= '0';
                       o_mem_we <= '1';    
                       o_mem_en <= '1';
                       cr_load <= '1';
                       cr_select <= '0'; 
                    
                    when S5=> 
                       r3_load <= '0';
                       r3_select <= '1'; 
                       r2_load <= '0';
                       o_mem_we <= '0';    
                       o_mem_en <= '1';
                       cr_select <= '1'; 
                       
                     when S6 =>   
                     
                       cr_load <= '1'; 
                       r5_load <= '1';  
                     
                     when S7 => 
                       r3_load <= '1';
                       r3_select <= '1';
                       o_mem_we <= '1';    
                       o_mem_en <= '1';
                       r2_load <= '1';
                       r4_load <= '1';
                       help_select<= '0';      

                      when S8 =>  
                      
                    
                      
                      when S9=>
                        cr_select <= '0';
                        cr_load <= '1';
                        r3_load <= '0';
                        r3_select <= '1'; 
                        r2_load <= '0';
                        o_mem_we <= '0';    
                        o_mem_en <= '1'; 
                     
                       when S10=>
                         o_mem_we <= '0';    
                         o_mem_en <= '1'; 
                       
                        when S11=>
                       r3_load <= '0';
                       r3_select <= '1';
                       r2_load <= '0';
                       r2_select <= '0';
                       o_mem_we <= '0';    
                       o_mem_en <= '1';
                       r5_load <= '0';
                       r5_select <= '0'; 
                       help_select<= '0';
                       
                       
                        when S12 =>
                        
                        r3_load <= '1';
                       r3_select <= '1'; 
                       r2_load <= '0';
                       r2_select <= '0';
                       o_mem_we <= '1';    
                       o_mem_en <= '1';
                       
                       when S13 =>
                       
                       r2_select <= '0';
                     o_mem_we <= '0';    
                     o_mem_en <= '1';
                    
                  
                      
                end case;
                     
              end process;
              
           end behavioral;     
                     
                                           
 
   
  
              
              
  
  
  
   
   
   
  
              
              
   
   
 
       
       

        
    
   
  
   

   
   
     
  
     
      
     
      
   
      
    
   
       
      
              
              
               
              
              
     
   
   
                
       
                 
  
         
              
                     
                     
                     
                     
                    
                     
                     
                     
                   
                     
                    
               
                    
                     
                    
                    
                     
                     
                      
                    
                       
                      
                   
                    
                     
                    
                  
                     
                     
                     
                     
             
                   
                   
                    
                    
                     
                          
                          
                             
                     
                    
                       
                        
                         
                       
                     
                    
                        
                        
                    
                      
                        
                   
                   
                    
                    
                     
                    
                   
                    
                       
                       
                
                   
                   
                  

                   
                  
             
                  
             
                  
  



