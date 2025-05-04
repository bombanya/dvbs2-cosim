// Copyright (c) 2025 Nikita Proshkin
// All rights reserved.

module dvbs_top ();
    wire axis_dvbs_tvalid;
    wire [7:0] axis_dvbs_tdata;
    wire axis_dvbs_tlast;
    wire axis_dvbs_tready;
    wire clk;
    wire rst;

    wire m_tready;
    wire m_tvalid;
    wire m_tlast;
    wire [7:0] m_tdata;

    assign m_tready = 1;

    integer fd;
    integer i = 0;
    reg [31:0] wr_buffer;

    fec_encoder fec_encoder(
        .clk(clk),
        .rst(rst),
        .s_tvalid(axis_dvbs_tvalid),
        .s_tdata(axis_dvbs_tdata),
        .s_tlast(axis_dvbs_tlast),
        .s_tready(axis_dvbs_tready),
        .m_tready(m_tready),
        .m_tvalid(m_tvalid),
        .m_tlast(m_tlast),
        .m_tdata(m_tdata)
    );

    stream_adapter stream_adapter(
            .axis_dvbs_tvalid(axis_dvbs_tvalid),
            .axis_dvbs_tdata(axis_dvbs_tdata),
            .axis_dvbs_tlast(axis_dvbs_tlast),
            .axis_dvbs_tready(axis_dvbs_tready),
            .rst_o(rst),
            .clk(clk)
    );

    initial begin
        fd = $fopen("cosim_res.bin", "wb");
    end

    always @(posedge clk) begin
        if (m_tready && m_tvalid) begin
            wr_buffer <= {m_tdata, wr_buffer[31:8]};

            if (i == 4) begin
                $fwrite(fd, "%u", wr_buffer);
                i <= 1;
            end else begin
                i <= i + 1;
            end
        end
    end

endmodule
