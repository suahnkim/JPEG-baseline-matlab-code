%Description: 
% Encodes jpeg image into JFIF stream
% most of the JFIF markers are explained in the code.  
% Doesn't support rst marker at the moment => future plan 
%Input: 
%Output: JFIF stream 
%Created by: Suah Kim
%Last edited by: Suah Kim, 4/21/2021

function JFIF_stream=JFIF_encoder(image_stream,image_height,image_width,number_of_components,q_table,q_table_chm,h_table_DC_lum,h_table_AC_lum,h_table_DC_chm,h_table_AC_chm,sampling_factors)
% SOI 
SOI = hex2dec(["FF" "D8"]);

% APP segment data
% This does not change unless explicit thumbnails are required =>
% But, explicit thumbnails are not supported anymore
APP_segment = hex2dec(["FF" "E0", "00" "10" "4A" "46" "49" "46" "00" "01" "01" "00" "00" "01" "00" "01" "00" "00"]);

% Quantization table
q_table_precision_id = "00"; %(xy), where x is 8 bit precision=0 16 bit precision=1, and y is q_table id 0~3
q_table_segment=[hex2dec(["FF" "DB"]) q_table_JIFF(q_table_precision_id,q_table)];
if number_of_components == 3
    % Chrominance quantization table
    q_table_precision_id_chm = "01"; %(xy), where x is 8 bit precision=0 16 bit precision=1, and y is q_table id 0~3
    q_table_segment=[q_table_segment hex2dec(["FF" "DB"]) q_table_JIFF(q_table_precision_id_chm,q_table_chm)];
end

% DC Huffman table
h_table_DC_lum_id="00"; % (xy), where x is DC=0 AC=1 identifier, and y is luminance=0 chrominance=1 identifier
h_table_segment=[hex2dec(["FF" "C4"]) h_table_JIFF(h_table_DC_lum_id,h_table_DC_lum)];

% AC Huffman table
h_table_AC_lum_id="10"; % (xy), where x is DC=0 AC=1 identifier, and y is luminance=0 chrominance=1 identifier
h_table_segment=[h_table_segment hex2dec(["FF" "C4"]) h_table_JIFF(h_table_AC_lum_id,h_table_AC_lum)];

if number_of_components == 3
    % Chrominance DC Huffman table
    h_table_DC_chm_id="01"; % (xy), where x is DC=0 AC=1 identifier, and y is luminance=0 chrominance=1 identifier
    h_table_segment=[h_table_segment hex2dec(["FF" "C4"]) h_table_JIFF(h_table_DC_chm_id,h_table_DC_chm)];
    
    % Chrominance AC Huffman table
    h_table_AC_chm_id="11"; % (xy), where x is DC=0 AC=1 identifier, and y is luminance=0 chrominance=1 identifier
    h_table_segment=[h_table_segment hex2dec(["FF" "C4"]) h_table_JIFF(h_table_AC_chm_id,h_table_AC_chm)];
end

% SOF
bits_precision=8; %baseline is 8
s_f_code=string(strcat(num2str(sampling_factors(1,1)),num2str(sampling_factors(1,2)))); % sampling factor code
component_q_info=["01" s_f_code "00"]; % [x y z], where x is Y=01 Cb=02 Cr=03, y is sampling factor, z is q_table id(not q_table_precision_id)
if number_of_components==3
    s_f_code_cb=string(strcat(num2str(sampling_factors(2,1)),num2str(sampling_factors(2,2))));
    s_f_code_cr=string(strcat(num2str(sampling_factors(3,1)),num2str(sampling_factors(3,2))));
    component_q_info=[component_q_info, "02" s_f_code_cb "01", "03" s_f_code_cr "01"];
end
SOF_segment_length = 2+1+2+2+1+number_of_components*3;
SOF_segment=[hex2dec(["FF" "C0"]) dec2uint8(SOF_segment_length,2) bits_precision dec2uint8(image_height,2) dec2uint8(image_width,2) number_of_components hex2dec(component_q_info)];

% SOS
SOS_segment_length = 2+1+number_of_components*2+3;
component_huffman_info=["01" "00"]; % [x yz], where x is Y=01 Cb=02 Cr=03, y is huffmantable id for DC, and Z is huffmantable id for AC
if number_of_components == 3
    component_huffman_info=[component_huffman_info, "02" "11", "03" "11"];
end
SOS_segment=[hex2dec(["FF" "DA"]) dec2uint8(SOS_segment_length,2) number_of_components hex2dec(component_huffman_info) hex2dec(["00" "3F" "00"])];

% JFIF
JFIF_stream = [SOI APP_segment q_table_segment h_table_segment SOF_segment SOS_segment bytestuffing(image_stream) hex2dec(["FF" "D9"])];
end

function q_table_segment=q_table_JIFF(q_table_number,q_table)
zig_zag=[...
    1 9 2 3 10 17 25 18 11 4 5 12 19 26 ...
    33 41 34 27 20 13 6 7 14 21 28 35 ...
    42 49 57 50 43 36 29 22 15 8 16 23 ...
    30 37 44 51 58 59 52 45 38 31 24 32 ...
    39 46 53 60 61 54 47 40 48 55 62 63 56 64];
v_quantization_table=q_table(zig_zag);
quantization_table_segment_length = 2 + 1 + length(v_quantization_table);
q_table_segment=[dec2uint8(quantization_table_segment_length,2) hex2dec(q_table_number) v_quantization_table];
end

function h_table_segment=h_table_JIFF(h_table_number,h_table)
A=tabulate(double(h_table(:,2)));
B=transpose([1:16; zeros(1,16)]);
B(A(:,1),2)=A(:,2);
h_table_frequency=transpose(B(:,2));
[~,index]=sortrows([double(h_table(:,2)) bin2dec(h_table(:,3))], [1,2]);
v_h_category = hex2dec(reshape(h_table(index,1),1,[]));
huffman_table_segment_length = 2 + 1 + length(h_table_frequency)+ length(v_h_category);
h_table_segment=[dec2uint8(huffman_table_segment_length,2) hex2dec(h_table_number) h_table_frequency v_h_category];
end

function uint8_number = dec2uint8(decimal_number,max_digits)
x=decimal_number;
uint8_number = zeros(1,max_digits);
remainder=mod(x,256);
quotient=(x-remainder)/256;
digits=1;
uint8_number(digits)=remainder;
x=quotient;
while quotient ~=0
    remainder=mod(quotient,256);
    quotient=(x-remainder)/256;
    x=quotient;
    digits=digits+1;
    uint8_number(digits)=remainder;
end
uint8_number=uint8(uint8_number(end:-1:1));
if max_digits < length(uint8_number)
    disp('max digits exceeded')
end
end

function new_stream=bytestuffing(stream)
% bytestuffing => Because 0xFF is a code identifier 0xFF is appended to differentiate them 
new_stream=zeros(1,length(stream)+sum(stream==255));
j=0;
for i=1:length(stream)
    new_stream(i+j) = stream(i);
    if stream(i) == 255
        j=j+1;
    end
end
end