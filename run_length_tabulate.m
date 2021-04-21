%Description: 
% In order to reduce the scanning the quantized coefficients, this is used
% to generate the statistic which is used to generate optimized Huffman table and
% the run-length with the corresponding value. 
%Input: quantized zigzag ordered AC coefficients
%Output: Table summarizing frequency of runlength and value, runlength and size category in hexadecimal, the corresponding value 
%Created by: Suah Kim
%Last edited by: Suah Kim, 4/21/2021

function [category_frequency_table, run_length_size_categories, values]=run_length_tabulate(coefficients)
% convert the coefficients into runlength categories
[num_blocks,~]=size(coefficients);
run_length_size_categories=strings(num_blocks,63);
values=strings(num_blocks,63);
for i1=1:num_blocks
    coefficient_array=coefficients(i1,:);
    run_length=0;
    k1=0;
    for j1=1:63
        coefficient=coefficient_array(j1);
        if coefficient == 0
            if isequal(coefficient_array(j1:end),zeros(1,length(coefficient_array(j1:end))))
                run_length_size_categories(i1,j1)="00";
                k1=k1+1;
                values(i1,k1)="";
                break;
            elseif run_length == 15
                run_length_size_categories(i1,j1)="F0";
                k1=k1+1;    
                values(i1,k1)="";
                run_length=0;
            else
                run_length=run_length+1;
            end
        else
            size_category = sprintf('%1X',ceil(log2(abs(coefficient)+1)));
            run_length_category = sprintf('%1X',run_length);
            run_length_size_categories(i1,j1)=string([run_length_category size_category]);
            k1=k1+1;
            values(i1,k1)=value_binarization(coefficient);
            run_length=0;
        end
    end
end

category_frequency_table=tabulate(reshape(run_length_size_categories(run_length_size_categories~=""),1,[]));
end
