%Description: 
% In order to reduce the scanning the quantized coefficients, this is used
% to generate the statistic which is used to generate optimized Huffman table and
% the size with the corresponding value. 
%Input: quantized zigzag ordered DPCM DC coefficients
%Output: Table summarizing frequency of quantized DC coefficient's sizes, size category in hexadecimal, the corresponding value 
%Created by: Suah Kim
%Last edited by: Suah Kim, 4/21/2021

function [category_frequency_table, categories, values]=category_tabulate(coefficients)
categories = dec2hex(ceil(log2(abs(coefficients)+1)));
category_frequency_table = tabulate((categories));
values = strings(length(coefficients),1);
for i1=1:length(coefficients)
    values(i1)=string(value_binarization(coefficients(i1)));
end
end