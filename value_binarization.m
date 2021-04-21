%Description: 
% Encodes a decimal value into binary  
%Input: decimal value
%Output: binary 
%Created by: Suah Kim
%Last edited by: Suah Kim, 4/21/2021

function encoded_value = value_binarization(value)
if value == 0
    encoded_value='';
else
    encoded_value=dec2bin(abs(value));
    if value < 0
        temp=encoded_value;
        temp(encoded_value=='0')='1';
        temp(encoded_value=='1')='0';
        encoded_value=temp;
    end
end
end