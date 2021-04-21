%Description: 
% This generates Huffman encoded code based on its category and the value 
%Input: category, value, huffman table
%Output: Huffman encoded code 
%Created by: Suah Kim
%Last edited by: Suah Kim, 4/21/2021

function [encoded_binary]=huffman_encode(categories,values,h_table)
categories(categories=="")=[];
encoded_binary=strings(1,length(categories));
for i1 = 1:length(categories)
        codeword=h_table(h_table(:,1)==(categories(i1)),3);
        encoded_binary(i1)=string([char(codeword) char(values(i1))]);
end
encoded_binary=char(strjoin(encoded_binary));
encoded_binary(encoded_binary==' ')=[];
end