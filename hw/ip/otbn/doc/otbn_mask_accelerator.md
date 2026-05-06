```mermaid
graph LR
    %% Set standard RTL shape styles
    %% [Register/Flop]
    %% {{Combinational Logic}}
    %% [[Sub-module Instance]]
    %% {2-to-1 Mux}
    %% (((Round shape for arithmetic operator)))
    
    %% ============================================================
    %% 1. EXTERNAL PORTS
    %% ============================================================
    subgraph Ports_IN [Inputs]
        direction TB
        clk_rst(clk_i / rst_ni)
        wvalid(wvalid_i)
        stall(stall_i)
        ab_in(a_i / b_i \n [NumShares])
        q_i(q_i \n [Modulus])
        rand(rand_i \n [Masking])
        enable_mod(enable_mod_i)
    end

    subgraph Ports_OUT [Outputs]
        direction TB
        wready(wready_o)
        rvalid(rvalid_o)
        sum_out(sum_o \n [NumShares])
        err(ctr_err_o)
    end

    %% ============================================================
    %% 2. INTERNAL MODULE DATAPATH
    %% ============================================================
    subgraph otbn_sec_add_mod [otbn_sec_add_mod module]
        direction LR

        %% --- Control Logic ---
        subgraph Control [Control & Sequencing]
            direction TB
            MuxStateD{{Mux State Calc}}
            MuxStateQ[Mux State Reg \n Latency deep]
            
            VecInsert{{vector_inserted_pulse}}
            InpCtr[[prim_count: Input Counter]]
        end

        %% --- Input Stage ---
        subgraph InputStage [Input Multiplexing]
            direction TB
            MuxA{Mux A \n [NumShares]}
            MuxB{Mux B \n [NumShares]}
        end

        %% --- Core Arithmetic ---
        subgraph DatapathCore [Secure Adder]
            direction LR
            SecAdd[[otbn_sec_add: core]]
            AddCarry(((Split Carry Bits \n sum[Width])))
            AddSum(((Split Sum Bits \n sum[Width-1:0])))
        end

        %% --- Storage ---
        subgraph Storage [Intermediate Buffer]
            direction TB
            Blanker[[prim_blanker]]
            FlopChain[(prim_flop_en Chain \n BufferDepth deep)]
        end

        %% --- Modulo Correction ---
        subgraph CorrectionLogic [Modulo Fix Calc]
            direction TB
            CarryExtract{{Extract Carry \n add_mod[NumShares]}}
            ModCorrect{{mod_correction Calc \n -Q vs 0}}
        end

        %% --- Output Muxing ---
        subgraph OutputStage [Output Gating]
            RouteLogic{{Output Route Logic}}
            FinalOutGates(((Output Mux/Gate)))
        end

        %% ============================================================
        %% 3. CONNECTIONS (DATAPATH & CONTROL)
        %% ============================================================

        %% --- Input Handshake ---
        stall -->|sec_add_stall| SecAdd
        MuxStateQ -.->|mux_state_q[0] - Sel control| MuxA
        MuxStateQ -.->|mux_state_q[0] - Sel control| MuxB
        MuxStateQ -.->|!mux_state_q[0]| wready

        %% --- Control Flow ---
        enable_mod --> MuxStateD
        enable_mod --> VecInsert
        enable_mod --> InpCtr
        VecInsert --> MuxStateD
        MuxStateD --> MuxStateQ
        
        SecAdd -.->|sec_add_inp_valid| MuxStateQ
        SecAdd -.->|sec_add_inp_valid| InpCtr
        
        InpCtr --> VecInsert
        InpCtr --> err

        %% --- Datapath Pass 1 (A+B) ---
        ab_in -->|Pass 1 ops| MuxA
        ab_in -->|Pass 1 ops| MuxB
        MuxA -->|addend_a| SecAdd
        MuxB -->|addend_b| SecAdd
        
        SecAdd --> AddCarry
        SecAdd --> AddSum
        
        %% --- Buffer/Storage Flow ---
        AddSum --> Blanker
        AddCarry --> Blanker
        Blanker -->|buffer_data[0]| FlopChain
        
        MuxStateQ -.->|buffer_advance control| FlopChain

        %% --- Modulo Correction Loop (Pass 2) ---
        FlopChain -->|buffer_data[BufferDepth]| CarryExtract
        FlopChain -->|buffer_data[BufferDepth] \n intermediate sum| MuxA
        
        CarryExtract -->|add_mod| ModCorrect
        q_i --> ModCorrect
        
        ModCorrect -->|mod_correction| MuxB
        
        %% --- Output Flow ---
        enable_mod --> RouteLogic
        MuxStateQ -.->|mux_state_q[Latency]| RouteLogic
        RouteLogic -.->|route_sum_out control| FinalOutGates
        RouteLogic -.->|route_sum_out control| Blanker

        AddSum -->|Pass 1/2 results| FinalOutGates
        SecAdd -.->|sec_add_oup_valid| FinalOutGates
        
        FinalOutGates --> sum_out
        FinalOutGates --> rvalid

    end
```
